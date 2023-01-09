unit UWDatabaseV2;

interface

uses
  Vcl.Forms, System.SysUtils, SQLite3.Classes, UWFile, UWFileTransfer;

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

function GetDatabaseConnection: TSQLiteDatabase;

var
  gWDatabase: TWDatabase;

implementation

function GetDatabaseConnection: TSQLiteDatabase;
var
  lSQLiteDatabase: TSQLiteDatabase;
begin
  try
    lSQLiteDatabase := TSQLiteDatabase.Create(ExtractFilePath(Application.ExeName) + '\data.db');
  except
    // Erro ao tentar conectar na base de dados
    on e: Exception do
      raise Exception.Create('Erro ao tentar conectar na base de dados. Mensagem: ' + e.Message);
  end;

  Result := lSQLiteDatabase;
end;

function TWDatabase.InsertFileTransfer(pOutputPath: string; pCheckIntegrity: Boolean; pTranferType: Char; pSameFilesOutput, pSameFilesOutputOption, pTotalSize: Integer): Integer;
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
begin

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'INSERT INTO file_transfer(                 ' +
      '  date_time,                               ' +
      '  output_path,                             ' +
      '  check_integrity,                         ' +
      '  transfer_type,                           ' +
      '  same_files_output_option,                ' +
      '  total_size) VALUES(                      ' +
      '  :pDateTime,                              ' +
      '  :pOutputPath,                            ' +
      '  :pCheckIntegrity,                        ' +
      '  :pTranferType,                           ' +
      '  :pSameFilesOutputOption,                 ' +
      '  :pTotalSize) RETURNING id_file_transfer;  ');
    lSQLiteStatement.ParamByName[':pDateTime'] := DateTimeToStr(Now);
    lSQLiteStatement.ParamByName[':pOutputPath'] := pOutputPath;
    lSQLiteStatement.ParamByName[':pCheckIntegrity'] := pCheckIntegrity;
    lSQLiteStatement.ParamByName[':pTranferType'] := pTranferType;
    lSQLiteStatement.ParamByName[':pSameFilesOutputOption'] := pSameFilesOutputOption;
    lSQLiteStatement.ParamByName[':pTotalSize'] := pTotalSize;

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      // Erro ao tentar inserir dados na tabela file_transfer
      on e: Exception do
        raise Exception.Create('Erro ao tentar inserir dados na tabela file_transfer. Mensagem: ' + e.Message);
    end;

    lSQLiteCursor.First;
    Result := lSQLiteCursor.ColumnAsInteger[0];
  finally
    lSQLiteStatement.Free;
    //lSQLiteCursor.Free;
  end;
end;

procedure TWDatabase.InsertFileTransferStatus(pIdFileTransfer, pIdFileTransferStatusType: Integer);
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
begin

  try
    try
      lSQLiteStatement := GetDatabaseConnection.Query(
        'INSERT INTO file_transfer_status(      ' +
        '	date_time,                            ' +
        '	id_file_transfer,                     ' +
        '	id_file_transfer_status_type) VALUES( ' +
        '	:pDateTime,                           ' +
        '	:pIdFileTransfer,                     ' +
        '	:pIdFileTransferStatusType);          ');
      lSQLiteStatement.ParamByName[':pDateTime'] := DateTimeToStr(Now);
      lSQLiteStatement.ParamByName[':pIdFileTransfer'] := pIdFileTransfer;
      lSQLiteStatement.ParamByName[':pIdFileTransferStatusType'] := pIdFileTransferStatusType;
    except
      // Erro ao tentar inserir dados na tabela file_transfer_status
      on e: Exception do
        raise Exception.Create('Erro ao tentar inserir dados na tabela file_transfer_status. Mensagem: ' + e.Message);
    end;
  finally
    lSQLiteStatement.Free;
    //lSQLiteCursor.Free;
  end;
end;

