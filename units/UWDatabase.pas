unit UWDatabase;

interface

uses
  LiteCall, LiteConsts, Data.DB, DBAccess, LiteAccess, Vcl.Forms, System.SysUtils, UWFile, UWFileTransfer;

type
  TWDatabase = record
  private
    function InsertFileTransfer(pOutputPath: string; pCheckIntegrity: Boolean; pTranferType: Char; pSameFilesOutput, pSameFilesOutputOption, pTotalSize: Integer): Integer;
    procedure InsertFileTransferStatus(pIdFileTransfer, pIdFileTransferStatusType: Integer);
    function InsertFileTransferLog(pIdFileTransfer: Integer; pWFiles: TWFiles): Integer;
    procedure UpdateFileTransferLog(pIdFileTransferLog: Integer);
  public
    procedure Start(var pIdTransfer: Integer; pOutputPath: string; pCheckIntegrity: Boolean; pTranferType: Char; pSameFilesOutput, pSameFilesOutputOption, pTotalSize: Integer; var pWFiles: TWFiles);
    procedure FileTransfer(pIdFileTransferLog: Integer);
    procedure Finish(pIdFileTransfer: Integer);
    procedure Pause(pIdFileTransfer: Integer);
    procedure Resume(pIdFileTransfer: Integer);
    procedure Cancel(pIdFileTransfer: Integer);

    function CheckInterruptedFileTransfer: Integer;
    function GetInterruptedFiles(pIdFileTransfer: Integer): TWFiles;
    function CheckPaused(pIdFileTransfer: Integer): Boolean;
    function GetFileTransfer(pIdFileTransfer: Integer; pWFiles: TWFiles): TWFileTransfer;

    procedure RemoveInterruptedData(pIdFileTransfer: Integer);
    procedure ClearAllData;
  end;

function GetDatabaseConnection: TLiteConnection;

var
  gWDatabase: TWDatabase;

implementation

function GetDatabaseConnection: TLiteConnection;
var
  lLiteConnection: TLiteConnection;
begin
  lLiteConnection := TLiteConnection.Create(nil);
  lLiteConnection.ClientLibrary := ExtractFilePath(Application.ExeName) + '\sqlite3.dll';
  lLiteConnection.Database := ExtractFilePath(Application.ExeName) + '\database.db';
  try
    lLiteConnection.Connect;
  except
    // Erro ao tentar conectar na base de dados
    on e: Exception do
      raise Exception.Create('Erro ao tentar conectar na base de dados. Mensagem: ' + e.Message);
  end;

  Result := lLiteConnection;
end;

function TWDatabase.InsertFileTransfer(pOutputPath: string; pCheckIntegrity: Boolean; pTranferType: Char; pSameFilesOutput, pSameFilesOutputOption, pTotalSize: Integer): Integer;
var
  lLiteQuery: TLiteQuery;
begin

  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'INSERT INTO file_transfer(                 ' +
      '  date_time,                               ' +
      '  output_path,                             ' +
      '  check_integrity,                         ' +
      '  transfer_type,                           ' +
      //'  same_files_output,                       ' +
      '  same_files_output_option,                ' +
      '  total_size) VALUES(                      ' +
      '  :pDateTime,                              ' +
      '  :pOutputPath,                            ' +
      '  :pCheckIntegrity,                        ' +
      '  :pTranferType,                           ' +
      //'  :pSameFilesOutput,                       ' +
      '  :pSameFilesOutputOption,                 ' +
      '  :pTotalSize) RETURNING id_file_transfer;  ';
    lLiteQuery.ParamByName('pDateTime').AsString := DateTimeToStr(Now);
    lLiteQuery.ParamByName('pOutputPath').AsString := pOutputPath;
    lLiteQuery.ParamByName('pCheckIntegrity').AsBoolean := pCheckIntegrity;
    lLiteQuery.ParamByName('pTranferType').AsString := pTranferType;
    //lLiteQuery.ParamByName('pSameFilesOutput').AsInteger := pSameFilesOutput;
    lLiteQuery.ParamByName('pSameFilesOutputOption').AsInteger := pSameFilesOutputOption;
    lLiteQuery.ParamByName('pTotalSize').AsInteger := pTotalSize;
    lLiteQuery.Prepare;

    try
      lLiteQuery.Open;
    except
      // Erro ao tentar inserir dados na tabela file_transfer
      on e: Exception do
        raise Exception.Create('Erro ao tentar inserir dados na tabela file_transfer. Mensagem: ' + e.Message);
    end;

    Result := lLiteQuery.FieldByName('id_file_transfer').AsInteger;

    lLiteQuery.Close;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

