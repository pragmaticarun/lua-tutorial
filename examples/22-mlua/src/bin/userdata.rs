// userdata.rs: exposing a Rust type to Lua with the UserData trait
use mlua::{Lua, MetaMethod, Result, UserData, UserDataFields, UserDataMethods};

struct Frame {
    width: u32,
    height: u32,
    pixels: Vec<u8>,
}

impl Frame {
    fn new(width: u32, height: u32) -> Self {
        Frame { width, height, pixels: vec![0; (width * height) as usize] }
    }
}

impl UserData for Frame {
    fn add_fields<F: UserDataFields<Self>>(fields: &mut F) {
        fields.add_field_method_get("width", |_, f| Ok(f.width));
        fields.add_field_method_get("height", |_, f| Ok(f.height));
    }

    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        // &mut self method: mlua checks the borrow at run time (like RefCell)
        methods.add_method_mut("fill", |_, f, value: u8| {
            f.pixels.fill(value);
            Ok(())
        });
        methods.add_method("checksum", |_, f, ()| {
            Ok(f.pixels.iter().map(|&p| p as u64).sum::<u64>())
        });
        methods.add_method("get", |_, f, (x, y): (u32, u32)| {
            if x >= f.width || y >= f.height {
                return Err(mlua::Error::runtime(format!("pixel ({x}, {y}) out of range")));
            }
            Ok(f.pixels[(y * f.width + x) as usize])
        });
        methods.add_meta_method(MetaMethod::Len, |_, f, ()| Ok(f.pixels.len()));
        methods.add_meta_method(MetaMethod::ToString, |_, f, ()| {
            Ok(format!("Frame({}x{})", f.width, f.height))
        });
    }
}

fn main() -> Result<()> {
    let lua = Lua::new();
    mlua_lessons::route_print(&lua)?; // keep Lua and Rust output in order
    let frame_mod = lua.create_table()?;
    frame_mod.set("new", lua.create_function(|_, (w, h): (u32, u32)| Ok(Frame::new(w, h)))?)?;
    lua.globals().set("Frame", frame_mod)?;

    lua.load(
        r#"
        local f = Frame.new(4, 3)
        f:fill(7)
        print(tostring(f), f.width, f.height, #f, f:checksum(), f:get(3, 2))
        local ok, err = pcall(f.get, f, 4, 0)
        print(ok, tostring(err):match("[^\n]*"))       -- first line; a traceback follows
        print(pcall(function() f.width = 10 end))      -- no setter: read-only field
        last = f
        "#,
    )
    .set_name("=demo")
    .exec()?;

    // the same object, seen from Rust again
    let ud: mlua::AnyUserData = lua.globals().get("last")?;
    {
        let mut frame = ud.borrow_mut::<Frame>()?;
        frame.pixels[0] = 255;
    }
    let sum: u64 = lua.load("return last:checksum()").eval()?;
    println!("after Rust edit: {sum}");
    Ok(())
}
