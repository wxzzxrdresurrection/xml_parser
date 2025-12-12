#define SourceDir "{#GetEnv('GITHUB_WORKSPACE')}"

[Setup]
AppName=XML Parser
AppVersion=1.0.0
DefaultDirName={pf}\XML Parser
DefaultGroupName=XML Parser
OutputDir=installer
OutputBaseFilename=XMLParserInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "{#SourceDir}\build\windows\x64\runner\Release\*"; \
    DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\XML Parser"; Filename: "{app}\xml_parser.exe"
Name: "{commondesktop}\XML Parser"; Filename: "{app}\xml_parser.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"