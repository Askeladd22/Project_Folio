' Launch Project Folio with LÖVE directly (GUI, no cmd.exe window).
' Double-click this file using wscript.exe. run_game.cmd remains diagnostic.
Option Explicit
Dim fso, shell, gameDir, loveExe, p1, p2, custom, command
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
gameDir = fso.GetParentFolderName(WScript.ScriptFullName)
custom = shell.ExpandEnvironmentStrings("%LOVE_EXE%")
p1 = shell.ExpandEnvironmentStrings("%ProgramFiles%") & "\LOVE\love.exe"
p2 = shell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\LOVE\love.exe"
loveExe = ""
If Len(custom) > 0 And custom <> "%LOVE_EXE%" Then
    If fso.FileExists(custom) Then loveExe = custom
End If
If loveExe = "" And fso.FileExists(p1) Then loveExe = p1
If loveExe = "" And fso.FileExists(p2) Then loveExe = p2
If loveExe = "" Then loveExe = "love.exe"
command = Chr(34) & loveExe & Chr(34) & " " & Chr(34) & gameDir & Chr(34)
On Error Resume Next
shell.Run command, 1, False
If Err.Number <> 0 Then
    MsgBox "LÖVE 11.x not found. Install LÖVE or set LOVE_EXE to love.exe." & vbCrLf & Err.Description, vbExclamation, "Project Folio"
End If
On Error GoTo 0
