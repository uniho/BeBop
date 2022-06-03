unit unit_mod_lua;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure llua_close;

implementation
uses
  LazFileUtils, unit_global, unit_js, unit_thread, lua54,
  uCEFTypes, uCEFInterfaces, uCEFConstants, uCEFv8Context, uCEFv8Value, uCEFValue,
  uCefDictionaryValue, uCefListValue;

const
  MODULE_NAME = 'lua'; //////////

var
  LuaState: Plua_State = nil;

function Alloc({%H-}ud, ptr: Pointer; {%H-}osize, nsize: size_t) : Pointer; cdecl;
begin
  try
    Result:= ptr;
    ReallocMem(Result, nSize);
  except
    Result:= nil;
  end;
end;

function print_func(L : Plua_State) : Integer; cdecl;
var
  i, c: integer;
  sl: TStringList;
  args: ICefListValue;
begin
  sl:= TStringList.Create;
  try
    c:= lua_gettop(L);
    for i:= 1 to c do sl.Add(lua_tostring(L, i));

    args:= TCefListValueRef.New;
    args.SetString(0, UTF8Decode(sl.Text));
    // see https://javascript.info/new-function
    NewFunction('console.log(args[0])', args);

    Result := 0;
  finally
    sl.Free;
  end;
end;

procedure llua_init;
begin
  if (not Assigned(LuaState)) then begin
    LuaState:= lua_newstate(@alloc, nil);
    if (not Assigned(LuaState)) then Raise Exception.Create('Cannot create Lua.');
    //luaL_requiref(LuaState, '', @luaopen_base, False);
    //lua_pop(LuaState, 1);
    //luaL_requiref(LuaState, LUA_COLIBNAME, @luaopen_coroutine, True);
    //lua_pop(LuaState, 1);
    //luaL_requiref(LuaState, LUA_TABLIBNAME, @luaopen_table, True);
    //lua_pop(LuaState, 1);
    //luaL_requiref(LuaState, LUA_STRLIBNAME, @luaopen_string, True);
    //lua_pop(LuaState, 1);
    //luaL_requiref(LuaState, LUA_MATHLIBNAME, @luaopen_math, True);
    //lua_pop(LuaState, 1);
    //luaL_requiref(LuaState, LUA_LOADLIBNAME, @luaopen_package, True);
    //lua_pop(LuaState, 1);
    luaL_openlibs(LuaState);
    lua_register(LuaState, 'print', @print_func);
  end
end;

procedure cefv2lua(val: ICefValue);
var
  i, l: integer;
  sl: TStringList;
begin
  case val.GetType of
    VTYPE_BOOL:
      lua_pushboolean(LuaState, val.GetBool);
    VTYPE_INT:
      lua_pushinteger(LuaState, val.GetInt);
    VTYPE_DOUBLE:
      lua_pushnumber(LuaState, val.GetDouble);
    VTYPE_STRING:
      lua_pushstring(LuaState, UTF8Encode(val.GetString));
    VTYPE_LIST: begin
      l:= val.GetList.GetSize;
      lua_newtable(LuaState);
      for i:= 0 to l-1 do begin
        lua_pushinteger(LuaState, i);
        cefv2lua(val.GetList.GetValue(i));
        lua_settable(LuaState, -3);
      end;
    end;
    VTYPE_DICTIONARY: begin
      sl:= TStringList.Create;
      try
        val.GetDictionary.GetKeys(sl);
        lua_newtable(LuaState);
        for i:= 0 to l-1 do begin
          lua_pushstring(LuaState, sl[i]);
          cefv2lua(val.GetDictionary.GetValue(UTF8Decode(sl[i])));
          if lua_type(LuaState, -1) = LUA_TNIL then begin
            lua_pop(LuaState, 1);
            lua_pushboolean(LuaState, False);
          end;
          lua_settable(LuaState, -3);
        end;
      finally
        sl.Free;
      end;
    end;
    else begin
      lua_pushnil(LuaState);
    end;
  end;
end;

function lua2cefv(const key: string = ''; const args: ICefListValue = nil): ICefValue;
var
  i, l, c: integer;
  s: string;
  obj: ICefDictionaryValue;
  list: ICefListValue;
begin
  Result:= TCefValueRef.New;
  case lua_type(LuaState, -1) of
    LUA_TNIL:
      Result.SetNull;
    LUA_TBOOLEAN:
      Result.SetBool(lua_toboolean(LuaState, -1));
    LUA_TNUMBER:
      if lua_isinteger(LuaState, -1) then begin
        Result.SetInt(lua_tointeger(LuaState, -1));
      end else
        Result.SetDouble(lua_tonumber(LuaState, -1));
    LUA_TSTRING:
      Result.SetString(lua_tostring(LuaState, -1));
    LUA_TFUNCTION: begin
      try
        try
          if (Assigned(args)) then begin
            l:= args.GetSize;
            for i:= 0 to l-1 do cefv2lua(args.GetValue(i));
          end;
          if lua_pcall(LuaState, l, 1, 0) <> 0 then Raise Exception.Create('');
          Result:= lua2cefv();
        except
          s:= lua_tostring(LuaState, -1);
          Raise Exception.Create(s);
        end;
      finally
        lua_settop(LuaState, 0);
      end;
    end;
    LUA_TTABLE: begin
      if key <> '' then begin
        lua_pushstring(LuaState, key);
        lua_rawget(LuaState, -2);
        Result:= lua2cefv('', args);
      end else begin
        l:= 0;
        c:= 0;
        obj:= TCefDictionaryValueRef.New;
        lua_pushnil(LuaState);  // first key
        while lua_next(LuaState, -2) <> 0 do begin
          // uses 'key' (at index -2) and 'value' (at index -1)
          s:= lua_tostring(LuaState, -2);
          if (lua_type(LuaState, -2) = LUA_TNUMBER) and
            (StrToIntDef(s, -1) = l) then Inc(c);
          obj.SetValue(UTF8Decode(s), lua2cefv());
          lua_pop(LuaState, 1); // removes 'value'; keeps 'key' for next iteration
          Inc(l);
        end;
        if l = c then begin
          list:= TCefListValueRef.New;
          for i:= 0 to l-1 do
            list.SetValue(i, obj.GetValue(UTF8Decode(IntToStr(i))));
          Result.SetList(list);
        end else
          Result.SetDictionary(obj);
      end;
    end;
  end;
end;

function llua_run(const filename, key: string; const args: ICefListValue): ICefValue;
var
  sl: TStringList;
  s: string;
begin
  Result:= nil;
  llua_init;
  sl:= TStringList.Create;
  try
    sl.LoadFromFile(filename);
    try
      try
        s:= sl.Text;
        if {%H-}luaL_loadbuffer(LuaState, PChar(s), Length(s), PChar(filename)) <> 0 then
          Raise Exception.Create('');
        if lua_pcall(LuaState, 0, 1, 0) <> 0 then
          Raise Exception.Create('');

        Result:= lua2cefv(key, args);
      except
        s:= lua_tostring(LuaState, -1);
        lua_settop(LuaState, 0);
        Raise Exception.Create(s);
      end;
    finally
      lua_settop(LuaState, 0);
    end;
  finally
    sl.Free;
  end;
end;

procedure llua_close;
begin
  if Assigned(LuaState) then begin
    lua_close(LuaState);
    LuaState:= nil;
  end;
end;

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
  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'run');
  Result:= TCefv8ValueRef.NewObject(nil, nil);
  Result.SetValueByKey('run',
   TCefv8ValueRef.NewFunction('run', handler), V8_PROPERTY_ATTRIBUTE_NONE);
end;

//
function requireCreate(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  handler: ICefv8Handler;
begin
  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'run');
  retval:= TCefv8ValueRef.NewObject(nil, nil);
  retval.SetValueByKey('run',
   TCefv8ValueRef.NewFunction('run', handler), V8_PROPERTY_ATTRIBUTE_NONE);

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


type

  { TV8HandlerCallback }

  TV8HandlerCallback = class(TV8HandlerSafe)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TRunThread }

  TRunThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result:= False;
  case handler.FuncName of
    'run': begin
      // result = (filename, options) => new Promise((resolve, reject) => {...})
      retval:= newV8Promise(name, TV8HandlerCallback.Create(handler.ModuleName, handler.FuncName, arguments, obj));
    end;

    else
      Exit;
  end;
  Result:= True;
end;

function TV8HandlerCallback.Execute(const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  // (resolve, reject) => {...}
  Result:= False;
  case FuncName of
    'run': begin
      StartPromiseThread(TRunThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    else
      Exit;
  end;
  Result:= True;
end;

procedure TRunThread.ExecuteAct;
var
  v1: ICefListValue;
  i, l: integer;
  filename, key: string;
begin
  l:= Args.GetSize;
  if l < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);

  filename:= UTF8Encode(Args.GetString(0));
  filename:= CreateAbsolutePath(filename, dogroot);

  key:= '';
  if l > 1 then begin
    key:= UTF8Encode(Args.GetString(1));
  end;

  v1:= nil;
  if l > 2 then begin
    v1:= TCefListValueRef.New;
    for i:= 2 to l-1 do v1.SetValue(i-2, Args.GetValue(i));
  end;

  CefResolve:= llua_run(filename, key, v1);
end;

//
const
  _import = G_VAR_IN_JS_NAME + '["~' + MODULE_NAME + '"]';
  _body = '' +
     'export const run=' + _import + '.run;' +
     ';';

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute);
  AddModuleHandler('~'+MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread);
  AddPromiseThreadClass(MODULE_NAME, TRunThread);

  AddPromiseThreadClass('~'+MODULE_NAME, TRunThread);
end.

