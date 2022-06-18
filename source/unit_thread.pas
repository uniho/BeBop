unit unit_thread;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uCEFInterfaces;

type

  { TPromiseThread }

  TPromiseThread = class(TThread)
  private
  protected
    CefResolve, CefReject: ICefValue;
    procedure Execute; override;
    procedure ExecuteAct; virtual; abstract;
    procedure TerminateEvent(Sender: TObject);
  public
    UID: string;
    Frame: ICefFrame;
    Args: ICefListValue;
    CefObject, CefLocal: ICefValue;
    constructor Create(); overload;
    destructor Destroy; override;
  end;

  TPromiseThreadClass = class of TPromiseThread;

function StartPromiseThread(thread: TPromiseThreadClass; Args: TCefv8ValueArray;
  resolve, reject: ICefv8Value; const moduleName, funcName: string; obj: ICefv8Value = nil; local: ICefv8Value = nil): string;
procedure RemovePromiseThread(const guid: string);
procedure AddPromiseThreadClass(const moduleName: string; baseClass: TPromiseThreadClass);

implementation

uses
  unit_global, unit_js,
  uCEFTypes, uCEFProcessMessage, uCEFv8Value, uCEFConstants, uCEFv8Context,
  uCEFValue, uCefv8ArrayBufferReleaseCallback;

//
procedure FreeMemProcPromiseThread(buffer: Pointer);
var
  s: string;
begin
  s:= StrPas(buffer);
  RemovePromiseThread(s);
  FreeMem(buffer);
end;

function StartPromiseThread(thread: TPromiseThreadClass; Args: TCefv8ValueArray;
  resolve, reject: ICefv8Value; const moduleName, funcName: string; obj: ICefv8Value; local: ICefv8Value): string;
var
  v1, v2, g: ICefv8Value;
  msg: ICefProcessMessage;
  len: integer;
  p: PChar;
begin
  v1:= TCefv8ValueRef.NewObject(nil, nil);
  v1.SetValueByKey('resolve', resolve, V8_PROPERTY_ATTRIBUTE_NONE);
  v1.SetValueByKey('reject', reject, V8_PROPERTY_ATTRIBUTE_NONE);
  v1.SetValueByKey('moduleName', TCefv8ValueRef.NewString(UTF8Decode(moduleName)), V8_PROPERTY_ATTRIBUTE_NONE);
  v1.SetValueByKey('funcName', TCefv8ValueRef.NewString(UTF8Decode(funcName)), V8_PROPERTY_ATTRIBUTE_NONE);

  Result:= NewUID;
  len:= Length(Result) + 1;
  p:= GetMem(len);
  Move(PChar(Result)^, p^, len);
  v1.SetValueByKey(VTYPE_OBJECT_FIELD, TCefv8ValueRef.NewArrayBuffer(
    p, len, TCefFastv8ArrayBufferReleaseCallback.Create(@FreeMemProcPromiseThread)), V8_PROPERTY_ATTRIBUTE_NONE);

  g:= TCefv8ContextRef.Current.GetGlobal;
  v2:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc');
  v2.SetValueByKey(UTF8Decode(Result), v1, V8_PROPERTY_ATTRIBUTE_NONE);

  msg:= TCefProcessMessageRef.New('promise_thread_start');
  msg.ArgumentList.SetSize(5);
  msg.ArgumentList.SetString(0, UTF8Decode(Result));
  msg.ArgumentList.SetString(1, UTF8Decode(moduleName + '.' + thread.ClassName));
  msg.ArgumentList.SetList(2, Cefv8ArrayToCefList(Args));
  if g.IsSame(obj) then begin
    msg.ArgumentList.SetNull(3);
  end else begin
    msg.ArgumentList.SetValue(3, Cefv8ValueToCefValue(obj));
  end;
  msg.ArgumentList.SetValue(4, Cefv8ValueToCefValue(local));

  TCefv8ContextRef.Current.Browser.MainFrame.SendProcessMessage(PID_BROWSER, msg);
end;

//
procedure RemovePromiseThread(const guid: string);
var
  i: integer;
  thread: TPromiseThread;
begin
  i:= ThreadList.IndexOf(guid);
  if i < 0 then exit;
  thread:= TPromiseThread(ThreadList.Objects[i]);
  if Assigned(thread) then thread.Free;
  ThreadList.Delete(i);
end;

procedure AddPromiseThreadClass(const moduleName: string; baseClass: TPromiseThreadClass);
begin
  ThreadClassList.AddObject(moduleName + '.' + baseClass.ClassName, TObject(baseClass));
end;

{ TPromiseThread }

constructor TPromiseThread.Create();
begin
  FreeOnTerminate:= False;
  OnTerminate:= @TerminateEvent;
  inherited Create(True); // CreateSuspended=True
end;

destructor TPromiseThread.Destroy;
begin
  inherited Destroy;
end;

procedure TPromiseThread.Execute;
begin
  try
    ExecuteAct;
  except
    on e: Exception do begin
      CefReject:= TCefValueRef.New;
      CefReject.SetString(UTF8Decode(e.message));
    end;
  end;
end;

procedure TPromiseThread.TerminateEvent(Sender: TObject);
var
  msg: ICefProcessMessage;
begin
  if Terminated then exit;

  msg:= TCefProcessMessageRef.New('promise');
  msg.ArgumentList.SetSize(3);
  msg.ArgumentList.SetString(0, UTF8Decode(UID));
  if Assigned(CefResolve) then begin
    msg.ArgumentList.SetInt(1, 1); // resolve
    msg.ArgumentList.SetValue(2, CefResolve);
  end else if Assigned(CefReject) then begin
    msg.ArgumentList.SetInt(1, -1); // reject
    if Assigned(CefReject) then begin
      msg.ArgumentList.SetValue(2, CefReject);
    end else begin
      msg.ArgumentList.SetNull(2);
    end;
  end else begin
    msg.ArgumentList.SetInt(1, 0);
  end;

  Frame.SendProcessMessage(PID_RENDERER, msg);
end;

end.

