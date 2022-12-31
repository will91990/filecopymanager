unit UWDatabase.ExtensionLabels;

interface

uses
  System.Classes, System.SysUtils, LiteCall, LiteConsts, Data.DB, DBAccess, LiteAccess, UWDatabase;

function getLabelsFromExtensions(pExtensions: TStrings): TStrings;
function getExtensionsFromLabel(pLabel: string): TStrings;

implementation

function getLabelsFromExtensions(pExtensions: TStrings): TStrings;
var
  lLiteQuery: TLiteQuery;
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

  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'SELECT                                                                ' +
      '  DISTINCT b.id_label,                                                ' +
      '  b.label                                                             ' +
      'FROM                                                                  ' +
      '  extensions_label a INNER JOIN labels b ON (a.id_label = b.id_label) ' +
      'WHERE                                                                 ' +
      '  a.extension IN ('+ lInSql +');                                      ';

    try
      lLiteQuery.Open;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela extensions_label. Mensagem: ' + e.Message);
    end;

    lLabels := TStringList.Create;

    while not lLiteQuery.Eof do
    begin
      lLabels.Add(lLiteQuery.FieldByName('label').AsString);
      lLiteQuery.Next;
    end;

    Result := lLabels;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

function getExtensionsFromLabel(pLabel: string): TStrings;
var
  lLiteQuery: TLiteQuery;
  lExtensions: TStrings;
begin
  lLiteQuery := TLiteQuery.Create(nil);
  lLiteQuery.Connection := GetDatabaseConnection;

  try
    lLiteQuery.SQL.Text :=
      'SELECT                                                               ' +
      '  extension                                                          ' +
      'FROM                                                                 ' +
      '  extensions_label a INNER JOIN labels b ON(a.id_label = b.id_label) ' +
      'WHERE                                                                ' +
      '  b.label = :pLabel;                                                 ';

    try
      lLiteQuery.ParamByName('pLabel').AsString := pLabel;
      lLiteQuery.Open;
    except
      on e: Exception do
        raise Exception.Create('Erro ao tentar selecionar dados na tabela extensions_label. Mensagem: ' + e.Message);
    end;

    lExtensions := TStringList.Create;

    while not lLiteQuery.Eof do
    begin
      lExtensions.Add(lLiteQuery.FieldByName('extension').AsString);
      lLiteQuery.Next;
    end;

    Result := lExtensions;
  finally
    lLiteQuery.Connection.Free;
    FreeAndNil(lLiteQuery);
  end;
end;

end.
