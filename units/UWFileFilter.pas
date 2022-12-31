unit UWFileFilter;

interface

uses
  System.SysUtils, System.IOUtils, System.Classes, UWGlobal, UWFile;

type
  TWExtensionsFilter = array of string;

  TWFilesPaths = array of string;

  TWFileFilter = class
  private
    wSourcePath: string;
    wSelectAll: Boolean;
    wIncludeSubDirOnSource: Boolean;
    wDateFilter: TDate;
    wExtensionsFilter: TStrings;

    wFilesPaths: TWFilesPaths;

    function getSourcePath: string;
    function getIncludeSubDirOnSource: Boolean;
    function getDateFilter: TDate;
    function getExtensionsFilter: TStrings;

    procedure setSourcePath(value: string);
    procedure setIncludeSubDirOnSource(value: Boolean);
    procedure setDateFilter(value: TDate);
    procedure setExtensionsFilter(value: TStrings);

    function getTotalSelectedFiles: Integer;
    function getTotalDirectoryFiles: Integer;
    function getTotalSelectedSize: Int64;
    function getTotalDirectorySize: Int64;

    function getFilesPaths: TWFilesPaths;
    function getSelectedFilesPaths: TWFilesPaths;
    function getExtensions: TWExtensionsFilter;
    function getCreationDateTimes: TStrings;
  public
    property SourcePath: string                   read getSourcePath            write setSourcePath;
    property SelectAll: Boolean                   read wSelectAll               write wSelectAll;
    property IncludeSubDirOnSource: Boolean       read getIncludeSubDirOnSource write setIncludeSubDirOnSource;
    property DateFilter: TDate                    read getDateFilter            write setDateFilter;
    property ExtensionsFilter: TStrings read getExtensionsFilter      write setExtensionsFilter;

    property TotalSelectedFiles: Integer  read getTotalSelectedFiles;
    property TotalDirectoryFiles: Integer read getTotalDirectoryFiles;
    property TotalSelectedSize: Int64     read getTotalSelectedSize;
    property TotalDirectorySize: Int64    read getTotalDirectorySize;

    property Extensions: TWExtensionsFilter read getExtensions;
    property CreationDateTimes: TStrings read getCreationDateTimes;

    procedure Refresh;
    function GenerateFiles: TWFiles;

    constructor Create;
  end;

implementation

{ TWFileFilter }

constructor TWFileFilter.Create;
begin
  wSelectAll := False;
  wDateFilter := -1;
  wIncludeSubDirOnSource := False;
end;

function TWFileFilter.getSourcePath: string;
begin
  Result := wSourcePath;
end;

function TWFileFilter.getIncludeSubDirOnSource: Boolean;
begin
  Result := wIncludeSubDirOnSource;
end;

function TWFileFilter.getDateFilter: TDate;
begin
  Result := wDateFilter;
end;

function TWFileFilter.getExtensionsFilter: TStrings;
begin
  Result := wExtensionsFilter;
end;

procedure TWFileFilter.setSourcePath(value: string);
begin
  wSourcePath := value;
end;

procedure TWFileFilter.setIncludeSubDirOnSource(value: Boolean);
begin
  wIncludeSubDirOnSource := value;
end;

procedure TWFileFilter.setDateFilter(value: TDate);
begin
  wDateFilter := value;
end;

procedure TWFileFilter.setExtensionsFilter(value: TStrings);
begin
  wExtensionsFilter := value;
end;

function TWFileFilter.getTotalSelectedFiles: Integer;
begin
  Result := Length(getSelectedFilesPaths);
end;

function TWFileFilter.getTotalDirectoryFiles: Integer;
begin
  Result := Length(getFilesPaths);
end;

function TWFileFilter.getTotalSelectedSize: Int64;
begin
  Result := SumFileSize(getSelectedFilesPaths);
end;

procedure TWFileFilter.Refresh;
var
  lPath: string;
  lDirPath: string;
  lFIlesPaths: TWFilesPaths;
  lFileAtts: TFileAttributes;
  i: Integer;
begin
  for lPath in TDirectory.GetFiles(wSourcePath) do
  begin
    lFileAtts := TFile.GetAttributes(lPath);

    if not (
      (TFileAttribute.faSymLink in lFileAtts) or
      (TFileAttribute.faHidden in lFileAtts) or
      (TFileAttribute.faSystem in lFileAtts) or
      (TFileAttribute.faDirectory in lFileAtts) or
      (TFileAttribute.faOffline in lFileAtts) or
      (TFileAttribute.faReparsePoint in lFileAtts) or
      (TFileAttribute.faTemporary in lFileAtts)) and (
      (TFileAttribute.faArchive in lFileAtts) or
      (TFileAttribute.faNormal in lFileAtts) or
      (TFileAttribute.faReadOnly in lFileAtts)) then
    begin
      SetLength(lFIlesPaths, Length(lFIlesPaths) +1);
      lFIlesPaths[Length(lFIlesPaths) -1] := lPath;
    end;
  end;

  // incluir arquivos dos subdiretórios sem suas pastas
