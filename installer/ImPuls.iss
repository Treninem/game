#ifndef MyBuildTag
  #define MyBuildTag "local"
#endif

#define MyAppName "ImPuls"
#define MyAppVersion "0.9.0"
#define MyAppPublisher "Treninem"

[Setup]
AppId={{A0EF7E22-01BA-4E9D-9034-548E9608B4FD}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName=ImPuls {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\ImPuls
DefaultGroupName=ImPuls
PrivilegesRequired=lowest
OutputDir=output
OutputBaseFilename=ImPuls-Setup-{#MyBuildTag}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupIconFile=impuls.ico
UninstallDisplayIcon={app}\impuls.ico
ArchitecturesAllowed=x64compatible
DisableProgramGroupPage=yes
CloseApplications=yes
RestartApplications=no
VersionInfoVersion=0.9.0.0
VersionInfoCompany=Treninem
VersionInfoDescription=ImPuls PC Installer
VersionInfoProductName=ImPuls
VersionInfoProductVersion=0.9.0.0

[Dirs]
Name: "{app}\current"

[Files]
Source: "..\build\windows\*"; DestDir: "{app}\current"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "updater.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "launcher.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "install_update_task.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "refresh_shortcuts.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "impuls.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "release_tag.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\ImPuls"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\launcher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\impuls.ico"
Name: "{group}\ImPuls"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\launcher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\impuls.ico"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\install_update_task.ps1"" -InstallDir ""{app}"""; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\refresh_shortcuts.ps1"" -InstallDir ""{app}"""; Flags: runhidden waituntilterminated
Filename: "{sys}\wscript.exe"; Parameters: """{app}\launcher.vbs"""; Description: "Запустить ImPuls"; Flags: postinstall nowait skipifsilent

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -WindowStyle Hidden -Command ""Unregister-ScheduledTask -TaskName 'ImPuls Background Update' -Confirm:$false -ErrorAction SilentlyContinue"""; Flags: runhidden; RunOnceId: "RemoveImPulsUpdaterTask"