procedure TWDatabase.InsertFileTransferStatus(pIdFileTransfer, pIdFileTransferStatusType: Integer);
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'INSERT INTO file_transfer_status(      ' +
      '	date_time,                            ' +
      '	id_file_transfer,                     ' +
      '	id_file_transfer_status_type) VALUES( ' +
      '	:pDateTime,                           ' +
      '	:pIdFileTransfer,                     ' +
      '	:pIdFileTransferStatusType);          ';
    lLiteQuery.ParamByName('pDateTime').AsString := DateTimeToStr(Now);
    lLiteQuery.ParamByName('pIdFileTransfer').AsInteger := pIdFileTransfer;
    lLiteQuery.ParamByName('pIdFileTransferStatusType').AsInteger := pIdFileTransferStatusType;
    lLiteQuery.Prepare;

    try
      lLiteQuery.ExecSQL;
    except
      // Erro ao tentar inserir dados na tabela file_transfer_status
      on e: Exception do
        raise Exception.Create('Erro ao tentar inserir dados na tabela file_transfer_status. Mensagem: ' + e.Message);
    end;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

function TWDatabase.InsertFileTransferLog(pIdFileTransfer: Integer; pWFiles: TWFiles): Integer;
var
  lLiteQuery: TLiteQuery;
  lCount: Integer;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    for lCount := Low(pWFiles) to High(pWFiles) do
    begin
      lLiteQuery.SQL.Text :=
        'INSERT INTO file_transfer_log(                      ' +
        '  date_time,                                        ' +
        '  id_file_transfer,                                 ' +
        '  source_file_path) VALUES(                         ' +
        '  :pDateTime,                                       ' +
        '  :pIdFileTransfer,                                 ' +
        '  :pSourceFilePath) RETURNING id_file_transfer_log; ';
      lLiteQuery.ParamByName('pDateTime').AsString := DateTimeToStr(Now);
      lLiteQuery.ParamByName('pIdFileTransfer').AsInteger := pIdFileTransfer;
      lLiteQuery.ParamByName('pSourceFilePath').AsString := pWFiles[lCount].Path;
      lLiteQuery.Prepare;

      try
        lLiteQuery.Open;
      except
        // Erro ao tentar inserir dados na tabela file_transfer_log
        on e: Exception do
          raise Exception.Create('Erro ao tentar inserir dados na tabela file_transfer_log. Mensagem: ' + e.Message);
      end;

      pWFiles[lCount].IdFileTransferLog := lLiteQuery.FieldByName('id_file_transfer_log').AsInteger;

      lLiteQuery.Close;
      lLiteQuery.UnPrepare;
    end;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

procedure TWDatabase.UpdateFileTransferLog(pIdFileTransferLog: Integer);
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'UPDATE                                        ' +
      '  file_transfer_log                           ' +
      'SET                                           ' +
      '  done_date_time = :pDoneDateTime             ' +
      'WHERE                                         ' +
      '  id_file_transfer_log = :pIdFileTransferLog; ';
    lLiteQuery.ParamByName('pDoneDateTime').AsString := DateTimeToStr(Now);
    lLiteQuery.ParamByName('pIdFileTransferLog').AsInteger := pIdFileTransferLog;
    lLiteQuery.Prepare;

    try
      lLiteQuery.ExecSQL;
    except
      // Erro ao tentar atualizar a tabela file_transfer_log
      on e: Exception do
        raise Exception.Create('Erro ao tentar atualizar a tabela file_transfer_log. Mensagem: ' + e.Message);
    end;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

