object frmTransfer: TfrmTransfer
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Transferindo'
  ClientHeight = 96
  ClientWidth = 385
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 8
    Width = 31
    Height = 13
    Caption = 'Label1'
  end
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 27
    Width = 369
    Height = 25
    TabOrder = 0
  end
  object btnCancelar: TButton
    Left = 302
    Top = 58
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 1
    OnClick = btnCancelarClick
  end
  object btnPausarRetomar: TButton
    Left = 220
    Top = 58
    Width = 75
    Height = 25
    Caption = 'Pausar'
    TabOrder = 2
    OnClick = btnPausarRetomarClick
  end
end
