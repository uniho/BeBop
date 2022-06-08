unit unit_rest;

{$DEFINE USE_mORMot}
{$DEFINE USE_REST_TEST}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  uCEFInterfaces;

type

  { TRestApiBase }

  TRestApiBase = class(TObject)
  private
  protected
    Status: integer;
    PathArray: array of string;
    QueryList, responseHeader: TStringList;
    Path, Query, Body, StatusText: string;
    Request: ICefRequest;
    FCriticalSection: TRtlCriticalSection;
    function get: string; virtual;
    function post: string; virtual;
    function put: string; virtual;
    function patch: string; virtual;
    function delete: string; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
  end;

  TRestApiClass = class of TRestApiBase;

procedure AddRestApiClass(const restName: string; baseClass: TRestApiClass);

function GetFromRestApi(const url: string; request: ICefRequest;
  var status: integer; var statusText: string; const responseHeader: TStringList): string;

implementation

uses
  {$IF Defined(USE_mORMot)}
  SynCommons,
  {$IF Defined(USE_REST_TEST)}
  unit_rest_test, unit_rest_test_sqlite,
  {$ENDIF}
  {$ENDIF}
  unit_global, uCEFTypes;

procedure AddRestApiClass(const restName: string; baseClass: TRestApiClass);
begin
  RestClassList.AddObject(restName, TObject(baseClass));
end;

function GetFromRestApi(const url: string; request: ICefRequest;
  var status: integer; var statusText: string; const responseHeader: TStringList): string;
var
  rest: TRestApiBase;
  i, len: integer;
  restName, path, s: string;
  bodys: TCefPostDataElementArray;
  {$IF Defined(USE_mORMot)}
  p: PUTF8Char;
  ru8s1, ru8s2: RawUTF8;
  {$ENDIF}
begin
  i:= Pos('/', url);
  if i = 0 then SysUtils.Abort;
  restName:= Copy(url, 1, i-1);
  path:= Copy(url, i+1, Length(url));
  i:= RestClassList.IndexOf(restName);
  if i < 0 then
    raise SysUtils.Exception.Create('You forgot to add "' + restName + '" to RestClassList.');
  rest:= TRestApiClass(RestClassList.Objects[i]).Create();
  try
    i:= Pos('?', path);
    if i > 0 then begin
      rest.Path:= Copy(path, 1, i-1);
      rest.Query:= Copy(path, i+1, Length(path));
    end else begin
      rest.Path:= path;
      rest.Query:= '';
    end;

    s:= rest.Path;
    while True do begin
      i:= Pos('/', s);
      SetLength(rest.PathArray, Length(rest.PathArray)+1);
      if i = 0 then begin
        rest.PathArray[Length(rest.PathArray)-1]:= s;
        break;
      end else if i = Length(s) then begin
        rest.PathArray[Length(rest.PathArray)-1]:= Copy(s, 1, Length(s)-1);
        break;
      end else begin
        rest.PathArray[Length(rest.PathArray)-1]:= Copy(s, 1, i-1);
        Delete(s, 1, i);
      end;
    end;

    {$IF Defined(USE_mORMot)}
    p:= PUTF8Char(rest.Query);
    while p^ <> #0 do begin
      p:= UrlDecodeNextNameValue(p, ru8s1{%H-}, ru8s2{%H-});
      if not Assigned(p) then break;
      rest.QueryList.Add(LowerCase(ru8s1) + '=' + LowerCase(ru8s2))
    end;
    {$ENDIF}

    rest.Request:= request;
    rest.responseHeader:= responseHeader;
    rest.Body:= '';
    if Assigned(request.PostData) then begin
      len:= request.PostData.GetElementCount;
      if len > 0 then begin
        SetLength(bodys{%H-}, len);
        request.PostData.GetElements(len, bodys);
        // 'Content-Type': 'application/json'
        if bodys[0].GetType = PDE_TYPE_BYTES then begin
          for i:= 0 to len-1 do begin
            SetLength(s, bodys[i].GetBytesCount);
            bodys[i].GetBytes(bodys[i].GetBytesCount, @s[1]);
            rest.Body:= rest.Body + s;
          end;
        end;
      end;
    end;

    case LowerCase(UTF8Encode(request.GetMethod)) of
      'get': Result:= rest.get;
      'post': Result:= rest.post;
      'put': Result:= rest.put;
      'patch': Result:= rest.patch;
      'delete': Result:= rest.delete;
    end;

    status:= rest.Status;
    statusText:= rest.StatusText;

  finally
    rest.Free;
  end;
end;

{ TRestApiBase }

function TRestApiBase.get: string;
begin
  Status:= 400; // HTTP_BADREQUEST
  StatusText:= 'Bad Request';
  Result:= '';
end;

function TRestApiBase.post: string;
begin
  Status:= 400; // HTTP_BADREQUEST
  StatusText:= 'Bad Request';
  Result:= '';
end;

function TRestApiBase.put: string;
begin
  Status:= 400; // HTTP_BADREQUEST
  StatusText:= 'Bad Request';
  Result:= '';
end;

function TRestApiBase.patch: string;
begin
  Status:= 400; // HTTP_BADREQUEST
  StatusText:= 'Bad Request';
  Result:= '';
end;

function TRestApiBase.delete: string;
begin
  Status:= 400; // HTTP_BADREQUEST
  StatusText:= 'Bad Request';
  Result:= '';
end;

constructor TRestApiBase.Create;
begin
  Status:= 200; // HTTP_SUCCESS
  StatusText:= 'OK';
  QueryList:= TStringList.Create;
  QueryList.Sorted:= True;
  InitCriticalSection(FCriticalSection);
  inherited Create;
end;

destructor TRestApiBase.Destroy;
begin
  QueryList.Free;
  DoneCriticalSection(FCriticalSection);
  inherited Destroy;
end;

procedure TRestApiBase.Lock;
begin
  System.EnterCriticalSection(FCriticalSection);
end;

procedure TRestApiBase.Unlock;
begin
  System.LeaveCriticalSection(FCriticalSection);
end;

end.

