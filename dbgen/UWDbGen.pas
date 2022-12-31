unit UWDbGen;

interface

uses
  System.SysUtils,
  LiteCall,
  LiteConsts,
  Data.DB,
  DBAccess,
  LiteAccess;

procedure CreateDatabase;

procedure CreateSystemTables;
procedure DropSystemTables;
procedure InsertSystemData;
procedure DeleteSystemData;

procedure CreateUserTables;
procedure DropUserTables;
procedure InsertUserData;
procedure DeleteUserData;

implementation

procedure CreateDatabase;
var
  lHandle: THandle;
begin
  lHandle := FileCreate(ExtractFilePath(ParamStr(0)) + '\data.db');
  FileClose(lHandle);
end;

function GetDatabaseConnection: TLiteConnection;
var
  lLiteConnection: TLiteConnection;
begin
  lLiteConnection := TLiteConnection.Create(nil);
  lLiteConnection.ClientLibrary := ExtractFilePath(ParamStr(0)) + '\sqlite3.dll';
  lLiteConnection.Database := ExtractFilePath(ParamStr(0)) + '\data.db';
  try
    lLiteConnection.Connect;
  except
    // Erro ao tentar conectar na base de dados
    on e: Exception do
      raise Exception.Create('Erro ao tentar conectar na base de dados. Mensagem: ' + e.Message);
  end;

  Result := lLiteConnection;
end;

procedure ExecSql(const pSql: string);
var
  lLiteQuery: TLiteQuery;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text := pSql;

    try
      lLiteQuery.ExecSQL;
    except
      on e: Exception do
        raise Exception.Create(' Mensagem: ' + e.Message);
    end;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

procedure CreateSystemTables;
const
  lSql: string =
    'CREATE TABLE file_transfer(                                                          ' +
    '  id_file_transfer INTEGER PRIMARY KEY,                                              ' +
    '  date_time TEXT NOT NULL,                                                           ' +
    '  output_path TEXT NOT NULL,                                                         ' +
    '  check_integrity BOOLEAN NOT NULL,                                                  ' +
    '  transfer_type TEXT CHECK(transfer_type = ''C'' OR transfer_type = ''M'') NOT NULL, ' +
    '  same_files_output_option INTEGER,                                                  ' +
    '  total_size INTEGER NOT NULL                                                        ' +
    ');                                                                                   ' +
    '                                                                                     ' +
    'CREATE TABLE file_transfer_log(                                                      ' +
    '  id_file_transfer_log INTEGER PRIMARY KEY,                                          ' +
    '  date_time TEXT NOT NULL,                                                           ' +
    '  id_file_transfer INTEGER REFERENCES file_transfer(id_file_transfer) NOT NULL,      ' +
    '  source_file_path TEXT NOT NULL,                                                    ' +
    '  done_date_time TEXT DEFAULT NULL                                                   ' +
    ');                                                                                   ' +
    '                                                                                     ' +
    'CREATE TABLE file_transfer_status_type(                                              ' +
    '  id_file_transfer_status_type INTEGER PRIMARY KEY,                                  ' +
    '  status_type TEXT NOT NULL                                                          ' +
    ');                                                                                   ' +
    '                                                                                     ' +
    'CREATE TABLE file_transfer_status(                                                   ' +
    '  id_file_transfer_status INTEGER PRIMARY KEY,                                       ' +
    '  date_time TEXT NOT NULL,                                                           ' +
    '  id_file_transfer INTEGER REFERENCES file_transfer(id_file_transfer) NOT NULL,      ' +
    '  id_file_transfer_status_type INTEGER REFERENCES file_transfer_status_type(id_file_transfer_status_type) NOT NULL ' +
    ');                                                                                                                 ';
begin
  ExecSql(lSql);
end;

procedure DropSystemTables;
const
  lSql: string =
    'DROP TABLE IF EXISTS file_transfer_status;      ' +
    'DROP TABLE IF EXISTS file_transfer_status_type; ' +
    'DROP TABLE IF EXISTS file_transfer_log;         ' +
    'DROP TABLE IF EXISTS file_transfer;             ';
begin
  ExecSql(lSql);
end;

