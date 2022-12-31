object frmSameFilesOutputOption: TfrmSameFilesOutputOption
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Aviso'
  ClientHeight = 235
  ClientWidth = 271
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
    Width = 224
    Height = 30
    Caption = 
      'Foi encontrado um arquivo com o mesmo'#13#10't'#237'tulo no diret'#243'rio de ou' +
      'tput'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Nirmala UI'
    Font.Style = []
    ParentFont = False
  end
  object rgPrincipal: TRadioGroup
    Left = 8
    Top = 56
    Width = 257
    Height = 129
    Caption = 'Selecione'
    Items.Strings = (
      'Substituir'
      'Manter todos os arquivos'
      'N'#227'o copiar')
    TabOrder = 0
  end
  object btnOk: TButton
    Left = 109
    Top = 202
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 190
    Top = 202
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 2
    OnClick = btnCancelClick
  end
end
