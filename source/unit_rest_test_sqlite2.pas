unit unit_rest_test_sqlite2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation
uses
  unit_global, unit_rest,
  mormot.core.base, mormot.rest.core, mormot.rest.server,
  mormot.orm.core, mormot.rest.sqlite3, mormot.db.raw.sqlite3.static;

const
  REST_NAME = 'test-sqlite';

type

  { TRestApi }

  TRestApi = class(TRestApiBase)
  private
  protected
    function get: string; override;
    function post: string; override;
    function delete: string; override;
    function put: string; override;
  public
  end;

  { TMusicTable }

  TMusicTable = class(TOrm)
  private
    FTitle: RawUTF8;
    FArtist: RawUTF8;
    FReleased: TDateTime;
  published
    property Title: RawUTF8 index 100 read FTitle write FTitle;
    property Artist: RawUTF8 index 100 read FArtist write FArtist;
    property Released: TDateTime read FReleased write FReleased;
  end;

var
  RestServer: TSQLRestServer;

procedure CreateRestServer(rest: TRestApiBase);
begin
  rest.Lock;
  try
    if Assigned(RestServer) then Exit;
    RestServer:= TSQLRestServerDB.CreateWithOwnModel(
      [TMusicTable],
      dogroot + '.test.sqlite', false, REST_NAME);

    RestServer.CreateMissingTables;
  finally
    rest.Unlock;
  end;
end;

{ TRestApi }

function TRestApi.get: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer(Self);
  params.Url:= REST_NAME + '/' + Path + '?' + Query;
  params.Method:= 'GET';
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

function TRestApi.post: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer(Self);
  params.Url:= REST_NAME + '/' + Path;
  params.Method:= 'POST';
  params.InBody:= Body;
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

function TRestApi.delete: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer(Self);
  params.Url:= REST_NAME + '/' + Path;
  params.Method:= 'DELETE';
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

function TRestApi.put: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer(Self);
  params.Url:= REST_NAME + '/' + Path;
  params.Method:= 'PUT';
  params.InBody:= Body;
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

initialization
  AddRestApiClass(REST_NAME, TRestApi);
  RestServer:= nil;
finalization
  if Assigned(RestServer) then RestServer.Free;
end.

