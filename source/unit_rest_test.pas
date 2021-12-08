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

  { TRestApi }

  TRestApi = class(TRestApiBase)
  private
  protected
    function get: string; override;
    function post: string; override;
  public
  end;

{ TRestApi }

function TRestApi.get: string;

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
  Result:= test;
end;

function TRestApi.post: string;
var
  doc: TDocVariantData; // = object
  s: RawUTF8;
begin
  doc.InitJSON(Body);
  doc.GetAsRawUTF8('text', s);
  Result:= s;
end;

initialization
  AddRestApiClass(REST_NAME, TRestApi);
end.

