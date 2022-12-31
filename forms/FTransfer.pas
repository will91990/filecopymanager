unit FTransfer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, UWCopy, UWFile, UWFileTransfer, UWDatabase,
  Vcl.StdCtrls;

type
  TFastCopyFileThread = class;

  TfrmTransfer = class(TForm)
    ProgressBar1: TProgressBar;
    Label1: TLabel;
    btnCancelar: TButton;
    btnPausarRetomar: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnPausarRetomarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    wIdFileTransfer: Integer;
    wFiles: TWFiles;
    wPaused: Boolean;
    foutputdir: string;
    fFastCopyFileThread: TFastCopyFileThread;
    fFastCopyFileThreadCanceled: Boolean;
    procedure ChangeControlsState(State: Boolean);
    procedure FastCopyFileProgress(Sender: TObject; FileName: TFileName; Value: Integer{; var CanContinue: Boolean});
    procedure FastCopyFileTerminate(Sender: TObject);
    function GetStatusText: string;
    procedure SetStatusText(const Value: string);
  public
    procedure StartFastCopyThread(pFileTransfer: TWFileTransfer);
    property StatusText: string read GetStatusText write SetStatusText;
    constructor Create(AOwner: TComponent; pWFileTransfer: TWFileTransfer); overload;
  end;

  TFastCopyFileProgressEvent = procedure(Sender: TObject; FileName: TFileName; Value: Integer{; var CanContinue: Boolean}) of object;

  TFastCopyFileThread = class(TThread)
  private
    WFileTransfer: TWFileTransfer;
    fProgress: TFastCopyFileProgressEvent;
    fCopyMode: TFastCopyFileMode;
    procedure FastCopyFileCallback(const FileName: TFileName; const CurrentSize, TotalSize: Int64{; var CanContinue: Boolean});
  protected
    procedure Execute; override;
  public
    //property Paused: Boolean read getPaused write setPaused;
    property CopyMode: TFastCopyFileMode read fCopyMode write fCopyMode;
    property OnProgress: TFastCopyFileProgressEvent read fProgress write fProgress;
    constructor Create(pFileTransfer: TWFileTransfer); overload;
  end;

var
  frmTransfer: TfrmTransfer;

implementation

{$R *.dfm}

{ TForm2 }

constructor TfrmTransfer.Create(AOwner: TComponent; pWFileTransfer: TWFileTransfer);
begin
  inherited Create(AOwner);

  ChangeControlsState(True);
  StatusText := 'Carregando dados...';
  wPaused := False;
  StartFastCopyThread(pWFileTransfer);
end;

procedure TfrmTransfer.FormShow(Sender: TObject);
begin
  //StartFastCopyThread;
end;

procedure TfrmTransfer.btnCancelarClick(Sender: TObject);
var
  lWFileTransfer: TWFileTransfer;
begin
  if wPaused then
  begin

    Self.Close;

  end
  else
  begin
    wPaused := True;

    {Self.btnPausarRetomarClick(Sender);

    case MessageDlg('Tem certeza que deja cancelar a cópia?', mtConfirmation, [mbYes, mbNo], 0, mbYes) of
      mrYes:
      begin
        fFastCopyFileThread.WFileTransfer.CancelTransfer;

        while not (fFastCopyFileThread.WFileTransfer.Canceled) do
          Sleep(100);

        MessageDlg('A transferência foi cancelada', mtInformation, [mbOK], 0, mbOK);
        Self.Close;
      end;

      mrNo:
      begin
        Self.btnPausarRetomarClick(Sender);
      end;
    end;}

    //opção desfazer

    fFastCopyFileThread.WFileTransfer.CancelTransfer;

    while not (fFastCopyFileThread.WFileTransfer.Canceled) do
      Sleep(100);

    MessageDlg('A transferência foi cancelada', mtInformation, [mbOK], 0, mbOK);
    Self.Close;
  end;
end;

procedure TfrmTransfer.btnPausarRetomarClick(Sender: TObject);
var
  lWFileTransfer: TWFileTransfer;
begin
  if btnPausarRetomar.Caption = 'Pausar' then
  begin
    wPaused := True;
    wIdFileTransfer := fFastCopyFileThread.WFileTransfer.IdFileTransfer;

    fFastCopyFileThread.WFileTransfer.PauseTranfer;

    while not (fFastCopyFileThread.WFileTransfer.Paused) do
      Sleep(100);

    btnPausarRetomar.Caption := 'Retomar';
  end
  else if btnPausarRetomar.Caption = 'Retomar' then
  begin
    wPaused := False;
    ProgressBar1.Position := 0;
    lWFileTransfer := gWDatabase.GetFileTransfer(wIdFileTransfer, gWDatabase.GetInterruptedFiles(wIdFileTransfer));
    StartFastCopyThread(lWFileTransfer);

    btnPausarRetomar.Caption := 'Pausar';
  end;
end;

procedure TfrmTransfer.ChangeControlsState(State: Boolean);
begin
  //Button1.Enabled := State;
  //Button2.Enabled := not State;
  if State then
  begin
    if fFastCopyFileThreadCanceled then
      StatusText := 'Aborted!'
    else
      StatusText := 'Done!';
    fFastCopyFileThreadCanceled := False;
  end;
end;

procedure TfrmTransfer.FastCopyFileProgress(Sender: TObject; FileName: TFileName; Value: Integer{; var CanContinue: Boolean});
begin
  StatusText := ExtractFileName(FileName);
  ProgressBar1.Position := Value;
end;

procedure TfrmTransfer.FastCopyFileTerminate(Sender: TObject);
begin
  if wPaused then
    Exit;

  ChangeControlsState(True);
  ShowMessage('Arquivos transferidos com sucesso!');
  Close;
end;

function TfrmTransfer.GetStatusText: string;
begin
  Result := Label1.Caption;
end;

procedure TfrmTransfer.SetStatusText(const Value: string);
begin
  Label1.Caption := Value;
end;

procedure TfrmTransfer.StartFastCopyThread(pFileTransfer: TWFileTransfer);
begin
  ChangeControlsState(False);

  fFastCopyFileThread := TFastCopyFileThread.Create(pFileTransfer);
  fFastCopyFileThread.OnProgress := FastCopyFileProgress;
  fFastCopyFileThread.OnTerminate := FastCopyFileTerminate;
  fFastCopyFileThread.Resume;
end;

{ TFastCopyFileThread }

constructor TFastCopyFileThread.Create(pFileTransfer: TWFileTransfer);
begin
  inherited Create(True);

  WFileTransfer := pFileTransfer;
  FreeOnTerminate := True;
end;

procedure TFastCopyFileThread.Execute;
begin
  WFileTransfer.OnProgress := FastCopyFileCallback;

  case WFileTransfer.FileTransferMode of
    ftmStart: WFileTransfer.StartTransfer;
    ftmResume: WFileTransfer.ResumeTransfer;
  end;

  //FastCopyFile(SourceFileName, DestinationFileName, CopyMode, FastCopyFileCallback);
end;

procedure TFastCopyFileThread.FastCopyFileCallback(const FileName: TFileName; const CurrentSize, TotalSize: Int64{; var CanContinue: Boolean});
var
  ProgressValue: Integer;
begin
  //CanContinue := not Terminated;

  ProgressValue := Round((CurrentSize * 100) / TotalSize);

  //ProgressValue := Round((CurrentSize / TotalSize) * 100);
  if Assigned(OnProgress) then
    OnProgress(Self, FileName, ProgressValue{, CanContinue});
end;

end.
