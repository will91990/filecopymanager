unit UWFile;

interface

uses System.IOUtils, System.SysUtils, UWGlobal;

type
  TWFile = class
  private
    pName: string;
    pDirectory: string;
    pExtension: string;
    pSize: Int64;
    pDateTime: TDateTime;

    pCreationDate: TDateTime;
    pLastAccessDate: TDateTime;
    pLastWriteDate: TDateTime;

    pFileAttributes: TFileAttributes;

    pIdFileTransferLog: Integer;

    function getName: string;
    function getDirectory: string;
    function getExtension: string;
    function getPath: string;
    function getSize: Int64;
    function getDateTime: TDateTime;
    function getHash: string;
    function getCreationDate: TDateTime;
    function getLastAccessDate: TDateTime;
    function getLastWriteDate: TDateTime;
    function getAttributes: TFileAttributes;
  public
    property Size: Int64 read getSize;
    property Path: string read getPath;
    property Name: string read getName;
    property Extension: string read getExtension;
    property Directory: string read getDirectory;
    property FileDateTime: TDateTime read getDateTime;
    property Hash: string read getHash;
    property CreationDate: TDateTime read getCreationDate;
    property LastAccessDate: TDateTime read getLastAccessDate;
    property LastWriteDate: TDateTime read getLastWriteDate;
    property Attributes: TFileAttributes read getAttributes;

    property IdFileTransferLog: Integer read pIdFileTransferLog write pIdFileTransferLog;

    procedure CopyTo(pDestPath: string);
    procedure MoveTo(pDestPath: string);
    procedure RenameFile(pNewName: string);
    procedure RemoveFile;
    constructor Create(FilePath: string);
  end;

  TWFiles = array of TWFile;

implementation

{ TWFile }

constructor TWFile.Create(FilePath: string);
//var
  //arquivo: THandle;
begin
  if FileExists(FilePath) then
  begin
    pName := ExtractFileName(FilePath);     // Nome do arquivo
    pDirectory := ExtractFileDir(FilePath); // Diretório do arquivo
    pExtension := ExtractFileExt(FilePath); // Extensão do arquivo
    pSize := FileSizeInt64(FilePath);       // Tamanho do arquivo

    pCreationDate := TFile.GetCreationTimeUtc(FilePath);
    pLastAccessDate := TFile.GetLastAccessTimeUtc(FilePath);
    pLastWriteDate := TFile.GetLastWriteTimeUtc(FilePath);

    pFileAttributes := TFile.GetAttributes(FilePath);

    //arquivo := FileOpen(FilePath, fmOpenRead);

    //pDateTime := FileGetDate(arquivo);

    //CloseHandle(arquivo);
  end
  else
    raise Exception.Create('Arquivo não existe');
end;

procedure TWFile.MoveTo(pDestPath: string);
begin
  //TFile.Move(getPath, pDestPath);
  TFile.Copy(getPath, pDestPath);

  //Vefifica a integridade do arquivo pelo tamanho
  if CompareFilesBySize(Path, pDestPath) then
    TFile.Delete(getPath);
end;

procedure TWFile.RemoveFile;
begin
  TFile.Delete(getPath);
end;

procedure TWFile.RenameFile(pNewName: string);
begin
  RenameFile(getPath);
end;

procedure TWFile.CopyTo(pDestPath: string);
begin
  TFile.Copy(getPath, pDestPath);
end;

function TWFile.getAttributes: TFileAttributes;
begin
  Result := pFileAttributes;
end;

function TWFile.getCreationDate: TDateTime;
begin
  Result := pCreationDate;
end;

function TWFile.getDateTime: TDateTime;
begin
  Result := pDateTime;
end;

function TWFile.getDirectory: string;
begin
  Result := pDirectory;
end;

function TWFile.getExtension: string;
begin
  Result := pExtension;
end;

function TWFile.getHash: string;
begin
  Result := FileHashMd5(Path);
end;

function TWFile.getLastAccessDate: TDateTime;
begin
  Result := pLastAccessDate;
end;

function TWFile.getLastWriteDate: TDateTime;
begin
  Result := pLastWriteDate;
end;

function TWFile.getName: string;
begin
  Result := pName;
end;

function TWFile.getPath: string;
begin
  Result := pDirectory + '\' + pName;
end;

function TWFile.getSize: Int64;
begin
  Result := pSize;
end;

end.
