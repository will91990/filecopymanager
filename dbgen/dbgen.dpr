program dbgen;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UWDbGen in 'UWDbGen.pas';

begin
  try
    if (ParamCount > 0) then
    begin
      if (ParamStr(1) = '-i') then //INIT - cria as tabelas de sitema e de usuário; insere dados default nas tabelas;
      begin
        CreateDatabase;

        //Tabelas de systema
        CreateSystemTables;
        InsertSystemData;

        //Tabelas de usuário
        CreateUserTables;
        InsertUserData;
      end
      else if (ParamStr(1) = '-r') then //RESET
      begin
        if FileExists(ExtractFilePath(ParamStr(0)) + '\data.db') then
          DeleteFile(ExtractFilePath(ParamStr(0)) + '\data.db');

        CreateDatabase;

        //Tabelas de systema
        CreateSystemTables;
        InsertSystemData;

        //Tabelas de usuário
        CreateUserTables;
        InsertUserData;
      end
      else if (ParamStr(1) = '-c') then //CLEAR
      begin
        DeleteSystemData;
        DeleteUserData;

        InsertSystemData;
        InsertUserData;
      end;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
