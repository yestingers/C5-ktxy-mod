"""One command for the current Alpha's offline checks (not in-game certification)."""
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
CACHE=Path.home()/"Documents/My Games/Sid Meier's Civilization 5/cache"
commands=[
    [sys.executable,'Tests/run_lua_tests.py'],
    [sys.executable,'-m','unittest','discover','-s','Tests','-p','test_*.py','-v'],
    [sys.executable,'Tests/validate_model.py'],
    [sys.executable,'Tests/validate_databases.py',str(CACHE/'Civ5DebugDatabase.db'),str(CACHE/'Localization-Merged.db')],
]
for command in commands:subprocess.run(command,cwd=ROOT,check=True)
print('All current offline checks passed; live Civ5 validation remains required.')
