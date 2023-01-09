unit UWDatabase.ExtensionLabelsV2;

interface

uses
  System.Classes, System.SysUtils, SQLite3.Classes, UWDatabaseV2;

function getLabelsFromExtensions(pExtensions: TStrings): TStrings;
function getExtensionsFromLabel(pLabel: string): TStrings;

implementation

function getLabelsFromExtensions(pExtensions: TStrings): TStrings;
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
  lExtension: string;
  lInSql: string;
  lLabels: TStrings;
begin
  lInSql := '';

  for lExtension in pExtensions do
    if lInSql = '' then
      lInSql := QuotedStr(lExtension)
    else
      lInSql := lInSql + ',' + QuotedStr(lExtension);

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'SELECT                                                                ' +
      '  DISTINCT b.id_label,                                                ' +
      '  b.label                                                             ' +
      'FROM                                                                  ' +
      '  extensions_label a INNER JOIN labels b ON (a.id_label = b.id_label) ' +
      'WHERE                                                                 ' +
      '  a.extension IN ('+ lInSql +');                                      ');

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela extensions_label. Mensagem: ' + e.Message);
    end;

    lLabels := TStringList.Create;

    lSQLiteCursor.First;

    while lSQLiteCursor.HasData do
    begin
      lLabels.Add(lSQLiteCursor.ColumnAsString[1]);
      lSQLiteCursor.Next;
    end;

    Result := lLabels;
  finally
    //lSQLiteCursor.Free;
    lSQLiteStatement.Free;
  end;
end;

function getExtensionsFromLabel(pLabel: string): TStrings;
var
  lSQLiteStatement: TSQLiteStatement;
  lSQLiteCursor: TSQLiteCursor;
  lExtensions: TStrings;
begin

  try
    lSQLiteStatement := GetDatabaseConnection.Query(
      'SELECT                                                               ' +
      '  extension                                                          ' +
      'FROM                                                                 ' +
      '  extensions_label a INNER JOIN labels b ON(a.id_label = b.id_label) ' +
      'WHERE                                                                ' +
      '  b.label = :pLabel                                                  ');
    lSQLiteStatement.ParamByName[':pLabel'] := pLabel;

    try
      lSQLiteCursor := lSQLiteStatement.Cursor;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela extensions_label. Mensagem: ' + e.Message);
    end;

    lExtensions := TStringList.Create;

    lSQLiteCursor.First;

    while lSQLiteCursor.HasData do
    begin
      lExtensions.Add(lSQLiteCursor.ColumnAsString[0]);
      lSQLiteCursor.Next;
    end;

    Result := lExtensions;
  finally
    //lSQLiteCursor.Free;
    lSQLiteStatement.Free;
  end;
end;

end.
