unit FFilterCopy;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.FileCtrl, Vcl.StdCtrls, Vcl.ExtCtrls, System.Threading,
  Vcl.Mask, System.RegularExpressions, FTransfer, FSameFilesOutputOption, UWGlobal, UWFileFilter, UWFile, UWFileTransfer, UWDatabase, UWDatabase.ExtensionLabels,
  Vcl.Imaging.GIFImg;

type
  TfrmFilterCopy = class(TForm)
    btnTransferFiles: TButton;
    Panel1: TPanel;
    dirlstSource: TDirectoryListBox;
    DriveComboBox1: TDriveComboBox;
    GroupBox1: TGroupBox;
    DriveComboBox2: TDriveComboBox;
    dirlstOutput: TDirectoryListBox;
    GroupBox2: TGroupBox;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    CheckBox1: TCheckBox;
    btnSaveProcess: TButton;
    btnConfigAdicionais: TButton;
    btnNovaPasta: TButton;
    grpFilters: TGroupBox;
    rgTipoTransferencia: TRadioGroup;
    chkConferirIntegridade: TCheckBox;
    chkDateFilter: TCheckBox;
    chkExtension: TCheckBox;
    cbbUniqueExtension: TComboBox;
    cbbCategoryExtension: TComboBox;
    chkSelecionarTudo: TCheckBox;
    chkIncludeSubdir: TCheckBox;
    Panel2: TPanel;
    lblTotalSelectedSizeValue: TLabel;
    lblTotalSelectedFilesValue: TLabel;
    Panel3: TPanel;
    lblTotalSizeValue: TLabel;
    lblTotalFilesValue: TLabel;
    Image1: TImage;
    Image2: TImage;
    cbbDateFilter: TComboBox;
    lblUniqueExtension: TLabel;
    lblCategoria: TLabel;
    edtDirSource: TEdit;
    procedure FormShow(Sender: TObject);
    procedure chkDateFilterClick(Sender: TObject);
    procedure chkExtensionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnNovaPastaClick(Sender: TObject);
    procedure btnTransferFilesClick(Sender: TObject);
    procedure dirlstSourceChange(Sender: TObject);
    procedure cbbUniqueExtensionChange(Sender: TObject);
    procedure chkIncludeSubdirClick(Sender: TObject);
    procedure medtDateFilterExit(Sender: TObject);
    procedure chkSelecionarTudoClick(Sender: TObject);
    procedure cbbDateFilterChange(Sender: TObject);
    procedure cbbCategoryExtensionChange(Sender: TObject);
    procedure DriveComboBox1Change(Sender: TObject);
    procedure DriveComboBox2Change(Sender: TObject);
    procedure edtDirSourceClick(Sender: TObject);
    procedure edtDirSourceExit(Sender: TObject);
  private
    WFileFilter: TWFileFilter;
    procedure RefreshSelectedInfoLabels;
    procedure EnableControls(Parent: TWinControl; Enabled: Boolean);
  public
    { Public declarations }
  end;

var
  frmFilterCopy: TfrmFilterCopy;

implementation

{$R *.dfm}

procedure TfrmFilterCopy.btnNovaPastaClick(Sender: TObject);
var
  lNewDirName: string;
