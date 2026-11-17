//! Helpers shared by the Lesson 22 examples.
use mlua::{Lua, MultiValue, Result};

/// Replace Lua's `print` with one that writes through Rust's `println!`.
///
/// Lua's own `print` writes to C's `stdout` buffer and Rust's `println!` to
/// Rust's, so when output goes to a pipe the two can appear out of order.
/// Hosts usually redirect `print` anyway (to a logger, a console widget, ...).
pub fn route_print(lua: &Lua) -> Result<()> {
    let print = lua.create_function(|lua, args: MultiValue| {
        let tostring: mlua::Function = lua.globals().get("tostring")?;
        let mut parts = Vec::with_capacity(args.len());
        for v in args {
            parts.push(tostring.call::<String>(v)?);
        }
        println!("{}", parts.join("\t"));
        Ok(())
    })?;
    lua.globals().set("print", print)
}
