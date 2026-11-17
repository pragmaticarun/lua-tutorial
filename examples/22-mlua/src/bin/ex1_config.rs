// Exercise 1 solution: load a Lua config file into a validated Rust struct
use mlua::{Lua, Result, Table};

#[derive(Debug)]
struct Config {
    width: u32,
    height: u32,
    codec: String,
    presets: Vec<String>,
}

fn load_config(lua: &Lua, src: &str) -> Result<Config> {
    // run the config in its own environment table, so it cannot touch globals
    let env = lua.create_table()?;
    lua.load(src).set_name("=config").set_environment(env.clone()).exec()?;
    let out: Table = env.get("output")?;
    let width: u32 = out.get("width")?;
    let height: u32 = out.get("height")?;
    if width % 2 != 0 || height % 2 != 0 {
        return Err(mlua::Error::runtime(format!("{width}x{height}: dimensions must be even")));
    }
    Ok(Config {
        width,
        height,
        codec: out.get::<Option<String>>("codec")?.unwrap_or_else(|| "h264".into()),
        presets: env.get::<Option<Vec<String>>>("presets")?.unwrap_or_default(),
    })
}

fn main() -> Result<()> {
    let lua = Lua::new();
    let good = r#"output = { width = 1280, height = 720 } presets = { "fast", "slow" }"#;
    println!("{:?}", load_config(&lua, good)?);
    for bad in [
        "output = { width = 1279, height = 720 }",
        "output = { width = 'wide', height = 720 }",
        "output = { width = 640, height = 480 } presets = { 1, {} }",
    ] {
        match load_config(&lua, bad) {
            Ok(c) => println!("unexpected: {c:?}"),
            Err(e) => println!("error: {}", e.to_string().lines().next().unwrap_or("")),
        }
    }
    let leaked: Option<String> = lua.globals().get("output")?;
    println!("global 'output' after loading: {leaked:?}");
    Ok(())
}
