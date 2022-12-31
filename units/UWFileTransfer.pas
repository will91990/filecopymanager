unit UWFileTransfer;

interface

uses
  System.SysUtils, System.IOUtils, UWCopy, UWGlobal, UWFile;

type
  TWSameFilesOutputOption = (sfNone, sfOverwrite, sfDontcopy, sfKeepboth); //e criar uma pasta e fazer um backup dos antigos
  TWTransferType = (ftCopy, ftMove);

  TFastCopyFileNormalCallback = procedure(const FileName: TFileName; const CurrentSize, TotalSize: Int64; var CanContinue: Boolean);
  TFastCopyFileMethodCallback = procedure(const FileName: TFileName; const CurrentSize, TotalSize: Int64) of object;

  TOnStartEvent = procedure(var pIdTransfer: Integer; pOutputPath: string; pCheckIntegrity: Boolean; pTranferType: Char; pSameFilesOutput, pSameFilesOutputOption, pTotalSize: Integer; var pWFiles: TWFiles) of object;
  TOnFileTransferEvent = procedure(pIdFileTransferLog: Integer) of object;
	TOnPauseEvent = procedure(pIdFileTransfer: Integer) of object;
	TOnResumeEvent = procedure(pIdFileTransfer: Integer) of object;
	TOnFinishEvent = procedure(pIdFileTransfer: Integer) of object;
	TOnCancelEvent = procedure(pIdFileTransfer: Integer) of object;

  TWFileTransferMode = (ftmStart, ftmResume);

  TWFileTransfer = class
  private
    wIdFileTransfer: Integer;
    wFileTransferMode: TWFileTransferMode;
    wIsRunning: Boolean;
    wProgressSize: Int64;

    wFiles: TWFiles;
    wOutputDir: string;
    wTotalSize: Integer;
    wSameFilesOutput: Integer;
    wSameFilesOutputOption: TWSameFilesOutputOption;
    wDoPause: Boolean;
    wPaused: Boolean;
    wDoCancel: Boolean;
    wCanceled: Boolean;
    wTransferType: TWTransferType;
    wCheckIntegrity: Boolean;

    wOnProgress: TFastCopyFileMethodCallback;
    wOnStart: TOnStartEvent;
    wOnFileTransfer: TOnFileTransferEvent;
    wOnPause: TOnPauseEvent;
    wOnResume: TOnResumeEvent;
    wOnFinish: TOnFinishEvent;
    wOnCancel: TOnCancelEvent;

    function GetTotalSize: Integer;
    function CheckSameFilesOutput: Integer;
    procedure Transfer;
  public
    property IdFileTransfer: Integer read wIdFileTransfer;
    property FileTransferMode: TWFileTransferMode read wFileTransferMode;
    property IsRunning: Boolean read wIsRunning;
    property SameFilesOutput: Integer read wSameFilesOutput;
    property SameFilesOutputOption: TWSameFilesOutputOption read wSameFilesOutputOption write wSameFilesOutputOption;
    property Paused: Boolean read wPaused;
    property Canceled: Boolean read wCanceled;
    property TransferType: TWTransferType read wTransferType write wTransferType;
    property CheckIntegrity: Boolean read wCheckIntegrity write wCheckIntegrity;

    property OnProgress: TFastCopyFileMethodCallback read wOnProgress write wOnProgress;
    property OnStart: TOnStartEvent read wOnStart write wOnStart;
    property OnFileTransfer: TOnFileTransferEvent read wOnFileTransfer write wOnFileTransfer;
    property OnPause: TOnPauseEvent read wOnPause write wOnPause;
    property OnResume: TOnResumeEvent read wOnResume write wOnResume;
    property OnFinish: TOnFinishEvent read wOnFinish write wOnFinish;
    property OnCancel: TOnCancelEvent read wOnCancel write wOnCancel;

    function CheckDriveCapacity: Boolean;
    procedure StartTransfer;
    procedure PauseTranfer;
    procedure CancelTransfer;
    procedure ResumeTransfer;

    constructor Create(pFiles: TWFiles; pOutputDir: string); overload;
    constructor Create(pFiles: TWFiles; pOutputDir: string; pIdFileTransfer, pTotalSize: Integer); overload;
  end;

  TWFileTransferResume = class(TWFileTransfer)

  end;

implementation

{ TWFileTransfer }

constructor TWFileTransfer.Create(pFiles: TWFiles; pOutputDir: string);
begin
  Self.wIsRunning := False;

  Self.wFiles := pFiles;
  Self.wOutputDir := pOutputDir;
  Self.wSameFilesOutput := CheckSameFilesOutput;
  Self.wTotalSize := Self.GetTotalSize;;
  Self.wFileTransferMode := ftmStart;
  Self.wProgressSize := 0;
end;

constructor TWFileTransfer.Create(pFiles: TWFiles; pOutputDir: string; pIdFileTransfer, pTotalSize: Integer);
begin
  Self.wIsRunning := False;

  Self.wIdFileTransfer := pIdFileTransfer;
  Self.wFiles := pFiles;
  Self.wOutputDir := pOutputDir;
  Self.wSameFilesOutput := CheckSameFilesOutput;
  //Self.wTotalSize := Self.GetTotalSize;
  Self.wTotalSize := pTotalSize;
  Self.wFileTransferMode := ftmResume;
  Self.wProgressSize := pTotalSize - Self.GetTotalSize;
