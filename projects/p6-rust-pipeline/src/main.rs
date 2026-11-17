//! mediapipe (Rust host): run a synthetic test frame through a chain of Lua
//! filter scripts. Same command line and output as the C++ host (Project 5).
//!
//!   mediapipe [--frames N] [--memory KiB] [--instructions N] [--seconds S]
//!             [--size WxH] script.lua[:key=value,...] ...
//!   mediapipe --version
mod frame;
mod sandbox;

use std::collections::BTreeMap;
use std::io::Write;

use frame::Frame;
use sandbox::{Limits, Script};

fn parse_step(arg: &str) -> (String, BTreeMap<String, String>) {
    let mut params = BTreeMap::new();
    let (path, rest) = arg.split_once(':').unwrap_or((arg, ""));
    for kv in rest.split(',') {
        if let Some((k, v)) = kv.split_once('=') {
            params.insert(k.to_string(), v.to_string());
        }
    }
    (path.to_string(), params)
}

fn main() {
    let mut limits = Limits { memory_bytes: 1024 * 1024, instructions: 2_000_000, seconds: 1.0 };
    let (mut width, mut height, mut frames) = (48usize, 24usize, 1usize);
    let mut steps = Vec::new();
    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut i = 0;
    while i < args.len() {
        let a = args[i].as_str();
        let next = args.get(i + 1).cloned().unwrap_or_default();
        match a {
            "--frames" => { frames = next.parse().unwrap_or(1); i += 1; }
            "--memory" => { limits.memory_bytes = next.parse::<usize>().unwrap_or(1024) * 1024; i += 1; }
            "--instructions" => { limits.instructions = next.parse().unwrap_or(2_000_000); i += 1; }
            "--seconds" => { limits.seconds = next.parse().unwrap_or(1.0); i += 1; }
            "--size" => {
                if let Some((w, h)) = next.split_once('x') {
                    width = w.parse().unwrap_or(48);
                    height = h.parse().unwrap_or(24);
                }
                i += 1;
            }
            "--version" => {
                let lua = mlua::Lua::new();
                let v: String = lua.load("return jit and (jit.version .. ' (Lua 5.1 API)') or _VERSION")
                    .eval().unwrap_or_default();
                println!("mediapipe-rs 1.0, mlua 0.12.2, {v}");
                return;
            }
            _ => steps.push(parse_step(a)),
        }
        i += 1;
    }
    if steps.is_empty() {
        eprintln!("usage: mediapipe [--frames N] [--memory KiB] [--instructions N] [--seconds S] [--size WxH] script.lua[:k=v,...]...");
        std::process::exit(2);
    }

    let mut failures = 0;
    let mut scripts: Vec<Option<Script>> = Vec::new();
    for (path, params) in &steps {
        let name = path.rsplit('/').next().unwrap_or(path);
        println!("load {path}");
        let _ = std::io::stdout().flush();
        let mut script = match Script::new(name, limits) {
            Ok(s) => s,
            Err(e) => { println!("  -> FAILED: {e}"); failures += 1; continue; }
        };
        if script.load(path, params) {
            scripts.push(Some(script));
        } else {
            println!("  -> FAILED: {}", script.error);
            failures += 1;
        }
    }

    let mut frame = Frame::new(width, height);
    for t in 0..frames {
        frame = Frame::test_pattern(width, height, t);
        println!("frame {t}\n  {:<15} {}", "input", frame.stats());
        if t == 0 {
            print!("{}", frame.ascii(48));
        }
        for slot in scripts.iter_mut() {
            let Some(script) = slot else { continue }; // unloaded after a failure
            if script.process(&mut frame) {
                println!("  {:<15} {}", script.name, frame.stats());
            } else {
                println!("  {:<15} FAILED: {} (unloaded)", script.name, script.error);
                *slot = None;
                failures += 1;
            }
        }
    }
    print!("output\n{}", frame.ascii(48));
    std::process::exit(if failures > 0 { 1 } else { 0 });
}
