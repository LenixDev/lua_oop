// run.js
const { lua, lauxlib, lualib } = require('fengari');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

// Load and run your Lua file
if (lauxlib.luaL_dofile(L, './index.lua') !== lua.LUA_OK) {
    console.error(lua.lua_tojsstring(L, -1));
}