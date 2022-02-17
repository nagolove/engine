use rand::Rng;

#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}

//type Callback = unsafe extern "C" fn(i32, *mut c_void)
use core::ffi::c_void;
use std::ptr;

type Callback = unsafe extern "C" fn(i32, i32, *mut c_void, i64);
type Callback_noargs = unsafe extern "C" fn();
type Callback_1arg = unsafe extern "C" fn(i32);

#[no_mangle]
pub extern "C" fn pump_iron(cb1: Callback, cb2: Callback) {
    unsafe {
        let mut rng = rand::thread_rng();
        for i in 0..100_000 {
        //for i in 0..10 {
            let n: u8 = rng.gen_range(0..100);
            let f: i64 = n as i64;
            cb1(i32::from(n), i32::from(n) + 1, ptr::null_mut(), f.into());
            cb2(i32::from(n) + 1, i32::from(n) + 0, ptr::null_mut(), f.into());
            //cb2(n.into() + 1, n.into(), ptr::null_mut(), f.into() + 1);
        }
    }
}

#[no_mangle]
pub extern "C" fn pump_iron_noargs(cb1: Callback_noargs) {
    unsafe {
        let mut rng = rand::thread_rng();
        for i in 0..10000 {
        //for i in 0..10_000 {
            let n: u8 = rng.gen_range(0..100);
            let f: i64 = n as i64;
            cb1();
            //cb2(n.into() + 1, n.into(), ptr::null_mut(), f.into() + 1);
        }
    }
}

#[no_mangle]
pub extern "C" fn pump_iron_1arg(cb: Callback_1arg) {
    unsafe {
        let mut rng = rand::thread_rng();
        for i in 0..10000 {
        //for i in 0..10_000 {
            let n: u8 = rng.gen_range(0..100);
            let f: i64 = n as i64;
            cb(i32::from(n));
            //cb2(n.into() + 1, n.into(), ptr::null_mut(), f.into() + 1);
        }
    }
}


use mlua::prelude::*;
use libc::{c_int, size_t};

/*
#[link(name = "snappy")]
extern {
    fn snappy_compress(input: *const u8,
                       input_length: size_t,
                       compressed: *mut u8,
                       compressed_length: *mut size_t) -> c_int;
    fn snappy_uncompress(compressed: *const u8,
                         compressed_length: size_t,
                         uncompressed: *mut u8,
                         uncompressed_length: *mut size_t) -> c_int;
    fn snappy_max_compressed_length(source_length: size_t) -> size_t;
    fn snappy_uncompressed_length(compressed: *const u8,
                                  compressed_length: size_t,
                                  result: *mut size_t) -> c_int;
    fn snappy_validate_compressed_buffer(compressed: *const u8,
                                         compressed_length: size_t) -> c_int;
}
*/

/*
#[link(name = "chipmunk")]
extern "C" {
    fn cpInitChipmunk() -> c_void;
}
*/

//fn call_dynamic() -> Result<u32, Box<dyn std::error::Error>> {
//fn call_dynamic() -> Result<u32, Box<dyn std::error::Error>> {
//fn call_dynamic() -> Result<u32, Box<dyn std::error::Error>> {

//mod chipmunk_strip;

static x: i64 = 0;
type cpInitChipmunk_proto = unsafe extern fn();

#[macro_use]
extern crate lazy_static;

lazy_static! {
    static ref lib: libloading::Library = libloading::Library::new("libchipmunk.so").unwrap();
    //static ref cpInitChipmunk: libloading::Symbol<cpInitChipmunk_proto> = lib.get(b"cpInitChipmunk");
    static ref cpInitChipmunk: libloading::Symbol<'static cpInitChipmunk_proto> = lib.get(b"cpInitChipmunk");
}

/*
 *fn call_dynamic() {
 *    unsafe {
 *        //let lib = libloading::Library::new("libchipmunk.so").unwrap();
 *        //let func: libloading::Symbol<unsafe extern fn() -> u32> = lib.get(b"my_func").unwrap();
 *        //func();
 *        //Ok(func())
 *        cpInitChipmunk =  lib.get(b"cpInitChipmunk").unwrap();
 *    }
 *}
 */

fn init(_: &Lua, _: ()) -> LuaResult<()> {
    //call_dynamic();
    //unsafe {
        //snappy_compress(ptr::null_mut, 19, ptr::null_mut, ptr::null_mut);
    //}
    unsafe {
        cpInitChipmunk();
    }
    println!("inited");
    Ok(())
}

fn hello(_: &Lua, name: String) -> LuaResult<()> {
    println!("hello, {}!", name);
    Ok(())
}

use mlua::{Chunk, Function, Lua, MetaMethod, Result, UserData, UserDataMethods, Variadic, Table};

//fn get_table(lua: &Lua, _: ()) -> LuaResult<Variadic> {
fn get_table(lua: &Lua, _: ()) -> LuaResult<Table> {
    let array_table = lua.create_table()?;

    array_table.set(1, "one")?;
    array_table.set(2, "two")?;
    array_table.set(3, "three")?;

    //Ok(())
    Ok(array_table)
}

#[mlua::lua_module]
fn ddd(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("hello", lua.create_function(hello)?)?;
    exports.set("get_table", lua.create_function(get_table)?)?;
    exports.set("init", lua.create_function(init)?)?;
    Ok(exports)
}

fn sum(_: &Lua, (a, b): (i64, i64)) -> LuaResult<i64> {
    Ok(a + b)
}

fn used_memory(lua: &Lua, _: ()) -> LuaResult<usize> {
    Ok(lua.used_memory())
}

fn check_userdata(_: &Lua, ud: MyUserData) -> LuaResult<i32> {
    Ok(ud.0)
}

/*
 *#[mlua::lua_module]
 *fn rust_module(lua: &Lua) -> LuaResult<LuaTable> {
 *    let exports = lua.create_table()?;
 *    exports.set("sum", lua.create_function(sum)?)?;
 *    exports.set("used_memory", lua.create_function(used_memory)?)?;
 *    exports.set("check_userdata", lua.create_function(check_userdata)?)?;
 *    Ok(exports)
 *}
 */

#[derive(Clone, Copy)]
struct MyUserData(i32);

impl LuaUserData for MyUserData {}

#[mlua::lua_module]
fn rust_module_second(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("userdata", lua.create_userdata(MyUserData(123))?)?;
    Ok(exports)
}

#[mlua::lua_module]
fn rust_module_error(_: &Lua) -> LuaResult<LuaTable> {
    Err("custom module error".to_lua_err())
}

