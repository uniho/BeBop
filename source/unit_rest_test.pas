unit unit_rest_test;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation
uses
  unit_global, unit_rest, SynCommons, SynDB, SynDBSQLite3;

const
  REST_NAME = 'test';

type

  { TTestRestApi }

  TTestRestApi = class(TRestApi)
  private
  protected
    function get: string; override;
    function post: string; override;
  public
  end;

{ TTestRestApi }

function TTestRestApi.get: string;

  //
  function direct: string;
  var
    cp: TSQLDBConnectionProperties;
    rows: ISQLDBRows;
    rowCount: PtrInt;
  begin
    cp:= TSQLDBSQLite3ConnectionProperties.Create(dogroot + '.test.sqlite', '', '', '');
    try
      rows:= cp.Execute('SELECT * FROM MusicTable', []);
      try
        Result:= rows.FetchAllAsJSON(True, @rowCount);
        if rowCount = 0 then Result:= '[]';
      finally
        rows:= nil; // Why bother? This is because, needs to free before `cp.Free`!
      end;
    finally
      cp.Free;
    end;
  end;

  //
  function test: string;
  var
    i: integer;
  begin
    Result:= '';
    for i:= 0 to Length(PathArray)-1 do begin
      if i > 0 then Result:= Result + ' + ';
      Result:= Result + PathArray[i];
    end;

    for i:= 0 to QueryList.Count-1 do begin
      Result:= Result + ' & ' + QueryList.Names[i] + ' = ' + QueryList.ValueFromIndex[i];
    end;
  end;

begin
  case PathArray[0] of
    'direct': Result:= direct;
    else Result:= test;
  end;
end;

function TTestRestApi.post: string;
var
  doc: TDocVariantData; // = object
  s: RawUTF8;
begin
  doc.InitJSON(Body);
  doc.GetAsRawUTF8('text', s);
  Result:= s;
end;

initialization
  AddRestApiClass(REST_NAME, TTestRestApi);
end.

