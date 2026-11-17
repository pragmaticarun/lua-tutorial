// versions.rs: one crate, three Lua versions selected by Cargo features
use mlua::{Lua, Result};

fn main() -> Result<()> {
    let lua = Lua::new();
    mlua_lessons::route_print(&lua)?; // keep Lua and Rust output in order
    let version: String = lua.load("return _VERSION").eval()?;
    let jit: Option<String> = lua.load("return jit and jit.version").eval()?;
    println!("feature build: {}", if cfg!(feature = "lua55") { "lua55" }
             else if cfg!(feature = "lua54") { "lua54" } else { "luajit" });
    println!("_VERSION = {version}, jit = {}", jit.as_deref().unwrap_or("none"));

    // integers: Lua 5.3+ keeps i64 exact, LuaJIT has only doubles
    let v: mlua::Value = lua.load("return 2^53 + 1").eval()?;
    let i: mlua::Value = lua.load("return 9007199254740993").eval()?;
    println!("2^53 + 1 -> {:?}; literal 9007199254740993 -> {:?}", v, i);

    // mlua installs its own allocator, so memory limits work on every version
    match lua.set_memory_limit(1 << 20) {
        Ok(_) => {
            let r = lua.load("local t = {} for i = 1, 1e6 do t[i] = i end").exec();
            println!("memory limit: supported, big table -> {}",
                     if r.is_err() { "MemoryError" } else { "ok" });
        }
        Err(e) => println!("memory limit: {e}"),
    }
    Ok(())
}
