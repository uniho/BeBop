unit unit_mod_process;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation

uses
  unit_js, unit_thread,
  uCEFTypes, uCEFInterfaces, unit_global, LazFileUtils,
  uCEFConstants, uCEFv8Context, uCEFv8Value, uCEFValue;

const
  MODULE_NAME = 'process'; //////////

type

  { TRequireThread }

  TRequireThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function importCreate(const name: string): ICefv8Value;

  //
  function env: ICefv8Value;
  var
    i, len: integer;
    sl: TStringList;
  begin
    sl:= TStringList.Create;
    try
      len:= GetEnvironmentVariableCount;
      for i:= 1 to len do begin
        sl.Add(GetEnvironmentString(i));
      end;
      Result:= TCefv8ValueRef.NewObject(nil, nil);
      for i:= 0 to len-1 do begin
        Result.SetValueByKey(UTF8Decode(sl.Names[i]),
          TCefv8ValueRef.NewString(UTF8Decode(sl.ValueFromIndex[i])), V8_PROPERTY_ATTRIBUTE_NONE);
      end;
    finally
      sl.Free;
    end;
  end;

begin
  Result:= TCefv8ValueRef.NewObject(nil, nil);

  Result.SetValueByKey('env', env, V8_PROPERTY_ATTRIBUTE_NONE);

  {$IF Defined(WINDOWS)}
  Result.SetValueByKey('platform',
    TCefv8ValueRef.NewString('win32'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(DARWIN)}
  Result.SetValueByKey('platform',
    TCefv8ValueRef.NewString('darwin'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(LINUX)}
  Result.SetValueByKey('platform',
    TCefv8ValueRef.NewString('linux'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ENDIF}

  {$IF Defined(CPUPOWERPC32)}
  Result.SetValueByKey('arch',
    TCefv8ValueRef.NewString('ppc'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPUPOWERPC64)}
  Result.SetValueByKey('arch',
    TCefv8ValueRef.NewString('ppc64'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPUAARCH64)}
  Result.SetValueByKey('arch',
    TCefv8ValueRef.NewString('arm64'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPUARM)}
  Result.SetValueByKey('arch',
    TCefv8ValueRef.NewString('arm'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPU64)}
  Result.SetValueByKey('arch',
    TCefv8ValueRef.NewString('x64'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPU32)}
  Result.SetValueByKey('arch',
    TCefv8ValueRef.NewString('x32'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ENDIF}
end;

//
function requireCreate(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;

  //
  function env: ICefv8Value;
  var
    i, len: integer;
    sl: TStringList;
  begin
    sl:= TStringList.Create;
    try
      len:= GetEnvironmentVariableCount;
      for i:= 1 to len do begin
        sl.Add(GetEnvironmentString(i));
      end;
      Result:= TCefv8ValueRef.NewObject(nil, nil);
      for i:= 0 to len-1 do begin
        Result.SetValueByKey(UTF8Decode(sl.Names[i]),
          TCefv8ValueRef.NewString(UTF8Decode(sl.ValueFromIndex[i])), V8_PROPERTY_ATTRIBUTE_NONE);
      end;
    finally
      sl.Free;
    end;
  end;

begin
  Result:= False;

  retval:= TCefv8ValueRef.NewObject(nil, nil);

  retval.SetValueByKey('env', env, V8_PROPERTY_ATTRIBUTE_NONE);

  {$IF Defined(WINDOWS)}
  retval.SetValueByKey('platform',
    TCefv8ValueRef.NewString('win32'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(DARWIN)}
  retval.SetValueByKey('platform',
    TCefv8ValueRef.NewString('darwin'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(LINUX)}
  retval.SetValueByKey('platform',
    TCefv8ValueRef.NewString('linux'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ENDIF}

  {$IF Defined(CPUPOWERPC32)}
  retval.SetValueByKey('arch',
    TCefv8ValueRef.NewString('ppc'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPUPOWERPC64)}
  retval.SetValueByKey('arch',
    TCefv8ValueRef.NewString('ppc64'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPUAARCH64)}
  retval.SetValueByKey('arch',
    TCefv8ValueRef.NewString('arm64'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPUARM)}
  retval.SetValueByKey('arch',
    TCefv8ValueRef.NewString('arm'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPU64)}
  retval.SetValueByKey('arch',
    TCefv8ValueRef.NewString('x64'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ELSEIF Defined(CPU32)}
  retval.SetValueByKey('arch',
    TCefv8ValueRef.NewString('x32'), V8_PROPERTY_ATTRIBUTE_NONE);
  {$ENDIF}

  Result:= True;
end;

//
function requireExecute(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  v, g: ICefv8Value;
  uuid: string;
begin
  // (resolve, reject) => {...}

  Result:= requireCreate(name, obj, arguments, retval, exception);
  if not Result or (exception <> '') then Exit;

  uuid:= StartPromiseThread(TRequireThread,
    [], arguments[0], arguments[1], MODULE_NAME, 'require');
  g:= TCefv8ContextRef.Current.GetGlobal;
  v:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc').GetValueByKey(UTF8Decode(uuid));
  v.SetValueByKey('resolve_args', retval, V8_PROPERTY_ATTRIBUTE_NONE);

  Result:= True;
end;

{ TRequireThread }

procedure TRequireThread.ExecuteAct;
begin
  // Nothing to do
  CefResolve:= TCefValueRef.New;
end;


//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result:= False;
end;

//
const
  _import = G_VAR_IN_JS_NAME + '["~' + MODULE_NAME + '"]';
  _body = '' +
     'export const env=' + _import + '.env;' +
     'export const platform=' + _import + '.platform;' +
     'export const arch=' + _import + '.arch;' +
     ';';

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute);
  AddModuleHandler('~'+MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread);
end.

