using System;
using System.Runtime.InteropServices;
public class NativeLuaHost {
    private const string Lua = @"D:\steam\steamapps\common\Sid Meier's Civilization V\lua51_Win32.dll";
    [DllImport(Lua, CallingConvention=CallingConvention.Cdecl)] static extern IntPtr luaL_newstate();
    [DllImport(Lua, CallingConvention=CallingConvention.Cdecl)] static extern void luaL_openlibs(IntPtr L);
    [DllImport(Lua, CallingConvention=CallingConvention.Cdecl)] static extern int luaL_loadfile(IntPtr L, string path);
    [DllImport(Lua, CallingConvention=CallingConvention.Cdecl)] static extern int lua_pcall(IntPtr L, int args, int results, int error);
    [DllImport(Lua, CallingConvention=CallingConvention.Cdecl)] static extern IntPtr lua_tolstring(IntPtr L, int index, IntPtr length);
    [DllImport(Lua, CallingConvention=CallingConvention.Cdecl)] static extern void lua_close(IntPtr L);
    public static int Main(string[] args) {
        var state = luaL_newstate();
        try {
            luaL_openlibs(state);
            foreach (var file in args) {
                var result = luaL_loadfile(state, file);
                if (result == 0) result = lua_pcall(state, 0, -1, 0);
                if (result != 0) { Console.Error.WriteLine(Marshal.PtrToStringAnsi(lua_tolstring(state, -1, IntPtr.Zero))); return 1; }
            }
            return 0;
        } finally { lua_close(state); }
    }
}
