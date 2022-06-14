unit unit_mod_util;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation

uses
  {$IFDEF Windows}Windows,{$ENDIF}
  Variants, unit_js, unit_thread,
  uCEFTypes, uCEFInterfaces, unit_global, LazFileUtils,
  uCEFConstants, uCEFv8Value, uCEFv8Context, uCEFv8ArrayBufferReleaseCallback,
  uCEFValue;

const
  MODULE_NAME = 'util'; //////////

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

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'UTF8Decode');
  Result.SetValueByKey('UTF8Decode',
   TCefv8ValueRef.NewFunction('UTF8Decode', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'UTF8Encode');
  Result.SetValueByKey('UTF8Encode',
   TCefv8ValueRef.NewFunction('UTF8Encode', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'SetCodePage');
  Result.SetValueByKey('SetCodePage',
   TCefv8ValueRef.NewFunction('SetCodePage', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'GetSystemDefaultLCID');
  Result.SetValueByKey('GetSystemDefaultLCID',
   TCefv8ValueRef.NewFunction('GetSystemDefaultLCID', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'CreateUUID');
  Result.SetValueByKey('CreateUUID',
   TCefv8ValueRef.NewFunction('CreateUUID', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'formatPas');
  Result.SetValueByKey('formatPas',
   TCefv8ValueRef.NewFunction('formatPas', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  // It's just a sample.
  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'unescapeHtmlSync');
  Result.SetValueByKey('unescapeHtmlSync',
   TCefv8ValueRef.NewFunction('unescapeHtmlSync', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  // It's just a sample.
  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'unescapeHtml');
  Result.SetValueByKey('unescapeHtml',
   TCefv8ValueRef.NewFunction('unescapeHtml', handler), V8_PROPERTY_ATTRIBUTE_NONE);
end;

//
function requireCreate(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  handler: ICefv8Handler;
begin
  retval:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'UTF8Decode');
  retval.SetValueByKey('UTF8Decode',
   TCefv8ValueRef.NewFunction('UTF8Decode', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'UTF8Encode');
  retval.SetValueByKey('UTF8Encode',
   TCefv8ValueRef.NewFunction('UTF8Encode', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'SetCodePage');
  retval.SetValueByKey('SetCodePage',
   TCefv8ValueRef.NewFunction('SetCodePage', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'GetSystemDefaultLCID');
  retval.SetValueByKey('GetSystemDefaultLCID',
   TCefv8ValueRef.NewFunction('GetSystemDefaultLCID', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'CreateUUID');
  retval.SetValueByKey('CreateUUID',
   TCefv8ValueRef.NewFunction('CreateUUID', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'formatPas');
  retval.SetValueByKey('formatPas',
   TCefv8ValueRef.NewFunction('formatPas', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  // It's just a sample.
  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'unescapeHtmlSync');
  retval.SetValueByKey('unescapeHtmlSync',
   TCefv8ValueRef.NewFunction('unescapeHtmlSync', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  // It's just a sample.
  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'unescapeHtml');
  retval.SetValueByKey('unescapeHtml',
   TCefv8ValueRef.NewFunction('unescapeHtml', handler), V8_PROPERTY_ATTRIBUTE_NONE);

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

  retval:= TCefv8ValueRef.NewNull;

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

  { TUnescapeHtmlThread }

  TUnescapeHtmlThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;

  //
  function formatPas(): string;
  var
    varr: array of variant;

    function List2Param(index: integer; v: ICefv8Value): integer;
    var
      i, l: integer;
    begin
      SetLength(varr, index+1);
      if v.IsInt then begin
        varr[index]:= v{%H-}.GetIntValue;
        Result:= index + 1;
      end else if v.IsDouble then begin
        varr[index]:= v{%H-}.GetDoubleValue;
        Result:= index + 1;
      end else if v.IsArray then begin
        l:= v.GetArrayLength;
        for i:= 0 to l-1 do begin
          index:= List2Param(index, v.GetValueByIndex(i))
        end;
        Result:= index;
      end else begin
        varr[index]:= {%H-}UTF8Encode(v.GetStringValue);
        Result:= index + 1;
      end;
    end;

  var
    s: string;
    i, p: integer;
    param: array of TVarRec;
    earr: array of extended;
    settings: TFormatSettings;
  begin
    if Length(arguments) < 2 then Exit;
    s:= UTF8Encode(arguments[0].GetStringValue);
    i:= 1; p:= 0;
    while i < Length(arguments) do begin
      p:= List2Param(p, arguments[i]);
      inc(i);
    end;
    SetLength(param{%H-}, Length(varr));
    SetLength(earr{%H-}, Length(varr));
    for i:= 0 to Length(varr)-1 do begin
      case VarType(varr[i]) of
        varInteger: begin
          param[i].VType:= vtInteger;
          param[i].VInteger:= varr{%H-}[i];
        end;
        varDouble: begin
          earr[i]:= varr{%H-}[i];
          param[i].VType:= vtExtended;
          param[i].VExtended:= @earr[i];
        end;
        varString: begin
          param[i].VType:= vtAnsiString;
          param[i].VString:= TVarData(varr[i]).vstring;
        end;
      end;
    end;
    settings:= DefaultFormatSettings;
    Result:= Format(s, param, settings);
  end;

//
var
  v1, v2: ICefv8Value;
  s: string;
  i, len: integer;
  p: Pointer;
begin
  Result:= False;
  try
    case handler.FuncName of
      'UTF8Decode': begin
        // <string> = utf8<ArrayBuffer> => {...}
        if Length(arguments) < 1 then Exit;
        if not arguments[0].IsArrayBuffer then Exit;
        // dataView = new DataView(arguments[0])
        retval:= NewV8Object(TCefv8ContextRef.Current.GetGlobal.GetValueByKey('DataView'), [arguments[0]]);
        // len = dataView.byteLength
        len:= retval.GetValueByKey('byteLength').GetIntValue;
        // for (let i=0;i<len;i++) s[i] = dataView.getUint8(i)
        SetLength(s{%H-}, len);
        v1:= retval.GetValueByKey('getUint8');
        for i:= 0 to len-1 do begin
          v2:= TCefv8ValueRef.NewInt(i);
          s[i+1]:= Chr(v1.ExecuteFunction(retval, [v2]).GetIntValue);
        end;
        retval:= TCefv8ValueRef.NewString(UTF8Decode(s));
      end;

      'UTF8Encode': begin
        // utf8<ArrayBuffer> = utf16<string> => {...}
        if Length(arguments) < 1 then Exit;
        s:= UTF8Encode(arguments[0].GetStringValue);
        len:= Length(s);
        p:= GetMem(len);
        Move(s[1], p^, len);
        retval:= TCefv8ValueRef.NewArrayBuffer(p, len,
          TCefFastv8ArrayBufferReleaseCallback.Create(@FreeMemProc));
      end;

      'SetCodePage': begin
        if Length(arguments) < 2 then Exit;
        if arguments[0].IsArrayBuffer then begin
          // utf16<string> = (ansi<ArrayBuffer>, cp) => {...}
          // dataView = new DataView(arguments[0])
          retval:= newV8Object(TCefv8ContextRef.Current.GetGlobal.GetValueByKey('DataView'), [arguments[0]]);
          // l = dataView.byteLength
          len:= retval.GetValueByKey('byteLength').GetIntValue;
          // for (let i=0;i<l;i++) s[i] = dataView.getUint8(i)
          SetLength(s{%H-}, len);
          v1:= retval.GetValueByKey('getUint8');
          for i:= 0 to len-1 do begin
            v2:= TCefv8ValueRef.NewInt(i);
            s[i+1]:= Chr(v1.ExecuteFunction(retval, [v2]).GetIntValue);
          end;

          SetCodePage(RawByteString(s), arguments[1].GetIntValue, false);
          SetCodePage(RawByteString(s), 65001{utf-8}, true);
          retval:= TCefv8ValueRef.NewString(UTF8Decode(s));
        end else begin
          // ansi<ArrayBuffer> = utf16<string> => {...}
          s:= UTF8Encode(arguments[0].GetStringValue);
          SetCodePage(RawByteString(s), arguments[1].GetIntValue, true);
          len:= Length(s);
          p:= GetMem(len);
          Move(s[1], p^, len);
          retval:= TCefv8ValueRef.NewArrayBuffer(p, len,
            TCefFastv8ArrayBufferReleaseCallback.Create(@FreeMemProc));
        end;
      end;

      'GetSystemDefaultLCID': begin
        // res<integer> = f()
        i:= 0;
        {$IFDEF Windows}
        i:= GetSystemDefaultLCID;
        {$ENDIF}
        retval:= TCefv8ValueRef.NewInt(i);
      end;

      'CreateUUID': begin
        // res<string> = f()
        s:= NewUID;
        s:= Copy(s, 2, Length(s)-2); // remove {}
        retval:= TCefv8ValueRef.NewString(UTF8Decode(s));
      end;

      'formatPas': begin
        // res<string> = (fmt<string>, arr<array>) => {...}
        if Length(arguments) < 2 then Exit;
        retval:= TCefv8ValueRef.NewString(UTF8Decode(formatPas));
      end;

      'unescapeHtmlSync': begin // Just a sample
        // res<string> = (html<string>) => {...}
        if Length(arguments) < 1 then Exit;

        // This is just a sample. It's bother, meaningless, and no value to process as native code.
        retval:= NewFunctionV8(
          'const escapeEl = window.document.createElement("textarea");' +
          'escapeEl.innerHTML = args[0];' +
          'return escapeEl.textContent;'
          , arguments);
      end;

      'unescapeHtml': begin // Just a sample, too.
        // res = (arg, ...) => new Promise((resolve, reject) => {...})
        retval:= NewV8Promise(name, TV8HandlerCallback.Create(handler.ModuleName, handler.FuncName, arguments, obj));
      end;

      else
        Exit;
    end;
  except
    on e: Exception do begin
      exception:= UTF8Decode(e.message);
    end;
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
    'unescapeHtml': begin
      // This is just a sample. It's bother, meaningless, and no value to process as native code.
      StartPromiseThread(TUnescapeHtmlThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    else
      Exit;
  end;
  Result:= True;
end;

{ TUnescapeHtmlThread }

// This is just a sample. It's bother, meaningless, and no value to process as native code, too.
procedure TUnescapeHtmlThread.ExecuteAct;
begin
  // see https://javascript.info/new-function
  NewFunctionRe(
    'const escapeEl = window.document.createElement("textarea");' +
    'escapeEl.innerHTML = args[0];' +
    'resolve(escapeEl.textContent);'
    , Args, UID);

  // NewFunctionRe() with UID resolves promise on its own, and thus nothing to do on terminate process.
  ResolveOnTerminate:= false;
end;

//
const
  _import = G_VAR_IN_JS_NAME + '["' + MODULE_NAME + '"]';
  _body = _import + '.__init__();' +
     'export const UTF8Decode=' + _import + '.UTF8Decode;' +
     'export const UTF8Encode=' + _import + '.UTF8Encode;' +
     'export const SetCodePage=' + _import + '.SetCodePage;' +
     'export const GetSystemDefaultLCID=' + _import + '.GetSystemDefaultLCID;' +
     'export const CreateUUID=' + _import + '.CreateUUID;' +
     'export const formatPas=' + _import + '.formatPas;' +
     'export const unescapeHtmlSync=' + _import + '.unescapeHtmlSync;' +
     'export const unescapeHtml=' + _import + '.unescapeHtml;' +
     '';

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute); // DEPRECATED
  AddModuleHandler(MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread); // DEPRECATED
  AddPromiseThreadClass(MODULE_NAME, TUnescapeHtmlThread); //
end.

