unit unit_global;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uCefInterfaces, uCefChromium;

const
  PROJECT_NAME = 'bebop';
  G_VAR_IN_JS_NAME = '__G_VAR_2BDF21C9_321C_4DBE_8C1B_175448499FB8__';
  VTYPE_FUNCTION_NAME = '__VTYPE_FUNCTION_NAME_{CA01F355-FE0D-4A3B-B9E2-BC3554352028}__';
  VTYPE_OBJECT_NAME = '__VTYPE_OBJECT_NAME_{A3A358C6-CCE5-4508-9B8E-6BECF6036E26}__';
  VTYPE_OBJECT_FIELD = '__VTYPE_OBJECT_FIELD_{1A77DB7F-367C-4A9C-A64F-385D0A75736D}__';

  ERROR_ENOENT = 'ENOENT';
  ERROR_OVER_THE_LIMIT = 'ERR_OVER_THE_LIMIT';
  ERROR_INVALID_HANDLE_VALUE = 'ERR_INVALID_HANDLE_VALUE';
  ERROR_INVALID_PARAM_COUNT = 'ERR_INVALID_PARAM_COUNT';

type

  { TSafeStringList }

  TSafeStringList = class
  private
  protected
    FStringList: TStringList;
    FCriticalSection: TRtlCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function AddObject(const S: string; AObject: TObject): Integer;
    function GetObject(const S: string): TObject;
    function RemoveObject(const S: string): boolean;
  end;

var
  dogroot, modroot, restroot, execPath: string;
  ThreadList, ThreadClassList, RestClassList: TStringList;
  ModuleHandlerList: TStringList;
  ObjectList: TSafeStringList;
  appCanClose, appClosing: boolean;
  shareDictionary: ICefDictionaryValue;
  Chromium: TChromium;

function NewUID(): string;
function normalizeResourceName(const filename: string): string;

implementation

function NewUID(): string;
var
  guid: TGUID;
begin
  CreateGUID(guid);
  Result:= GUIDToString(guid);
end;

function normalizeResourceName(const filename: string): string;
begin
  Result:= filename;
  if Pos('http://0.0.0.0/', filename) = 1 then begin
    Result:= Copy(filename, 16, Length(filename));
  end;
end;

procedure ClearPromiseThreadList();
var
  obj: TObject;
begin
  while ThreadList.Count > 0 do begin
    obj:= ThreadList.Objects[0];
    if Assigned(obj) then obj.Free;
    ThreadList.Delete(0);
  end;
end;

{ TSafeStringList }

constructor TSafeStringList.Create;
begin
  FStringList:= TStringList.Create;
  FStringList.Sorted:= True;
  FStringList.OwnsObjects:= True;
  InitCriticalSection(FCriticalSection);
  inherited Create;
end;

destructor TSafeStringList.Destroy;
begin
  FStringList.Free;
  DoneCriticalSection(FCriticalSection);
  inherited Destroy;
end;

function TSafeStringList.AddObject(const S: string; AObject: TObject): Integer;
begin
  EnterCriticalSection(FCriticalSection);
  try
    Result:= FStringList.AddObject(S, AObject);
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;

function TSafeStringList.GetObject(const S: string): TObject;
var
  i: integer;
begin
  //EnterCriticalSection(FCriticalSection);
  //try
    i:= FStringList.IndexOf(S);
    Result:= nil;
    if i >= 0 then Result:= FStringList.Objects[i];
  //finally
  //  LeaveCriticalSection(FCriticalSection);
  //end;
end;

function TSafeStringList.RemoveObject(const S: string): boolean;
var
  i: integer;
begin
  EnterCriticalSection(FCriticalSection);
  try
    i:= FStringList.IndexOf(S);
    Result:= false;
    if i >= 0 then begin
      FStringList.Delete(i);
      Result:= True;
    end;
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;

initialization
  ThreadList:= TStringList.Create;
  ThreadList.Sorted:= True;
  ThreadClassList:= TStringList.Create;
  ThreadClassList.Sorted:= True;
  RestClassList:= TStringList.Create;
  RestClassList.Sorted:= True;
finalization
  ClearPromiseThreadList();
  ThreadList.Free;
  ThreadClassList.Free;
  RestClassList.Free;
  if Assigned(ModuleHandlerList) then ModuleHandlerList.Free;
  if Assigned(ObjectList) then ObjectList.Free;
end.

