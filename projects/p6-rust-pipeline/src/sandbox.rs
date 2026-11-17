//! One filter script in its own sandboxed Lua state, with resource limits:
//! the same design as the C++ host (Project 5), written with mlua.

use std::cell::Cell;
use std::collections::BTreeMap;
use std::rc::Rc;
use std::time::{Duration, Instant};

use mlua::{
    Error, Function, HookTriggers, Lua, LuaOptions, MultiValue, StdLib, Table,
    UserData, UserDataFields, UserDataMethods, Value, VmState,
};

use mlua::chunk::ChunkMode;

use crate::frame::Frame;

#[derive(Clone, Copy)]
pub struct Limits {
    pub memory_bytes: usize, // per script state
    pub instructions: i64,   // per call (load, or one process())
    pub seconds: f64,        // wall-clock time per call
}

const HOOK_EVERY: u32 = 1000;

/// What the hook and our pcall share: the budget for the current call.
#[derive(Default)]
struct Budget {
    steps: Cell<i64>,
    deadline: Cell<Option<Instant>>,
    out_of_steps: Cell<bool>,
    out_of_time: Cell<bool>,
}

impl Budget {
    fn exhausted(&self) -> bool {
        self.out_of_steps.get() || self.out_of_time.get()
    }
}

fn coord(v: f64, limit: usize, what: &str) -> mlua::Result<usize> {
    let i = v as i64; // truncates like the C++ host's static_cast<int>
    if v < 0.0 || i >= limit as i64 {
        return Err(Error::runtime(format!("{what} {i} out of range 0..{}", limit - 1)));
    }
    Ok(i as usize)
}

// Lua sees the host's Frame through this impl. The host hands it out with
// Lua::scope, so the handle dies when process() returns.
impl UserData for Frame {
    fn add_fields<F: UserDataFields<Self>>(fields: &mut F) {
        fields.add_field_method_get("width", |_, f| Ok(f.width as i64));
        fields.add_field_method_get("height", |_, f| Ok(f.height as i64));
    }

    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("get", |_, f, (x, y): (f64, f64)| {
            Ok(f.at(coord(x, f.width, "x")?, coord(y, f.height, "y")?) as i64)
        });
        methods.add_method_mut("set", |_, f, (x, y, v): (f64, f64, f64)| {
            let (x, y) = (coord(x, f.width, "x")?, coord(y, f.height, "y")?);
            f.set(x, y, (v.clamp(0.0, 255.0) + 0.5).min(255.0) as u8); // clamp, round
            Ok(())
        });
        methods.add_meta_method(mlua::MetaMethod::ToString, |_, f, ()| {
            Ok(format!("Frame({}x{})", f.width, f.height))
        });
    }
}

pub struct Script {
    pub name: String,
    pub error: String,
    lua: Lua,
    env: Option<Table>,
    limits: Limits,
    budget: Rc<Budget>,
}

impl Script {
    pub fn new(name: &str, limits: Limits) -> mlua::Result<Script> {
        // Only the libraries we hand out: no io, os, package, debug.
        #[allow(unused_mut)]
        let mut libs = StdLib::STRING | StdLib::TABLE | StdLib::MATH;
        #[cfg(feature = "luajit")]
        {
            libs |= StdLib::JIT;
        }
        let lua = Lua::new_with(libs, LuaOptions::default())?;
        #[cfg(feature = "luajit")]
        {
            // LuaJIT runs hooks only in its interpreter, not in compiled
            // traces, so the instruction limit needs the JIT off
            lua.load("jit.off()").exec()?;
        }
        lua.set_memory_limit(limits.memory_bytes)?;
        // strings share a metatable whose __index is the global string table
        lua.globals().get::<Table>("string")?.raw_set("dump", Value::Nil)?;
        Ok(Script {
            name: name.to_string(),
            error: String::new(),
            lua,
            env: None,
            limits,
            budget: Rc::new(Budget::default()),
        })
    }

    fn arm(&self) {
        let b = &self.budget;
        b.steps.set(self.limits.instructions);
        b.deadline.set(Some(Instant::now() + Duration::from_secs_f64(self.limits.seconds)));
        b.out_of_steps.set(false);
        b.out_of_time.set(false);
        let budget = Rc::clone(&self.budget);
        let _ = self.lua.set_hook(HookTriggers::new().every_nth_instruction(HOOK_EVERY), move |_, _| {
            budget.steps.set(budget.steps.get() - HOOK_EVERY as i64);
            if budget.steps.get() < 0 {
                budget.out_of_steps.set(true);
                return Err(Error::runtime("instruction limit exceeded"));
            }
            if budget.deadline.get().is_some_and(|d| Instant::now() > d) {
                budget.out_of_time.set(true);
                return Err(Error::runtime("time limit exceeded"));
            }
            Ok(VmState::Continue)
        });
    }

    /// Turn an mlua error into the one-line message the C++ host prints.
    fn describe(&self, e: &Error) -> String {
        if self.budget.out_of_steps.get() {
            return format!("instruction limit exceeded ({})", self.limits.instructions);
        }
        if self.budget.out_of_time.get() {
            return format!("time limit exceeded ({:.2} s)", self.limits.seconds);
        }
        match e {
            Error::MemoryError(_) => {
                format!("memory limit exceeded ({} KiB)", self.limits.memory_bytes / 1024)
            }
            Error::SyntaxError { message, .. } => message.clone(),
            Error::RuntimeError(msg) => msg.lines().next().unwrap_or("").to_string(),
            Error::CallbackError { cause, .. } => self.describe(cause),
            other => other.to_string().lines().next().unwrap_or("").to_string(),
        }
    }

