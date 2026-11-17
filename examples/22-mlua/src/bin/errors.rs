// errors.rs: Lua errors in Rust, Rust errors in Lua
use std::fmt;
use mlua::{ExternalError, Lua, Result};

#[derive(Debug)]
struct DecodeError {
    frame: u32,
}
impl fmt::Display for DecodeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "corrupt frame {}", self.frame)
    }
}
impl std::error::Error for DecodeError {}

fn kind(e: &mlua::Error) -> &'static str {
    match e {
        mlua::Error::SyntaxError { .. } => "SyntaxError",
        mlua::Error::RuntimeError(_) => "RuntimeError",
        mlua::Error::CallbackError { .. } => "CallbackError",
        mlua::Error::FromLuaConversionError { .. } => "FromLuaConversionError",
        mlua::Error::ExternalError(_) => "ExternalError",
        _ => "other",
    }
}

fn first_line(e: &mlua::Error) -> String {
    e.to_string().lines().next().unwrap_or("").to_string()
}

fn main() -> Result<()> {
    let lua = Lua::new();
    mlua_lessons::route_print(&lua)?; // keep Lua and Rust output in order

    // 1. Lua errors become mlua::Error values
    for code in ["return 1 +", "error('boom')", "local t = nil; return t.x"] {
        let err = lua.load(code).set_name("=script").exec().unwrap_err();
        println!("{:<22} {}", kind(&err), first_line(&err));
    }

    // 2. a Lua value of the wrong type for the requested Rust type
    let err = lua.load("return 'abc'").eval::<i32>().unwrap_err();
    println!("{:<22} {}", kind(&err), first_line(&err));

    // 3. Rust errors raised inside callbacks reach Lua as error values...
    let decode = lua.create_function(|_, frame: u32| {
        if frame == 13 {
            return Err(DecodeError { frame }.into_lua_err()); // any std::error::Error
        }
        Ok(format!("frame {frame} ok"))
    })?;
    lua.globals().set("decode", decode)?;
    lua.load(
        r#"
        print(decode(1))
        local ok, err = pcall(decode, 13)
        print(ok, tostring(err):match("[^\n]*"))
        "#,
    )
    .exec()?;

    // 4. ...and back in Rust the original error can be recovered by type
    let err = lua.load("decode(13)").exec().unwrap_err();
    println!("{:<22} {}", kind(&err), first_line(&err));
    match err.chain().find_map(|e| e.downcast_ref::<DecodeError>()) {
        Some(d) => println!("downcast: DecodeError {{ frame: {} }}", d.frame),
        None => println!("downcast failed"),
    }
    Ok(())
}
