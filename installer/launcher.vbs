Set shell = CreateObject("WScript.Shell")
root = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
updateCommand = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & root & "updater.ps1"" -InstallDir """ & Left(root, Len(root)-1) & """"
shell.Run updateCommand, 0, True

gameExe = root & "current\ImPuls.exe"
Set fso = CreateObject("Scripting.FileSystemObject")
If fso.FileExists(gameExe) Then
    shell.Run """" & gameExe & """", 1, False
Else
    MsgBox "ImPuls.exe не найден. Проверьте подключение к Интернету и запустите ImPuls ещё раз.", 48, "ImPuls"
End If