    fn finish<T>(&mut self, r: mlua::Result<T>) -> bool {
        self.lua.remove_hook();
        match r {
            // the hook only runs between Lua instructions; a long C call can
            // overrun the deadline unseen, so look once more (detect, not stop)
            Ok(_) if self.budget.deadline.get().is_some_and(|d| Instant::now() > d) => {
                self.error = format!(
                    "time limit exceeded ({:.2} s), detected after the call returned",
                    self.limits.seconds
                );
                false
            }
            Ok(_) => true,
            Err(e) => {
                self.error = self.describe(&e);
                let _ = self.lua.gc_collect(); // give back what the failed call held
                false
            }
        }
    }

    pub fn load(&mut self, path: &str, params: &BTreeMap<String, String>) -> bool {
        let src = match std::fs::read(path) {
            Ok(s) => s,
            Err(_) => {
                self.error = format!("cannot open {path}");
                return false;
            }
        };
        let env = match self.make_env(params) {
            Ok(t) => t,
            Err(e) => {
                self.error = e.to_string();
                return false;
            }
        };
        self.arm();
        let r = self
            .lua
            .load(&src[..])
            .set_name(format!("@{path}"))
            .set_mode(ChunkMode::Text) // refuse precompiled bytecode
            .set_environment(env.clone())
            .exec();
        self.env = Some(env);
        self.finish(r)
    }

    fn make_env(&self, params: &BTreeMap<String, String>) -> mlua::Result<Table> {
        let lua = &self.lua;
        let g = lua.globals();
        let env = lua.create_table()?;
        for name in ["assert", "error", "ipairs", "next", "pairs", "select", "tonumber",
                     "tostring", "type", "unpack", "setmetatable", "rawequal", "rawget",
                     "rawset", "rawlen"] {
            env.raw_set(name, g.raw_get::<Value>(name)?)?; // some exist in only some versions
        }
        for lib in ["string", "table", "math"] {
            let copy = lua.create_table()?;
            for pair in g.get::<Table>(lib)?.pairs::<Value, Value>() {
                let (k, v) = pair?;
                copy.raw_set(k, v)?;
            }
            env.raw_set(lib, copy)?;
        }
        // pcall that re-raises once the budget is spent (see the C++ host)
        let budget = Rc::clone(&self.budget);
        let pcall = lua.create_function(move |lua, (f, args): (Function, MultiValue)| {
            let r = f.call::<MultiValue>(args);
            if budget.exhausted() {
                return Err(Error::runtime("instruction limit exceeded"));
            }
            let mut out = MultiValue::new();
            match r {
                Ok(vals) => {
                    out.push_back(Value::Boolean(true));
                    out.extend(vals);
                }
                Err(e) => {
                    out.push_back(Value::Boolean(false));
                    let msg = match &e {
                        Error::RuntimeError(m) => m.clone(),
                        Error::CallbackError { cause, .. } => match cause.as_ref() {
                            Error::RuntimeError(m) => m.clone(),
                            c => c.to_string(),
                        },
                        other => other.to_string(),
                    };
                    out.push_back(Value::String(lua.create_string(msg.lines().next().unwrap_or(""))?));
                }
            }
            Ok(out)
        })?;
        env.raw_set("pcall", pcall)?;
        let name = self.name.clone();
        let tostring: Function = g.get("tostring")?;
        let print = lua.create_function(move |_, args: MultiValue| {
            let mut line = format!("  [{name}]");
            for (i, v) in args.into_iter().enumerate() {
                line.push_str(if i == 0 { " " } else { "\t" });
                line.push_str(&tostring.call::<String>(v)?);
            }
            println!("{line}");
            Ok(())
        })?;
        env.raw_set("print", print)?;
        let p = lua.create_table()?;
        for (k, v) in params {
            match v.parse::<f64>() {
                Ok(n) => p.raw_set(k.as_str(), n)?,
                Err(_) => p.raw_set(k.as_str(), v.as_str())?,
            }
        }
        env.raw_set("params", p)?;
        // --8<-- [start:param]
        // Exercise 1: param(name, default). A number default demands a number.
        let given = params.clone();
        let param = lua.create_function(move |lua, (name, default): (String, Value)| {
            match (given.get(&name), default) {
                (None, d) => Ok(d),
                (Some(v), Value::Number(_) | Value::Integer(_)) => match v.parse::<f64>() {
                    Ok(n) => Ok(Value::Number(n)),
                    Err(_) => Err(Error::runtime(format!("param {name}: '{v}' is not a number"))),
                },
                (Some(v), _) => Ok(Value::String(lua.create_string(v)?)),
            }
        })?;
        env.raw_set("param", param)?;
        // --8<-- [end:param]
        Ok(env)
    }

    /// Call process(frame). On failure the frame is left unchanged.
    pub fn process(&mut self, frame: &mut Frame) -> bool {
        let f: Option<Function> = self.env.as_ref().and_then(|e| e.raw_get("process").ok());
        let Some(f) = f else {
            self.error = "script does not define process(frame)".into();
            return false;
        };
        let backup = frame.clone(); // a failed filter must not leave half its work
        self.arm();
        let r = self.lua.scope(|scope| {
            let ud = scope.create_userdata_ref_mut(frame)?; // invalid after the scope
            f.call::<()>(ud)
        });
        let ok = self.finish(r);
        if !ok {
            *frame = backup;
        }
        ok
    }
}