//  if wIncludeSubDirOnSource then
//    for lDirPath in TDirectory.GetDirectories(wSourcePath) do
//      for lPath in TDirectory.GetFiles(lDirPath) do
//        if FileGetAttr(lPath) = faNormal then
//        begin
//          SetLength(lFIlesPaths,Length(lFIlesPaths)+1);
//          lFIlesPaths[Length(lFIlesPaths)-1] := lPath;
//        end;

  wFilesPaths := lFIlesPaths;
end;

function TWFileFilter.getTotalDirectorySize: Int64;
begin
  Result := SumFileSize(getFilesPaths);
end;

function TWFileFilter.getExtensions: TWExtensionsFilter;
var
  Path: string;
  Extensions: TWExtensionsFilter;
  CountExtensions: Integer;
begin

  for Path in getFilesPaths do
    if Length(Extensions) = 0 then
    begin
      SetLength(Extensions,Length(Extensions)+1);
      Extensions[Length(Extensions)-1] := LowerCase(ExtractFileExt(Path));
    end
    else
      for CountExtensions := 0 to Length(Extensions) -1 do
        if Extensions[CountExtensions] = LowerCase(ExtractFileExt(Path)) then
          Break
        else
          if (CountExtensions = Length(Extensions) -1) then
          begin
            SetLength(Extensions,Length(Extensions)+1);
            Extensions[Length(Extensions)-1] := LowerCase(ExtractFileExt(Path));
          end
          else
            Continue;

  Result := Extensions;
end;

function TWFileFilter.getCreationDateTimes: TStrings;
var
  Path: string;
  CreationDateTimes: TStrings;
  Count: Integer;
  lFileDate: TDate;
begin

  CreationDateTimes := TStringList.Create;

  for Path in getFilesPaths do
  begin
    lFileDate := TFile.GetCreationTimeUtc(Path);

    if CreationDateTimes.Count = 0 then
    begin
      CreationDateTimes.Add(DateToStr(lFileDate));
    end
    else
      for Count := 0 to CreationDateTimes.Count -1 do
        if CreationDateTimes[Count] = DateToStr(lFileDate) then
          Break
        else
          if (Count = CreationDateTimes.Count -1) then
          begin
            CreationDateTimes.Add(DateToStr(lFileDate));
          end
          else
            Continue;
  end;

  Result := CreationDateTimes;
end;

function TWFileFilter.getFilesPaths: TWFilesPaths;
begin
  Result := wFilesPaths;
end;

function TWFileFilter.getSelectedFilesPaths: TWFilesPaths;
var
  lFIlesPaths: TWFilesPaths;
  lDirPath: string;
  lFilesPathsResult: TWFilesPaths;

  procedure AppendFilesPaths(Path: string);
  begin
    SetLength(lFilesPathsResult, Length(lFilesPathsResult) +1);
    lFilesPathsResult[Length(lFilesPathsResult) -1] := Path;
  end;

  procedure DateFilter;
  var
    lPath: string;

    procedure ExtensionsFilter; //FILTRO DE EXTENSÃO
    var
      //Counter2: Integer;
      lExtension: string;
    begin
      //for Counter2 := 0 to Length(wExtensionsFilter) -1 do
      for lExtension in wExtensionsFilter do
        if lExtension = LowerCase(ExtractFileExt(lPath)) then
        //if wExtensionsFilter[Counter2] = ExtractFileExt(lPath) then
          AppendFilesPaths(lPath);
    end;

  begin
    for lPath in lFIlesPaths do //FILTRO DE DATA
      if (wDateFilter <> -1) then
      begin
        if (DateToStr(TFile.GetCreationTimeUtc(lPath)) = DateToStr(wDateFilter)) then
        //if (Length(wExtensionsFilter) > 0) then
          if (wExtensionsFilter.Count > 0) then
            ExtensionsFilter
          else
            AppendFilesPaths(lPath);
      end
      //else if (Length(wExtensionsFilter) > 0) then
      else if (wExtensionsFilter.Count > 0) then
        ExtensionsFilter;
  end;
begin
  lFIlesPaths := getFilesPaths;

  if not wSelectAll then
    DateFilter
  else
    lFilesPathsResult := lFIlesPaths;

//  if wIncludeSubDirOnSource then
//    for lDirPath in TDirectory.GetDirectories(wSourcePath) do
//      DateFilter;

  Result := lFilesPathsResult;
end;

function TWFileFilter.GenerateFiles: TWFiles;
var
  SelectedFiles: TWFilesPaths;
  Path: string;
  wFiles: TWFiles;
begin
  SelectedFiles := getSelectedFilesPaths;

  for Path in SelectedFiles do
  begin
    SetLength(wFiles, Length(wFiles) +1);
    wFiles[Length(wFiles) -1] := TWFile.Create(Path);
  end;

  Result := wFiles;
end;

end.
