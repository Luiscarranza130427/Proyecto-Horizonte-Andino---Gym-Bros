Option Explicit
' Ejecuta "php artisan usuarios:desactivar-fecha-futura" oculto y agrega la salida a storage\logs\usuarios-fecha-futura.log.
' La ruta del proyecto sale de la ubicacion de este script (antes estaba fija en
' C:\laragon\www\gym-bros, que no existe) y PHP de la variable GYMBROS_PHP o,
' si no esta definida, del PHP de Laragon instalado.
Dim shell, fso, raiz, php, command, args, result
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
raiz = fso.GetParentFolderName(fso.GetParentFolderName(WScript.ScriptFullName))
shell.CurrentDirectory = raiz
php = shell.ExpandEnvironmentStrings("%GYMBROS_PHP%")
If php = "%GYMBROS_PHP%" Then php = "C:\laragon\bin\php\php-8.4.21-Win32-vs17-x64\php.exe"
If Not fso.FileExists(php) Then WScript.Quit 3
args = ""
If WScript.Arguments.Count > 1 Then WScript.Quit 2
If WScript.Arguments.Count = 1 Then
    If WScript.Arguments(0) <> "--simular" Then WScript.Quit 2
    args = " --simular"
End If
command = "& '" & php & "' artisan usuarios:desactivar-fecha-futura --no-interaction --no-ansi" & args & " *>> '" & raiz & "\storage\logs\usuarios-fecha-futura.log'; exit $LASTEXITCODE"
result = shell.Run("powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -Command """ & command & """", 0, True)
WScript.Quit result