end;

function TWFileTransfer.GetTotalSize: Integer;
var
  count: Integer;
  SumSize: Int64;
begin
  SumSize := 0;

  for count := Low(wFiles) to High(wFiles) do
    SumSize := SumSize + wFiles[count].Size;

  Result := SumSize;
end;

function TWFileTransfer.CheckDriveCapacity: Boolean;
var
  FileDrive: string;
  count: Integer;
const
  CharDrive: array[1..26] of Char = ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z');
begin
  FileDrive := ExtractFileDrive(wOutputDir);

  if FileDrive[1] in ['A'..'Z'] then
    for count := 1 to 26 do
      if CharDrive[count] = FileDrive[1] then
      begin
        Result := DiskFree(count) > wTotalSize;
        Exit;
      end;
end;

function TWFileTransfer.CheckSameFilesOutput: Integer;
var
  count,countResult: Integer;
begin
  countResult := 0;

  for count := 0 to Length(wFiles) -1 do
    if TFile.Exists(wOutputDir + '\' + wFiles[count].Name) then
      countResult := countResult + 1;

  Result := countResult;
end;

procedure TWFileTransfer.Transfer;
var
  count, countCopy: Integer;
  sourcepath, outputpath: string;
begin

  for count := 0 to Length(wFiles) -1 do
  begin
    //verificar se foi pausado
    if wDoPause then
    begin
      wOnPause(wIdFileTransfer);
      wPaused := True;

      {while (wPaused) do
        if wDoCancel then
        begin
          wOnCancel(wIdFileTransfer);
          wCanceled := True;
          Exit;
        end
        else
          Sleep(500);}

      Exit;
    end;

    //verificar se foi cancelado
    if wDoCancel then
    begin
      wOnCancel(wIdFileTransfer);
      wCanceled := True;
      Exit;
    end;

    //barra de progresso
    wProgressSize := wProgressSize + wFiles[count].Size;
    wOnProgress(wFiles[count].Name, wProgressSize, Self.wTotalSize);

    sourcepath := wFiles[count].Path;
    outputpath := wOutputDir + '\' + wFiles[count].Name;

    //se o arquivo já existir no output dir
    if TFile.Exists(outputpath) then
      case wSameFilesOutputOption of
        sfNone: ;
        sfOverwrite: ;
        sfDontcopy: Continue;
        sfKeepboth:
        begin
          countCopy := 0;

          repeat
            countCopy := countCopy +1;
            outputpath := wOutputDir + '\' + TPath.GetFileNameWithoutExtension(wFiles[count].Name) + ' - copy ' + IntToStr(countCopy) + wFiles[count].Extension;
          until not (TFile.Exists(outputpath));
        end;
      end;

    //INTEGRIDADE
    if wCheckIntegrity then
      repeat
        FastCopyFile(sourcepath, outputpath, fcfmCreate);
      until wFiles[count].Hash = FileHashMd5(outputpath) // Integridade por HASH MD5
    else
      repeat
        FastCopyFile(sourcepath, outputpath, fcfmCreate);
      until wFiles[count].Size = FileSizeInt64(outputpath); // Integridade por tamanho

    //preservar data e hora
    TFile.SetCreationTimeUtc(outputpath, wFiles[count].CreationDate);
    TFile.SetLastAccessTimeUtc(outputpath, wFiles[count].LastAccessDate);
    TFile.SetLastWriteTimeUtc(outputpath, wFiles[count].LastWriteDate);

    //preservar atributos
    TFile.SetAttributes(outputpath, wFiles[count].Attributes);

    //se for para mover, apaga os arquivos
    if wTransferType = ftMove then
      TFile.Delete(sourcepath);

    //gravar logs
    wOnFileTransfer(wFiles[count].IdFileTransferLog);
  end;

  wOnFinish(wIdFileTransfer);
end;

procedure TWFileTransfer.StartTransfer;
begin
  if Self.wFileTransferMode = ftmStart then
  begin
    Self.wIsRunning := True;

    wOnStart(
      wIdFileTransfer,
      wOutputDir,
      wCheckIntegrity,
      'C',
      wSameFilesOutput,
      -1,
      wTotalSize,
      wFiles);

    Transfer;
  end
  else
    raise Exception.Create('Erro de desenvolvimento!');
end;

procedure TWFileTransfer.ResumeTransfer;
begin
  if Self.wFileTransferMode = ftmResume then
  begin
    Self.wIsRunning := True;

    wOnResume(wIdFileTransfer);

    Transfer;
  end
  else
    raise Exception.Create('Erro de desenvolvimento!');
end;

procedure TWFileTransfer.PauseTranfer;
begin
  if Self.wIsRunning then
    wDoPause := True;
end;

procedure TWFileTransfer.CancelTransfer;
begin
  if Self.wIsRunning then
    wDoCancel := True
  else
    Self.wOnCancel(Self.wIdFileTransfer);
end;

end.
