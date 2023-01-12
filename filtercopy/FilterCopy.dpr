program FilterCopy;

uses
  System.SysUtils,
  Windows,
  Winapi.ShellAPI,
  Vcl.Dialogs,
  Vcl.Forms,
  FFilterCopy in 'FFilterCopy.pas' {frmFilterCopy},
  FSameFilesOutputOption in '..\forms\FSameFilesOutputOption.pas' {frmSameFilesOutputOption},
  FTransfer in '..\forms\FTransfer.pas' {frmTransfer},
  UWCopy in '..\units\UWCopy.pas',
  UWFile in '..\units\UWFile.pas',
  UWFileFilter in '..\units\UWFileFilter.pas',
  UWFileTransfer in '..\units\UWFileTransfer.pas',
  UWGlobal in '..\units\UWGlobal.pas',
  SQLite3.Classes in '..\lib\Embedded-SQLite3-for-Delphi\SQLite3.Classes.pas',
  SQLite3.Core.Constants in '..\lib\Embedded-SQLite3-for-Delphi\SQLite3.Core.Constants.pas',
  SQLite3.Core.Functions in '..\lib\Embedded-SQLite3-for-Delphi\SQLite3.Core.Functions.pas',
  SQLite3.Core.Objects in '..\lib\Embedded-SQLite3-for-Delphi\SQLite3.Core.Objects.pas',
  SQLite3.Core.Prototypes in '..\lib\Embedded-SQLite3-for-Delphi\SQLite3.Core.Prototypes.pas',
  UWDatabaseV2 in '..\units\UWDatabaseV2.pas',
  UWDatabase.ExtensionLabelsV2 in '..\units\UWDatabase.ExtensionLabelsV2.pas';

function CheckDependencies: Boolean;
var
  Handle: THandle;
begin
//  if not FileExists(ExtractFilePath(Application.ExeName) + '\sqlite3.dll') then
//  begin
//    MessageDlg('Erro ao carregar dependências. Arquivo sqlite3.dll não encontrado.', mtWarning, [mbOK], 0);
//    Result := False;
//  end;

  if not FileExists(ExtractFilePath(Application.ExeName) + '\dbgen.exe') then
  begin
    MessageDlg('Erro ao carregar dependências. Arquivo dbgen.exe não encontrado.', mtWarning, [mbOK], 0);
    Result := False;
  end
  else
    if not FileExists(ExtractFilePath(Application.ExeName) + '\data.db') then
    begin
      try
        try
          ShellExecute(Handle, 'open', PChar(ExtractFilePath(Application.ExeName) + '\dbgen.exe'), '-i', nil, SW_HIDE);
          Result := True;
        except
          Result := False;
        end;
      finally
        FreeAndNil(Handle);
      end;
    end
    else
      Result := True;
end;

{$R *.res}

begin
  if not CheckDependencies then
    Exit;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmFilterCopy, frmFilterCopy);
  Application.Run;
end.