function TWDatabase.InsertFileTransferLog(pIdFileTransfer: Integer; pWFiles: TWFiles): Integer;
var
  lSQLiteDatabase: TSQLiteDatabase;
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
  lCount: Integer;
begin

  try
    lSQLiteDatabase := GetDatabaseConnection;

    for lCount := Low(pWFiles) to High(pWFiles) do
    begin
      lSQLiteStatement := lSQLiteDatabase.Query(
        'INSERT INTO file_transfer_log(                      ' +
        '  date_time,                                        ' +
        '  id_file_transfer,                                 ' +
        '  source_file_path) VALUES(                         ' +
        '  :pDateTime,                                       ' +
        '  :pIdFileTransfer,                                 ' +
        '  :pSourceFilePath) RETURNING id_file_transfer_log; ');
      lSQLiteStatement.ParamByName[':pDateTime'] := DateTimeToStr(Now);
      lSQLiteStatement.ParamByName[':pIdFileTransfer'] := pIdFileTransfer;
      lSQLiteStatement.ParamByName[':pSourceFilePath'] := pWFiles[lCount].Path;

      try
        lSQLiteCursor := lSQLiteStatement.Cursor;
      except
        // Erro ao tentar inserir dados na tabela file_transfer_log
        on e: Exception do
          raise Exception.Create('Erro ao tentar inserir dados na tabela file_transfer_log. Mensagem: ' + e.Message);
      end;

      lSQLiteCursor.First;
      pWFiles[lCount].IdFileTransferLog := lSQLiteCursor.ColumnAsInteger[0];
    end;
  finally
    //lSQLiteCursor.Free;
    lSQLiteStatement.Free;
    //lSQLiteDatabase.Free;
  end;
end;

procedure TWDatabase.UpdateFileTransferLog(pIdFileTransferLog: Integer);
var
  lSQLiteStatement: TSQLiteStatement;
begin

  try
    try
      lSQLiteStatement := GetDatabaseConnection.Query(
        'UPDATE                                        ' +
        '  file_transfer_log                           ' +
        'SET                                           ' +
        '  done_date_time = :pDoneDateTime             ' +
        'WHERE                                         ' +
        '  id_file_transfer_log = :pIdFileTransferLog; ');
      lSQLiteStatement.ParamByName[':pDoneDateTime'] := DateTimeToStr(Now);
      lSQLiteStatement.ParamByName[':pIdFileTransferLog'] := pIdFileTransferLog;
    except
      // Erro ao tentar atualizar a tabela file_transfer_log
      on e: Exception do
        raise Exception.Create('Erro ao tentar atualizar a tabela file_transfer_log. Mensagem: ' + e.Message);
    end;
  finally
    lSQLiteStatement.Free;
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
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
begin

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'SELECT                      ' +
      '  DISTINCT id_file_transfer ' +
      'FROM                        ' +
      '  file_transfer_log         ' +
      'WHERE                       ' +
      '  a.done_date_time IS NULL  ');

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_log. Mensagem: ' + e.Message);
    end;

    if not lSQLiteCursor.HasData then
      Result := -1
    else
      Result := lSQLiteCursor.ColumnAsInteger[0];
  finally
    lSQLiteStatement.Free;
    //lSQLiteCursor.Free;
  end;
end;

function TWDatabase.GetInterruptedFiles(pIdFileTransfer: Integer): TWFiles;
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
  lWFiles: TWFiles;
begin

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'SELECT                                    ' +
      '  id_file_transfer_log,                   ' +
      '  source_file_path                        ' +
      'FROM                                      ' +
      '  file_transfer_log                       ' +
      'WHERE                                     ' +
      '  id_file_transfer = :pIdFileTransfer AND ' +
      '  done_date_time IS NULL                  ');
    lSQLiteStatement.ParamByName[':pIdFileTransfer'] := pIdFileTransfer;

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_log. Mensagem: ' + e.Message);
    end;

    lSQLiteCursor.First;

    while lSQLiteCursor.HasData do
    begin
      SetLength(lWFiles, Length(lWFiles)+1);

      lWFiles[High(lWFiles)] := TWFile.Create(lSQLiteCursor.ColumnAsString[1]);
      lWFiles[High(lWFiles)].IdFileTransferLog := lSQLiteCursor.ColumnAsInteger[0];
      lSQLiteCursor.Next;
    end;

    Result := lWFiles;
  finally
    lSQLiteStatement.Free;
    //lSQLiteCursor.Free;
  end;
