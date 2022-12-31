unit UWAutoResumeTransfer;

interface

uses
  System.SysUtils, System.Classes, Vcl.Dialogs, Vcl.Controls, UWFile, UWFileTransfer, UWDatabase, FTransfer;

procedure WAutoResumeTransfer(AOwner: TComponent);

implementation

procedure WAutoResumeTransfer(AOwner: TComponent);
var
  lIdFileTransfer, count: Integer;
  lFileTransfer: TWFileTransfer;
	lWFiles: TWFiles;
	lMsg: string;
	//lFileExists: Boolean;
begin

	lIdFileTransfer := gWDatabase.CheckInterruptedFileTransfer;

	if lIdFileTransfer <> -1 then
	begin
		if gWDatabase.CheckPaused(lIdFileTransfer) then // se for transferência pausada
			lMsg := 'Sua última transferência foi pausada. Deseja continuar?'
		else // se for interrompido
			lMsg := 'Sua última transferência foi interrompida. Deseja continuar?';

		//Verificar se os arquivos interrompidos ainda existem para serem copiados
		lWFiles := gWDatabase.GetInterruptedFiles(lIdFileTransfer);

		for count := Low(lWFiles) to High(lWFiles) do
			if not (FileExists(lWFiles[count].Path)) then
			begin
				gWDatabase.RemoveInterruptedData(lIdFileTransfer);
				Exit;
				//lFileExists := False;
				//Break;
			end;

		if MessageDlg(lMsg, mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes then
		begin
			// continua transferência da onde parou
			lFileTransfer := gWDatabase.GetFileTransfer(lIdFileTransfer, lWFiles);
      frmTransfer := TfrmTransfer.Create(AOwner, lFileTransfer);
      try
        frmTransfer.ShowModal;
      finally
        FreeAndNil(frmTransfer);
      end;
		end
		else
			gWDatabase.RemoveInterruptedData(lIdFileTransfer);
	end;
end;

end.
