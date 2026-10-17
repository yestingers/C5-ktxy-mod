"""Run the real Lua 5.1 rules/controller/UI with an installed Civ5 interpreter.

The native host is local test tooling, never a mod dependency or packaged file.
"""
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
HOST = ROOT / 'Tests/native_lua_host.exe'
SOURCE = HOST.with_suffix('.cs')

if not HOST.exists() or HOST.stat().st_mtime < SOURCE.stat().st_mtime:
    compiler = Path(os.environ.get('WINDIR', 'C:/Windows')) / 'Microsoft.NET/Framework/v4.0.30319/csc.exe'
    subprocess.run([str(compiler), '/nologo', '/platform:x86', f'/out:{HOST}', str(SOURCE)], check=True)
for name in ['test_traits.lua', 'test_runtime.lua', 'test_ui.lua']:
    subprocess.run([str(HOST), f'Tests/{name}'], cwd=ROOT, check=True)