procedure TWDatabase.Start(var pIdTransfer: Integer; pOutputPath: string; pCheckIntegrity: Boolean; pTranferType: Char; pSameFilesOutput, pSameFilesOutputOption, pTotalSize: Integer; var pWFiles: TWFiles);
var
  lIdFileTransfer, lCount: Integer;
begin
  lIdFileTransfer := InsertFileTransfer(
    pOutputPath,
    pCheckIntegrity,
    pTranferType,
    pSameFilesOutput,
    pSameFilesOutputOption,
    pTotalSize);

  InsertFileTransferStatus(lIdFileTransfer, 1);

  InsertFileTransferLog(lIdFileTransfer, pWFiles);

//  for lCount := Low(pWFiles) to High(pWFiles) do
//    pWFiles[lCount].IdFileTransferLog := InsertFileTransferLog(lIdFileTransfer, pWFiles[lCount].Path);

  pIdTransfer := lIdFileTransfer;
end;

procedure TWDatabase.FileTransfer(pIdFileTransferLog: Integer);
begin
  UpdateFileTransferLog(pIdFileTransferLog);
end;

procedure TWDatabase.Finish(pIdFileTransfer: Integer);
begin
  InsertFileTransferStatus(pIdFileTransfer, 5);
end;

procedure TWDatabase.Pause(pIdFileTransfer: Integer);
begin
  InsertFileTransferStatus(pIdFileTransfer, 2);
end;

procedure TWDatabase.Resume(pIdFileTransfer: Integer);
begin
  InsertFileTransferStatus(pIdFileTransfer, 3);
end;

procedure TWDatabase.Cancel(pIdFileTransfer: Integer);
begin
  RemoveInterruptedData(pIdFileTransfer);
  InsertFileTransferStatus(pIdFileTransfer, 4);
end;

function TWDatabase.CheckInterruptedFileTransfer: Integer;
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'SELECT                      ' +
      '  DISTINCT id_file_transfer ' +
      'FROM                        ' +
      '  file_transfer_log         ' +
      'WHERE                       ' +
      '  a.done_date_time IS NULL  ';

    try
      lLiteQuery.Open;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_log. Mensagem: ' + e.Message);
    end;

    if lLiteQuery.IsEmpty then
      Result := -1
    else
      Result := lLiteQuery.FieldByName('id_file_transfer').AsInteger;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

function TWDatabase.GetInterruptedFiles(pIdFileTransfer: Integer): TWFiles;
var
  lLiteQuery: TLiteQuery;
  lWFiles: TWFiles;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'SELECT                                    ' +
      '  id_file_transfer_log,                   ' +
      '  source_file_path                        ' +
      'FROM                                      ' +
      '  file_transfer_log                       ' +
      'WHERE                                     ' +
      '  id_file_transfer = :pIdFileTransfer AND ' +
      '  done_date_time IS NULL                  ';
    lLiteQuery.ParamByName('pIdFileTransfer').AsInteger := pIdFileTransfer;

    try
      lLiteQuery.Open;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_log. Mensagem: ' + e.Message);
    end;

    lLiteQuery.First;

    while not lLiteQuery.Eof do
    begin
      SetLength(lWFiles, Length(lWFiles)+1);
      lWFiles[High(lWFiles)] := TWFile.Create(lLiteQuery.FieldByName('source_file_path').AsString);
      lWFiles[High(lWFiles)].IdFileTransferLog := lLiteQuery.FieldByName('id_file_transfer_log').AsInteger;
      lLiteQuery.Next;
    end;

    Result := lWFiles;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