procedure InsertSystemData;
const
  lSql: string =
    'INSERT INTO file_transfer_status_type(id_file_transfer_status_type, status_type) VALUES(1, ''started''); ' +
    'INSERT INTO file_transfer_status_type(id_file_transfer_status_type, status_type) VALUES(2, ''paused'');  ' +
    'INSERT INTO file_transfer_status_type(id_file_transfer_status_type, status_type) VALUES(3, ''resumed''); ' +
    'INSERT INTO file_transfer_status_type(id_file_transfer_status_type, status_type) VALUES(4, ''caceled''); ' +
    'INSERT INTO file_transfer_status_type(id_file_transfer_status_type, status_type) VALUES(5, ''done'');    ';
begin
  ExecSql(lSql);
end;

procedure DeleteSystemData;
const
  lSql: string =
    'DELETE FROM file_transfer_log;    ' +
    'DELETE FROM file_transfer_status; ' +
    'DELETE FROM file_transfer;        ';
begin
  ExecSql(lSql);
end;

procedure CreateUserTables;
const
  lSql: string =
    'CREATE TABLE labels(                                     ' +
    '  id_label INTEGER PRIMARY KEY,                          ' +
    '  label TEXT UNIQUE NOT NULL                             ' +
    ');                                                       ' +
    '                                                         ' +
    'CREATE TABLE extensions_label(                           ' +
    '  id_extensions INTEGER PRIMARY KEY,                     ' +
    '  id_label INTEGER REFERENCES labels(id_label) NOT NULL, ' +
    '  extension TEXT NOT NULL                                ' +
    ');                                                       ';
begin
  ExecSql(lSql);
end;

procedure DropUserTables;
const
  lSql: string =
    'DROP TABLE IF EXISTS extensions_label; ' +
    'DROP TABLE IF EXISTS labels;           ';
begin
  ExecSql(lSql);
end;

procedure InsertUserData;
const
  lSql: string =
    'INSERT INTO labels(label) VALUES(''Documentos'');                       ' +
    'INSERT INTO labels(label) VALUES(''Imagens'');                          ' +
    'INSERT INTO labels(label) VALUES(''Músicas'');                          ' +
    'INSERT INTO labels(label) VALUES(''Vídeos'');                           ' +
    'INSERT INTO labels(label) VALUES(''RAW'');                              ' +
    'INSERT INTO labels(label) VALUES(''Arquivo compactado'');               ' +

    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.txt'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.pdf'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.doc'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.docx''); ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.odt'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.csv'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(1, ''.xls'');  ' +

    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.png'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.jpeg''); ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.jpg'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.bmp'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.gif'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.tiff''); ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(2, ''.exif''); ' +

    'INSERT INTO extensions_label(id_label, extension) VALUES(3, ''.mp3'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(3, ''.wav'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(3, ''.wave''); ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(3, ''.wma'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(3, ''.flac''); ' +

    'INSERT INTO extensions_label(id_label, extension) VALUES(4, ''.mp4'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(4, ''.mov'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(4, ''.mkv'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(4, ''.avi'');  ' +

    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.3fr'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.arw'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.srf'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.sr2'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.bay'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.crw'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.cr2'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.cr3'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.cap'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.tif'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.iiq'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.eip'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.dcs'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.dcr'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.drf'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.k25'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.kdc'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.tif'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.dng'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.erf'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.fff'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.mef'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.mos'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.mrw'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.nef'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.nrw'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.orf'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.ptx'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.pef'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.pxn'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.r3d'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.raf'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.raw'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.rw2'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.rwl'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.dng'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.si3'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.rwz'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.x3f'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(5, ''.braw''); ' +

    'INSERT INTO extensions_label(id_label, extension) VALUES(6, ''.zip'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(6, ''.7z'');   ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(6, ''.rar'');  ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(6, ''.gz'');   ' +
    'INSERT INTO extensions_label(id_label, extension) VALUES(6, ''.tar'');  ';
begin
  ExecSql(lSql);
end;

procedure DeleteUserData;
const
  lSql: string =
    'DELETE FROM labels;           ' +
    'DELETE FROM extensions_label; ';
begin
  ExecSql(lSql);
end;

end.