begin
  lNewDirName := InputBox('Novo diretório','Nome:','');

  if lNewDirName = '' then
    Exit;

  if TRegEx.IsMatch(lNewDirName, '^[^\s^\x00-\x1f\\?*:"";<>|\/.][^\x00-\x1f\\?*:"";<>|\/]*[^\s^\x00-\x1f\\?*:"";<>|\/.]+$') then
  begin
    CreateDir(dirlstOutput.Directory + '\' + lNewDirName);
    dirlstOutput.Update;
    dirlstOutput.Selected[dirlstOutput.Items.IndexOf(lNewDirName)] := True;
    dirlstOutput.OpenCurrent;
  end;
end;

procedure TfrmFilterCopy.btnTransferFilesClick(Sender: TObject);
var
  lFileTransfer: TWFileTransfer;
  lWFiles: TWFiles;
  lTransfer: TfrmTransfer;
  lfrmSameFilesOutputOption: TfrmSameFilesOutputOption;
  lSameFilesOutputOption: TWSameFilesOutputOption;
begin

  if WFileFilter.TotalSelectedFiles = 0 then
  begin
    MessageDlg('Nenhum arquivo selecionado', mtWarning, [mbOK], 0);
    Exit;
  end;

  if MessageDlg('Deseja transferir os arquivos selecionados para a pasta ''' + dirlstOutput.Directory + '''?', mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrNo then
    Exit;

  lWFiles := WFileFilter.GenerateFiles;
  lFileTransfer := TWFileTransfer.Create(lWFiles, dirlstOutput.Directory);

  //checar capacidade do drive
  if not lFileTransfer.CheckDriveCapacity then
  begin
    ShowMessage('O disco ' + DriveComboBox2.Drive + ' não possui espaço o suficiente para transferir os arquivos selecionados');
    Exit;
  end;

  //se existem arquivos com o mesmo título no output
  if lFileTransfer.SameFilesOutput > 0 then
  begin
    lfrmSameFilesOutputOption := TfrmSameFilesOutputOption.Create(Self, lFileTransfer.SameFilesOutput, lSameFilesOutputOption);

    try
      if lfrmSameFilesOutputOption.ShowModal = mrOk then
        lFileTransfer.SameFilesOutputOption := lSameFilesOutputOption
      else
        Exit;
    finally
      lfrmSameFilesOutputOption.Free;
    end;
  end;

  //copiar ou mover
  case rgTipoTransferencia.ItemIndex of
    0: lFileTransfer.TransferType := ftCopy;
    1: lFileTransfer.TransferType := ftMove;
  else
    raise Exception.Create('Error Message');
  end;

  //integridade md5
  lFileTransfer.CheckIntegrity := chkConferirIntegridade.Checked;

  // EVENTOS
  lFileTransfer.OnStart := gWDatabase.Start;
  lFileTransfer.OnPause := gWDatabase.Pause;
  lFileTransfer.OnFileTransfer := gWDatabase.FileTransfer;
  lFileTransfer.OnFinish := gWDatabase.Finish;
  lFileTransfer.OnCancel := gWDatabase.Cancel;
  lFileTransfer.OnResume := gWDatabase.Resume;

  lTransfer := TfrmTransfer.Create(Self, lFileTransfer);
  try
    lTransfer.ShowModal;
  finally
    FreeAndNil(lTransfer);
  end;
end;

procedure TfrmFilterCopy.cbbCategoryExtensionChange(Sender: TObject);
begin
  if cbbCategoryExtension.Text = '' then
    Exit;

  cbbUniqueExtension.ClearSelection;
  RefreshSelectedInfoLabels;

  Panel2.SetFocus;
end;

procedure TfrmFilterCopy.cbbDateFilterChange(Sender: TObject);
begin
  RefreshSelectedInfoLabels;
  Panel2.SetFocus;
end;

procedure TfrmFilterCopy.cbbUniqueExtensionChange(Sender: TObject);
begin
  if cbbUniqueExtension.Text = '' then
    Exit;

  cbbCategoryExtension.ClearSelection;
  RefreshSelectedInfoLabels;

  Panel2.SetFocus;
end;

procedure TfrmFilterCopy.chkDateFilterClick(Sender: TObject);
var
  lCreationDateTime: string;
begin
  cbbDateFilter.Enabled := chkDateFilter.Checked;

  if (cbbDateFilter.Enabled) then
  begin
    if (cbbDateFilter.Items.Count = 0) then
    begin
      cbbDateFilter.Clear;

      for lCreationDateTime in WFileFilter.CreationDateTimes do
        cbbDateFilter.Items.Add(lCreationDateTime);

      cbbDateFilter.SetFocus;
    end;

    RefreshSelectedInfoLabels;

    chkDateFilter.SetFocus;
  end
  else
    RefreshSelectedInfoLabels;
end;

procedure TfrmFilterCopy.chkExtensionClick(Sender: TObject);
var
  lExtension: string;
  lExtensions: TStrings;
begin
  lblUniqueExtension.Enabled := chkExtension.Checked;
  cbbUniqueExtension.Enabled := chkExtension.Checked;
  lblCategoria.Enabled := chkExtension.Checked;
  cbbCategoryExtension.Enabled := chkExtension.Checked;

  if (chkExtension.Checked) then
    if (cbbUniqueExtension.Items.Count = 0) and (cbbCategoryExtension.Items.Count = 0) then
    begin
      cbbUniqueExtension.Clear;

      for lExtension in WFileFilter.Extensions do
        cbbUniqueExtension.Items.Add(lExtension);

      cbbCategoryExtension.Clear;
      lExtensions := TStringList.Create;

      for lExtension in WFileFilter.Extensions do
        lExtensions.Add(lExtension);

      cbbCategoryExtension.Items := getLabelsFromExtensions(lExtensions);
    end;

  if (cbbUniqueExtension.Text <> '') or (cbbCategoryExtension.Text <> '') then
    RefreshSelectedInfoLabels;
end;

procedure TfrmFilterCopy.chkIncludeSubdirClick(Sender: TObject);
begin
  RefreshSelectedInfoLabels;
end;

procedure TfrmFilterCopy.chkSelecionarTudoClick(Sender: TObject);
begin
  if chkSelecionarTudo.Checked then
  begin
    chkDateFilter.Enabled := False;
    chkExtension.Enabled := False;
    lblUniqueExtension.Enabled := False;
    lblCategoria.Enabled := False;
    cbbUniqueExtension.Enabled := False;
    cbbCategoryExtension.Enabled := False;
  end
  else
  begin
    chkDateFilter.Enabled := True;
    cbbDateFilter.Enabled := chkDateFilter.Checked;

    chkExtension.Enabled := True;
    lblUniqueExtension.Enabled := chkExtension.Checked;
    lblCategoria.Enabled := chkExtension.Checked;
    cbbUniqueExtension.Enabled := chkExtension.Checked;
    cbbCategoryExtension.Enabled := chkExtension.Checked;
  end;

  RefreshSelectedInfoLabels;
end;

procedure TfrmFilterCopy.dirlstSourceChange(Sender: TObject);
var
  lTask: ITask;
begin
  edtDirSource.Text := dirlstSource.Directory;

  lTask := TTask.Create(
    procedure
    begin
      Self.EnableControls(Self, False);

      WFileFilter.SourcePath := dirlstSource.Directory;
      WFileFilter.Refresh;

      TThread.Synchronize(TThread.Current,
      procedure
      var
        lExtension: string;
        lCreationDateTime: string;
      begin
        Image1.Visible := False;
        lblTotalFilesValue.Caption := 'Total: '+ IntToStr(WFileFilter.TotalDirectoryFiles) + ' arquivos';
        //lblTotalSizeValue.Caption := 'Tamanho: ' + IntToStr(WFileFilter.TotalDirectorySize) + ' bytes';;
        lblTotalSizeValue.Caption := 'Tamanho: ' + FileSizeToString(WFileFilter.TotalDirectorySize);
        lblTotalFilesValue.Visible := True;
        lblTotalSizeValue.Visible := True;
        
        chkSelecionarTudo.Checked := False;
        chkIncludeSubdir.Checked := False;
        chkExtension.Checked := False;
        chkDateFilter.Checked := False;

        cbbUniqueExtension.Clear;
        cbbCategoryExtension.Clear;
        cbbDateFilter.Clear;

        lblTotalSelectedFilesValue.Caption := '0 arquivos selecionados';
        lblTotalSelectedSizeValue.Caption := '0 bytes';

        Self.EnableControls(Self, True);
      end);
    end);

  lTask.Start;

  lblTotalFilesValue.Visible := False;
  lblTotalSizeValue.Visible := False;
  Image1.Visible := True;
end;

procedure TfrmFilterCopy.DriveComboBox1Change(Sender: TObject);
begin
  dirlstSource.SetFocus;
end;

procedure TfrmFilterCopy.DriveComboBox2Change(Sender: TObject);
begin
  dirlstOutput.SetFocus;
end;

procedure TfrmFilterCopy.edtDirSourceClick(Sender: TObject);
begin
  edtDirSource.SelectAll;
end;

procedure TfrmFilterCopy.edtDirSourceExit(Sender: TObject);
begin
  edtDirSource.SelStart := 0;
end;

procedure TfrmFilterCopy.EnableControls(Parent: TWinControl; Enabled: Boolean);
var
  i: Integer;
  Ctl: TControl;
begin
  for i := 0 to Pred(Parent.ControlCount) do
  begin
    Ctl := Parent.Controls[i];
    Ctl.Enabled := Enabled;
    if Ctl is TWinControl then
      EnableControls(TWinControl(Ctl), Enabled);
  end;

  if Enabled then
  begin
    if chkSelecionarTudo.Checked then
    begin
      chkSelecionarTudo.Enabled := True;
      chkExtension.Enabled := False;
      chkDateFilter.Enabled := False;
      cbbDateFilter.Enabled := False;
      lblUniqueExtension.Enabled := False;
      lblCategoria.Enabled := False;
      cbbUniqueExtension.Enabled := False;
      cbbCategoryExtension.Enabled := False;
    end
    else if chkExtension.Checked or chkDateFilter.Checked then
    begin
      //chkSelecionarTudo.Enabled := False;
      chkExtension.Enabled := True;
      chkDateFilter.Enabled := True;
      cbbDateFilter.Enabled := chkDateFilter.Checked;
      lblUniqueExtension.Enabled := chkExtension.Checked;
      lblCategoria.Enabled := chkExtension.Checked;
      cbbUniqueExtension.Enabled := chkExtension.Checked;
      cbbCategoryExtension.Enabled := chkExtension.Checked;
    end
    else
    begin
      chkSelecionarTudo.Enabled := True;
      chkExtension.Enabled := True;
      chkDateFilter.Enabled := True;
      lblUniqueExtension.Enabled := False;
      lblCategoria.Enabled := False;
      cbbUniqueExtension.Enabled := False;
      cbbCategoryExtension.Enabled := False;
      cbbDateFilter.Enabled := False;
    end;
  end;
end;

procedure TfrmFilterCopy.FormCreate(Sender: TObject);
begin
  WFileFilter := TWFileFilter.Create;
  TGIFImage(Image1.Picture.Graphic).Animate := True;
  TGIFImage(Image2.Picture.Graphic).Animate := True;
end;

procedure TfrmFilterCopy.FormShow(Sender: TObject);
begin
  //GetVolumeInformation()

  dirlstSource.Directory := DriveComboBox1.Drive + ':\';
  dirlstOutput.Directory := DriveComboBox1.Drive + ':\';
end;

procedure TfrmFilterCopy.medtDateFilterExit(Sender: TObject);
begin
  RefreshSelectedInfoLabels;
end;

procedure TfrmFilterCopy.RefreshSelectedInfoLabels;
var
  lExtensionsFilter: TStrings;
  lTask: ITask;
begin
  if chkSelecionarTudo.Checked then
    WFileFilter.SelectAll := True
  else
  begin
    WFileFilter.SelectAll := False;

    // FILTRO DE DATA
    if (chkDateFilter.Enabled) and (chkDateFilter.Checked) then
    begin
      if (cbbDateFilter.Text <> '') then
        WFileFilter.DateFilter := StrToDate(cbbDateFilter.Text);
    end
    else
      WFileFilter.DateFilter := -1;

    // FILTRO DE EXTENSÃO
    lExtensionsFilter := TStringList.Create;

    if (chkExtension.Enabled) and (chkExtension.Checked) then
    begin
      if cbbUniqueExtension.Text <> '' then
      begin

        lExtensionsFilter.Add(cbbUniqueExtension.Text);

        WFileFilter.ExtensionsFilter := lExtensionsFilter;
      end
      else if cbbCategoryExtension.Text <> '' then
        WFileFilter.ExtensionsFilter := getExtensionsFromLabel(cbbCategoryExtension.Text);//lExtensionsFilter;
    end
    else
      WFileFilter.ExtensionsFilter := lExtensionsFilter;
  end;

  lTask := TTask.Create(
  procedure
  var
    lTotalSelectedFiles, lTotalSelectedSize: string;
  begin

    lTotalSelectedFiles := IntToStr(WFileFilter.TotalSelectedFiles) + ' arquivos selecionados';
    //lTotalSelectedSize := IntToStr(WFileFilter.TotalSelectedSize) + ' bytes';
    lTotalSelectedSize := FileSizeToString(WFileFilter.TotalSelectedSize);

    EnableControls(Self, False);

    TThread.Synchronize(TThread.Current,
    procedure
    begin
      lblTotalSelectedFilesValue.Caption := lTotalSelectedFiles;
      lblTotalSelectedSizeValue.Caption := lTotalSelectedSize;
      Image2.Visible := False;
      lblTotalSelectedFilesValue.Visible := True;
      lblTotalSelectedSizeValue.Visible := True;

      EnableControls(Self, True); //ver isso
    end);
  end);

  lTask.Start;

  lblTotalSelectedFilesValue.Visible := False;
  lblTotalSelectedSizeValue.Visible := False;
  Image2.Visible := True;
end;

end.
