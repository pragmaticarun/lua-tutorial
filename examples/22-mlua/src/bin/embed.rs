// embed.rs: a Lua state inside a Rust program
use mlua::{Function, Lua, Result, Table};

fn main() -> Result<()> {
    let lua = Lua::new();
    mlua_lessons::route_print(&lua)?; // keep Lua and Rust output in order // safe subset of the standard library, owned by `lua`

    // run code, evaluate expressions with a typed result
    lua.load("print('hello from ' .. _VERSION)").exec()?;
    let n: i64 = lua.load("return 6 * 7").eval()?;
    let (a, b): (String, bool) = lua.load("return 'two', true").eval()?;
    println!("eval: {n} {a} {b}");

    // globals in both directions
    let globals = lua.globals();
    globals.set("width", 1920)?;
    globals.set("codec", "av1")?;
    lua.load("label = codec:upper() .. '@' .. width").exec()?;
    let label: String = globals.get("label")?;
    println!("label from Lua: {label}");

    // call a Lua function from Rust
    lua.load("function area(w, h) return w * h end").exec()?;
    let area: Function = globals.get("area")?;
    println!("area: {}", area.call::<i64>((1280, 720))?);

    // a Rust closure callable from Lua; arguments and results convert automatically
    let clamp = lua.create_function(|_, (x, lo, hi): (f64, f64, f64)| Ok(x.clamp(lo, hi)))?;
    globals.set("clamp", clamp)?;
    lua.load("print(clamp(1.5, 0, 1), clamp(-3, -1, 1))").exec()?;

    // tables: build in Rust, read in Lua, and the other way round
    let presets: Table = lua.create_sequence_from(["fast", "medium", "slow"])?;
    globals.set("presets", presets)?;
    let joined: String = lua.load("return table.concat(presets, '|')").eval()?;
    let cfg: Table = lua.load("return { fps = 30, hdr = false }").eval()?;
    println!("{joined} fps={} hdr={}", cfg.get::<u32>("fps")?, cfg.get::<bool>("hdr")?);
    Ok(())
}
