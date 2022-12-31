unit UWGlobal;

interface

uses
  System.IOUtils, System.SysUtils, Winapi.Windows, System.Classes, IdHashMessageDigest;

function FileSizeInt64(const FilePath: string): Int64;
function FileSizeInt64New(const FilePath: string): Int64;
function SumFileSize(FilePath: array of string): Int64;
function CompareFilesBySize(const FilePathA: string; const FilePathB: string): Boolean;
function FileHashMd5(pFilePath: string): string;
//function CompareFilesByHashMd5(const FilePathA: string; const FilePathB: string): Boolean;
function FileSizeToString(const pBytes: Int64): string;

implementation

{ FUNCTIONS }

function FileSizeInt64(const FilePath: string): Int64;
var
  FileHandle: THandle;
  FileSizeLo, FileSizeHi: DWORD;
begin
  FileHandle := FileOpen(FilePath, fmOpenRead or fmShareDenyNone);  //

  try
    FileSizeLo := GetFileSize(FileHandle, @FileSizeHi);
    Int64Rec(Result).Lo := FileSizeLo;
    Int64Rec(Result).Hi := FileSizeHi;
  finally
    FileClose(FileHandle);
  end;
end;

function FileSizeInt64New(const FilePath: string): Int64;
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
  Result := FileStream.Size;
end;

function SumFileSize(FilePath: array of string): Int64;
var
  FilePathLength: Integer;
  counter: Integer;
  SumSize: Int64;
begin
  SumSize := 0;
  FilePathLength := Length(FilePath);

  if FilePathLength = 0 then
  begin
    Result := SumSize;
    Exit;
  end;

  for counter := 0 to FilePathLength -1 do
    SumSize := SumSize + FileSizeInt64(FilePath[counter]);

  Result := SumSize;
end;

function CompareFilesBySize(const FilePathA: string; const FilePathB: string): Boolean;
begin
  Result := (FileSizeInt64(FilePathA) = FileSizeInt64(FilePathB));
//  Result := (FileSizeInt64New(FilePathA) = FileSizeInt64New(FilePathB));
end;

function FileHashMd5(pFilePath: string): string;
var
  idmd5: TIdHashMessageDigest5;
  fs: TFileStream;
  hash: T4x4LongWordRecord;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  fs := TFileStream.Create(pFilePath, fmOpenRead OR fmShareDenyWrite);

  try
    result := idmd5.HashStreamAsHex(fs);
  finally
    fs.Free;
    idmd5.Free;
  end;
end;

function FileSizeToString(const pBytes: Int64): string;
const
  b = 1; // byte
  kb = 1024 * b; // kilobyte
  mb = 1024 * kb; // megabyte
  gb = 1024 * mb; // gigabyte
begin
  if pBytes > gb then
    Result := FormatFloat('#.## GB', pBytes / gb)
  else if pBytes > mb then
    Result := FormatFloat('#.## MB', pBytes / mb)
  else if pBytes > kb then
    Result := FormatFloat('#.## KB', pBytes / kb)
  else if pBytes > 0 then
    Result := FormatFloat('#.## bytes', pBytes)
  else
    Result := '0 bytes';
end;

end.
