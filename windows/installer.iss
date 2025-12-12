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
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs