unit unit_mod_path;

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
  MODULE_NAME = 'path'; //////////

type

  { TRequireThread }

  TRequireThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function importCreate(const name: string): ICefv8Value;
var
  handler: ICefv8Handler;
begin
  Result:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'dirname');
  Result.SetValueByKey('dirname',
   TCefv8ValueRef.NewFunction('dirname', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'basename');
  Result.SetValueByKey('basename',
   TCefv8ValueRef.NewFunction('basename', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'extname');
  Result.SetValueByKey('extname',
   TCefv8ValueRef.NewFunction('extname', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'join');
  Result.SetValueByKey('join',
   TCefv8ValueRef.NewFunction('join', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'resolve');
  Result.SetValueByKey('resolve',
   TCefv8ValueRef.NewFunction('resolve', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'relative');
  Result.SetValueByKey('relative',
   TCefv8ValueRef.NewFunction('relative', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'isAbsolute');
  Result.SetValueByKey('isAbsolute',
   TCefv8ValueRef.NewFunction('isAbsolute', handler), V8_PROPERTY_ATTRIBUTE_NONE);
end;

//
function requireCreate(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  handler: ICefv8Handler;
begin
  Result:= False;

  retval:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'dirname');
  retval.SetValueByKey('dirname',
   TCefv8ValueRef.NewFunction('dirname', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'basename');
  retval.SetValueByKey('basename',
   TCefv8ValueRef.NewFunction('basename', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'extname');
  retval.SetValueByKey('extname',
   TCefv8ValueRef.NewFunction('extname', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'join');
  retval.SetValueByKey('join',
   TCefv8ValueRef.NewFunction('join', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'resolve');
  retval.SetValueByKey('resolve',
   TCefv8ValueRef.NewFunction('resolve', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'relative');
  retval.SetValueByKey('relative',
   TCefv8ValueRef.NewFunction('relative', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'isAbsolute');
  retval.SetValueByKey('isAbsolute',
   TCefv8ValueRef.NewFunction('isAbsolute', handler), V8_PROPERTY_ATTRIBUTE_NONE);

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

  //
  function dirname: string;
  var
    drive: string;
  begin
    Result:= UTF8Encode(arguments[0].GetStringValue);
    if (Result <> DirectorySeparator) and (Result <> '/') and (Result <> '\') then begin
      drive:= ExtractFileDrive(Result);
      Result:= ExtractFileDir(ExcludeTrailingPathDelimiter(Result));
      if Result <> '' then begin
        if Result = drive then Result:= IncludeTrailingPathDelimiter(Result);
      end else begin
        Result:= '.';
      end;
    end;
  end;

  //
  function basename: string;
  var
    s: string;
    p: integer;
  begin
    Result:= UTF8Encode(arguments[0].GetStringValue);
    if (Result <> DirectorySeparator) and (Result <> '/') and (Result <> '\') then begin
      Result:= ExtractFileName(ExcludeTrailingPathDelimiter(Result));
      if Length(arguments) > 1 then begin
        s:= UTF8Encode(arguments[1].GetStringValue);
        if s <> '' then begin
          p:= Pos(s, Result);
          if (p > 1) and (p = Length(Result) - Length(s) + 1) then begin
            Result:= Copy(Result, 1, Length(Result) - Length(s));
          end;
        end;
      end;
    end;
  end;

  //
  function extname: string;
  begin
    Result:= UTF8Encode(arguments[0].GetStringValue);
    Result:= ExtractFileExt(Result);
  end;

  //
  function join: string;

    function sub(const base, s: string): string;
    begin
      if s = '' then begin
        Result:= base;
      end else if base = '' then begin
        Result:= s;
      end else begin
        Result:= IncludeTrailingPathDelimiter(base) + ExcludeLeadingPathDelimiter(s);
      end;
    end;

  var
    i, len: integer;
  begin
    Result:= UTF8Encode(arguments[0].GetStringValue);
    len:= Length(arguments);
    for i:= 1 to len-1 do begin
      Result:= sub(Result, UTF8Encode(arguments[i].GetStringValue));
    end;
  end;

  //
  function resolve: string;
  var
    base: string;
  begin
    base:= UTF8Encode(TCefv8ContextRef.Current.GetGlobal.GetValueByKey('__dogroot').GetStringValue);
    if Length(arguments) > 1 then begin
      base:= UTF8Encode(arguments[1].GetStringValue);
    end;
    Result:= UTF8Encode(arguments[0].GetStringValue);
    if Result <> '' then begin
      if Result[1] = '\' then begin
        Result:= '.' + Result;
      end;
      Result:= CreateAbsolutePath(Result, base);
    end;
  end;

  //
  function relative: string;
  var
    base: string;
  begin
    base:= UTF8Encode(arguments[0].GetStringValue);
    Result:= UTF8Encode(arguments[1].GetStringValue);
    if Result <> '' then begin
      //if Result[1] = '\' then begin
      //  Result:= '.' + Result;
      //end;
      Result:= CreateRelativePath(Result, base, True);
    end;
  end;

begin
  Result:= False;
  case handler.FuncName of
    'dirname': begin
      if Length(arguments) < 1 then Exit;
      retval:= TCefv8ValueRef.NewString(UTF8Decode(dirname));
    end;

    'basename': begin
      if Length(arguments) < 1 then Exit;
      retval:= TCefv8ValueRef.NewString(UTF8Decode(basename));
    end;

    'extname': begin
      if Length(arguments) < 1 then Exit;
      retval:= TCefv8ValueRef.NewString(UTF8Decode(extname));
    end;

    'join': begin
      if Length(arguments) < 1 then Exit;
      retval:= TCefv8ValueRef.NewString(UTF8Decode(join));
    end;

    'resolve': begin
      if Length(arguments) < 1 then Exit;
      retval:= TCefv8ValueRef.NewString(UTF8Decode(resolve));
    end;

    'relative': begin
      if Length(arguments) < 2 then Exit;
      retval:= TCefv8ValueRef.NewString(UTF8Decode(relative));
    end;

    'isAbsolute': begin
      if Length(arguments) < 1 then Exit;
      retval:= TCefv8ValueRef.NewBool(
        FilenameIsAbsolute(UTF8Encode(arguments[0].GetStringValue)));
    end;

    else
      Exit;
  end;
  Result:= True;
end;

//
const
  _import = G_VAR_IN_JS_NAME + '["' + MODULE_NAME + '"]';
  _body = _import + '.__init__();' +
     'export const dirname=' + _import + '.dirname;' +
     'export const basename=' + _import + '.basename;' +
     'export const extname=' + _import + '.extname;' +
     'export const join=' + _import + '.join;' +
     'export const resolve=' + _import + '.resolve;' +
     'export const relative=' + _import + '.relative;' +
     'export const isAbsolute=' + _import + '.isAbsolute;' +
     '';

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute); // DEPRECATED
  AddModuleHandler(MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread); // DEPRECATED
end.

