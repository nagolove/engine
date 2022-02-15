#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}

use rand::Rng;

//let mut rng = rand::thread_rng();

#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    //let mut rng = rand::thread_rng();
    //let n: u8 = rng.gen_range(0..100);
    //println!("n = {}", n);
    /*
     *if n == 50 {
     *    return a + (b - 1)
     *} else {
     *    a + b
     *}
     */
    a + b
}

//type Callback = unsafe extern "C" fn(i32, *mut c_void)
use core::ffi::c_void;
use std::ptr;

type Callback = unsafe extern "C" fn(i32, i32, *mut c_void, i64);

#[no_mangle]
pub extern "C" fn pump_iron(cb1: Callback, cb2: Callback) {
    unsafe {
        let mut rng = rand::thread_rng();
        for i in 0..10000 {
            let n: u8 = rng.gen_range(0..100);
            let f: i64 = n as i64;
            cb1(i32::from(n), i32::from(n) + 1, ptr::null_mut(), f.into());
            cb2(i32::from(n) + 1, i32::from(n) + 0, ptr::null_mut(), f.into());
            //cb2(n.into() + 1, n.into(), ptr::null_mut(), f.into() + 1);
        }
    }
}


pub fn sum(a: i32, b: i32) -> i32 {
    a + b
}

use mlua::prelude::*;

fn hello(_: &Lua, name: String) -> LuaResult<()> {
    println!("hello, {}!", name);
    Ok(())
}

#[mlua::lua_module]
fn ddd(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("hello", lua.create_function(hello)?)?;
    Ok(exports)
}

