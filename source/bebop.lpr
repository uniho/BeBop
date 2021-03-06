program bebop;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  {$IFDEF Win32}
  Windows,
  {$ENDIF}
  uCEFLazarusCocoa, // required for Cocoa
  Interfaces, // this includes the LCL widgetset
  Forms, uCEFApplication, uCEFConstants, uCEFWorkScheduler,
  unit1, unit_js, unit_global, unit_thread, unit_rest;

{.$R *.res}

{$IFDEF Win32}
  // CEF3 needs to set the LARGEADDRESSAWARE flag which allows 32-bit processes to use up to 3GB of RAM.
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

begin
  {$IFDEF DARWIN}  // $IFDEF MACOSX
  AddCrDelegate;
  {$ENDIF}
  GlobalCEFApp:= TCefApplication.Create;
  try
    InitGlobalCEFApp;
    if GlobalCEFApp.StartMainProcess then begin
      RequireDerivedFormResource:=True;
      Application.Scaled:=True;
      {$IFNDEF LCLGTK2}
      Application.ShowMainForm:= False;
      {$ENDIF}
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
      Application.Run;
    end;
  finally
    if Assigned(GlobalCEFWorkScheduler) then GlobalCEFWorkScheduler.StopScheduler;
    DestroyGlobalCEFApp;
    DestroyGlobalCEFWorkScheduler;
  end;
end.

