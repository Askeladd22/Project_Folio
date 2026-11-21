"""Static acceptance for the GUI launcher and retained CMD diagnostics."""
from pathlib import Path
root = Path(__file__).resolve().parents[2]
text = (root / "run_game.vbs").read_text(encoding="utf-8")
assert "WScript.Shell" in text and "shell.Run command, 1, False" in text
assert "cmd.exe" not in text.split("command =")[1].split("On Error Resume Next")[0]
assert "love.exe" in text and "LOVE_EXE" in text
assert (root / "run_game.cmd").is_file()
assert "run_game.vbs" in (root / "README.md").read_text(encoding="utf-8")
print("PASS GUI direct LÖVE launcher and preserved diagnostic CMD")