end;

function TWDatabase.CheckPaused(pIdFileTransfer: Integer): Boolean;
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
begin

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'SELECT                                    ' +
      '  1                                       ' +
      'FROM                                      ' +
      '  file_transfer_status                    ' +
      'WHERE                                     ' +
      '  id_file_transfer = :pIdFileTransfer AND ' +
      '  id_file_transfer_status_type = 2        ');
    lSQLiteStatement.ParamByName[':pIdFileTransfer'] := pIdFileTransfer;

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_status. Mensagem: ' + e.Message);
    end;

    Result := lSQLiteCursor.HasData;
  finally
    lSQLiteStatement.Free;
    //lSQLiteCursor.Free;
  end;
end;

function TWDatabase.GetFileTransfer(pIdFileTransfer: Integer; pWFiles: TWFiles): TWFileTransfer;
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
  lWFileTransfer: TWFileTransfer;
begin

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'SELECT                                 ' +
      '  output_path,                         ' +
      '  check_integrity,                     ' +
      '  transfer_type,                       ' +
      '  same_files_output_option,            ' +
      '  total_size                           ' +
      'FROM                                   ' +
      '  file_transfer                        ' +
      'WHERE                                  ' +
      '  id_file_transfer = :pIdFileTransfer; ');
    lSQLiteStatement.ParamByName[':pIdFileTransfer'] := pIdFileTransfer;

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer. Mensagem: ' + e.Message);
    end;

    if lSQLiteCursor.HasData then
    begin
      lWFileTransfer := TWFileTransfer.Create(
        pWFiles,
        lSQLiteCursor.ColumnAsString[0],
        pIdFileTransfer,
        lSQLiteCursor.ColumnAsInteger[4]);

      lWFileTransfer.CheckIntegrity := StrToBool(lSQLiteCursor.ColumnAsString[1]);

      if lSQLiteCursor.ColumnAsString[2] = 'C' then
        lWFileTransfer.TransferType := ftCopy
      else if lSQLiteCursor.ColumnAsString[2] = 'M' then
        lWFileTransfer.TransferType := ftMove;

      case lSQLiteCursor.ColumnAsInteger[3] of
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
    lSQLiteStatement.Free;
    //lSQLiteCursor.Free;
  end;
end;

procedure TWDatabase.RemoveInterruptedData(pIdFileTransfer: Integer);
var
  lSQLiteStatement: TSQLiteStatement;
begin

  try
    try
      lSQLiteStatement := GetDatabaseConnection.Query(
        'DELETE FROM                               ' +
        '  file_transfer_log                       ' +
        'WHERE                                     ' +
        '  id_file_transfer = :pIdFileTransfer AND ' +
        '  done_date_time IS NULL                  ');
      lSQLiteStatement.ParamByName[':pIdFileTransfer'] := pIdFileTransfer;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela file_transfer_status. Mensagem: ' + e.Message);
    end;

  finally
    lSQLiteStatement.Free;
  end;
end;

procedure TWDatabase.ClearAllData;
var
  lSQLiteStatement: TSQLiteStatement;
begin

  try
    try
      lSQLiteStatement := GetDatabaseConnection.Query(
        'DELETE FROM file_transfer_log;    ' +
        'DELETE FROM file_transfer;        ' +
        'DELETE FROM file_transfer_status; ');
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar excluir dados das tabelas file_transfer_log, file_transfer, file_transfer_status. Mensagem: ' + e.Message);
    end;

  finally
    lSQLiteStatement.Free;
  end;
end;

end.
