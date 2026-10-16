"""Run Lua tests with the LuaJIT DLL already shipped with LOVE on Windows."""
import ctypes
import os
from pathlib import Path
import sys

os.chdir(Path(__file__).resolve().parent.parent)
dll = Path(os.environ.get("LOVE_LUA_DLL", "C:/Program Files (x86)/LOVE/lua51.dll"))
lua = ctypes.CDLL(str(dll))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
files = [Path(p) for p in sys.argv[1:]] or sorted(Path("tests").glob("*_test.lua"))
failed = 0
for path in files:
    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    result = lua.luaL_loadfile(state, str(path).encode())
    if result == 0:
        result = lua.lua_pcall(state, 0, -1, 0)
    if result:
        failed += 1
        print(f"FAIL {path}: {lua.lua_tolstring(state, -1, None).decode(errors='replace')}", flush=True)
    else:
        print(f"PASS {path}", flush=True)
    lua.lua_close(state)
print(f"{len(files) - failed}/{len(files)} test files passed", flush=True)
sys.exit(bool(failed))
