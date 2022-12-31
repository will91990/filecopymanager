unit FSameFilesOutputOption;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls{, uGlobal}, UWFileTransfer;

type
  TfrmSameFilesOutputOption = class(TForm)
    rgPrincipal: TRadioGroup;
    Label1: TLabel;
    btnOk: TButton;
    btnCancel: TButton;
    procedure btnOkClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    wTotaSameFilesOutput: Integer;
    WSameFilesOutputOption: ^TWSameFilesOutputOption;
  public

    constructor Create(AOwner: TComponent; pTotalSameFilesOutput: Integer; var pSameFilesOutputOption: TWSameFilesOutputOption); overload;
  end;

var
  frmSameFilesOutputOption: TfrmSameFilesOutputOption;

implementation

{$R *.dfm}

constructor TfrmSameFilesOutputOption.Create(AOwner: TComponent; pTotalSameFilesOutput: Integer; var pSameFilesOutputOption: TWSameFilesOutputOption);
begin
  inherited Create(AOwner);

  wTotaSameFilesOutput := pTotalSameFilesOutput;
  WSameFilesOutputOption := @pSameFilesOutputOption;
end;

procedure TfrmSameFilesOutputOption.FormShow(Sender: TObject);
begin
  if wTotaSameFilesOutput = 1 then
    Label1.Caption := 'Existe um arquivo com o mesmo título '
  else if wTotaSameFilesOutput > 1 then
    Label1.Caption := 'Foram enontrados ' + IntToStr(wTotaSameFilesOutput) + ' arquivos com títulos iguais';
end;

procedure TfrmSameFilesOutputOption.btnOkClick(Sender: TObject);
begin
  case rgPrincipal.ItemIndex of
    0: WSameFilesOutputOption^ := sfOverwrite;
    1: WSameFilesOutputOption^ := sfKeepboth;
    2: WSameFilesOutputOption^ := sfDontcopy;
  end;

  ModalResult := mrOk;
end;

procedure TfrmSameFilesOutputOption.btnCancelClick(Sender: TObject);
begin
  //WSameFilesOutputOption := sfNone;
  ModalResult := mrCancel;
  Close;
end;



end.
