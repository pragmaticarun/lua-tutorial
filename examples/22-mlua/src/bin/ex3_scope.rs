// Exercise 3 solution: lend non-'static Rust data to Lua for a limited time
use mlua::{Lua, Result};

fn main() -> Result<()> {
    let lua = Lua::new();
    mlua_lessons::route_print(&lua)?;
    let mut collected: Vec<String> = Vec::new();   // a plain local, not 'static

    lua.scope(|scope| {
        // this closure borrows `collected` mutably; it is only valid inside the scope
        let emit = scope.create_function_mut(|_, line: String| {
            collected.push(line);
            Ok(())
        })?;
        lua.globals().set("emit", emit)?;
        lua.load("for i = 1, 3 do emit('event ' .. i) end").exec()
    })?;

    println!("collected in Rust: {:?}", collected);
    // after the scope the function is invalidated, so Lua cannot reach `collected`
    let r = lua.load("emit('too late')").set_name("=late").exec();
    println!("calling after scope: {}", match r {
        Ok(_) => "ok".to_string(),
        Err(e) => e.to_string().lines().next().unwrap_or("").to_string(),
    });
    Ok(())
}
