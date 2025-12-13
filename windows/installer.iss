#define AppName "XML Parser"
#define AppVersion "1.0.0"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=installer
OutputBaseFilename=XMLParserSetup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\xml_parser.exe"; DestDir: "{app}";
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}";
Source: "build\windows\x64\runner\Release\icudtl.dat"; DestDir: "{app}";

Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: recursesubdirs

[Icons]
Name: "{group}\XML Parser"; Filename: "{app}\xml_parser.exe"
Name: "{commondesktop}\XML Parser"; Filename: "{app}\xml_parser.exe"
