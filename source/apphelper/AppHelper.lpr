program AppHelper;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  uCEFApplication,
  unit_js;

begin
  GlobalCEFApp:= TCefApplication.Create;

  GlobalCEFApp.OnWebKitInitialized := @WebKitInitializedEvent;
  GlobalCEFApp.OnContextCreated:= @ContextCreatedEvent;
  GlobalCEFApp.OnContextReleased:= @ContextReleasedEvent;
  GlobalCEFApp.OnProcessMessageReceived:= @ProcessMessageReceivedEvent;

  // The main process and the subprocess *MUST* have the same GlobalCEFApp
  // properties and events, specially FrameworkDirPath, ResourcesDirPath,
  // LocalesDirPath, cache and UserDataPath paths.
  {$IFDEF DARWIN}
  GlobalCEFApp.InitLibLocationFromArgs;
  {$ENDIF}

  GlobalCEFApp.StartSubProcess;
  GlobalCEFApp.Free;
  GlobalCEFApp:= nil;
end.