function TWDatabase.CheckPaused(pIdFileTransfer: Integer): Boolean;
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'SELECT                                    ' +
      '  1                                       ' +
      'FROM                                      ' +
      '  file_transfer_status                    ' +
      'WHERE                                     ' +
      '  id_file_transfer = :pIdFileTransfer AND ' +
      '  id_file_transfer_status_type = 2        ';
    lLiteQuery.ParamByName('pIdFileTransfer').AsInteger := pIdFileTransfer;

    try
      lLiteQuery.Open;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_status. Mensagem: ' + e.Message);
    end;

    Result := not (lLiteQuery.IsEmpty);
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

function TWDatabase.GetFileTransfer(pIdFileTransfer: Integer; pWFiles: TWFiles): TWFileTransfer;
var
  lLiteQuery: TLiteQuery;
  lWFileTransfer: TWFileTransfer;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'SELECT                                 ' +
      '  output_path,                         ' +
      '  check_integrity,                     ' +
      '  transfer_type,                       ' +
      '  same_files_output_option,            ' +
      '  total_size                        ' +
      'FROM                                   ' +
      '  file_transfer                        ' +
      'WHERE                                  ' +
      '  id_file_transfer = :pIdFileTransfer; ';
    lLiteQuery.ParamByName('pIdFileTransfer').AsInteger := pIdFileTransfer;

    try
      lLiteQuery.Open;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer. Mensagem: ' + e.Message);
    end;

    if not (lLiteQuery.IsEmpty) then
    begin

      lWFileTransfer := TWFileTransfer.Create(
        pWFiles,
        lLiteQuery.FieldByName('output_path').AsString,
        pIdFileTransfer,
        lLiteQuery.FieldByName('total_size').AsInteger);

      lWFileTransfer.CheckIntegrity := lLiteQuery.FieldByName('check_integrity').AsBoolean;

      if lLiteQuery.FieldByName('transfer_type').AsString = 'C' then
        lWFileTransfer.TransferType := ftCopy
      else if lLiteQuery.FieldByName('transfer_type').AsString = 'M' then
        lWFileTransfer.TransferType := ftMove;

      case lLiteQuery.FieldByName('same_files_output_option').AsInteger of
        0: lWFileTransfer.SameFilesOutputOption := sfNone;
        1: lWFileTransfer.SameFilesOutputOption := sfOverwrite;
        2: lWFileTransfer.SameFilesOutputOption := sfDontcopy;
        3: lWFileTransfer.SameFilesOutputOption := sfKeepboth;
      end;

      lWFileTransfer.OnStart := Start;
      lWFileTransfer.OnPause := Pause;
      lWFileTransfer.OnFileTransfer := FileTransfer;
      lWFileTransfer.OnFinish := Finish;
      lWFileTransfer.OnCancel := Cancel;
      lWFileTransfer.OnResume := Resume;
    end;

    Result :=  lWFileTransfer;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

procedure TWDatabase.RemoveInterruptedData(pIdFileTransfer: Integer);
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'DELETE FROM                               ' +
      '  file_transfer_log                       ' +
      'WHERE                                     ' +
      '  id_file_transfer = :pIdFileTransfer AND ' +
      '  done_date_time IS NULL                  ';

    lLiteQuery.ParamByName('pIdFileTransfer').AsInteger := pIdFileTransfer;

    try
      lLiteQuery.ExecSQL;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_status. Mensagem: ' + e.Message);
    end;

  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

procedure TWDatabase.ClearAllData;
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'DELETE FROM file_transfer_log;    ' +
      'DELETE FROM file_transfer;        ' +
      'DELETE FROM file_transfer_status; ';

    try
      lLiteQuery.ExecSQL;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar excluir dados das tabelas file_transfer_log, file_transfer, file_transfer_status. Mensagem: ' + e.Message);
    end;

  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

end.
