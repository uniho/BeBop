unit unit_rest_test_sqlite;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation
uses
  unit_global, unit_rest,
  SynSQLite3Static, SynCommons, mORMot, mORMotSQLite3;

const
  REST_NAME = 'test-sqlite';

type

  { TSqliteRestApi }

  TSqliteRestApi = class(TRestApi)
  private
  protected
    function get: string; override;
    function post: string; override;
    function delete: string; override;
    function put: string; override;
  public
  end;

  { TMusicTable }

  TMusicTable = class(TSQLRecord)
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

procedure CreateRestServer;
begin
  RestServer:= TSQLRestServerDB.CreateWithOwnModel(
    [TMusicTable],
    dogroot + '.test.sqlite', false, REST_NAME);

  RestServer.CreateMissingTables;
end;

{ TSqliteRestApi }

function TSqliteRestApi.get: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer;
  params.Url:= REST_NAME + '/' + Path + '?' + Query;
  params.Method:= 'GET';
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

function TSqliteRestApi.post: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer;
  params.Url:= REST_NAME + '/' + Path;
  params.Method:= 'POST';
  params.InBody:= Body;
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

function TSqliteRestApi.delete: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer;
  params.Url:= REST_NAME + '/' + Path;
  params.Method:= 'DELETE';
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

function TSqliteRestApi.put: string;
var
  params: TSQLRestURIParams;
begin
  if not Assigned(RestServer) then CreateRestServer;
  params.Url:= REST_NAME + '/' + Path;
  params.Method:= 'PUT';
  params.InBody:= Body;
  params.RestAccessRights:= @SUPERVISOR_ACCESS_RIGHTS;
  RestServer.URI(params);
  Result:= params.OutBody;
end;

initialization
  AddRestApiClass(REST_NAME, TSqliteRestApi);
  RestServer:= nil;
finalization
  if Assigned(RestServer) then RestServer.Free;
end.

