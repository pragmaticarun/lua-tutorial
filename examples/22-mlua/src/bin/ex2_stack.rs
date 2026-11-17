// Exercise 2 solution: a Rust Vec exposed as a Lua object with methods and metamethods
use mlua::{Lua, MetaMethod, Result, UserData, UserDataMethods, Value};

#[derive(Default)]
struct Stack(Vec<i64>);

impl UserData for Stack {
    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        methods.add_method_mut("push", |_, s, v: i64| {
            s.0.push(v);
            Ok(())
        });
        methods.add_method_mut("pop", |_, s, ()| Ok(s.0.pop())); // None -> nil
        methods.add_method("peek", |_, s, ()| Ok(s.0.last().copied()));
        methods.add_meta_method(MetaMethod::Len, |_, s, ()| Ok(s.0.len()));
        methods.add_meta_method(MetaMethod::ToString, |_, s, ()| {
            Ok(format!("Stack{:?}", s.0))
        });
        // __index fallback for numeric indices: s[1] is the bottom element
        methods.add_meta_method(MetaMethod::Index, |_, s, key: Value| {
            Ok(key.as_integer().and_then(|i| s.0.get((i - 1) as usize).copied()))
        });
    }
}

fn main() -> Result<()> {
    let lua = Lua::new();
    mlua_lessons::route_print(&lua)?;
    lua.globals().set("Stack", lua.create_function(|_, ()| Ok(Stack::default()))?)?;
    lua.load(
        r#"
        local s = Stack()
        for i = 1, 4 do s:push(i * 10) end
        print(tostring(s), #s, s:peek(), s[1], s[4], s[5])
        print(s:pop(), s:pop(), #s)
        local ok, err = pcall(s.push, s, "x")
        print(ok, tostring(err):match("[^\n]*"))
        "#,
    )
    .set_name("=demo")
    .exec()
}
