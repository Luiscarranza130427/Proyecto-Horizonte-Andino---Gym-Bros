Option Explicit
Dim shell, command, args, result
Set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = "C:\laragon\www\gym-bros"
args = ""
If WScript.Arguments.Count > 0 Then
    If WScript.Arguments(0) <> "--simular" Then WScript.Quit 2
    args = " --simular"
End If
command = "& 'C:\laragon\bin\php\php-8.3.33-Win32-vs16-x64\php.exe' artisan suscripciones:vencer --no-interaction --no-ansi" & args & " *>> 'C:\laragon\www\gym-bros\storage\logs\suscripciones-vencimiento.log'; exit $LASTEXITCODE"
result = shell.Run("powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -Command """ & command & """", 0, True)
WScript.Quit result
