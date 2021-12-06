program bebop;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  {$IFDEF Windows}
  Windows,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uCEFApplication, uCEFConstants, unit1, unit_js,
  unit_mod_fs, unit_mod_project, unit_global, unit_mod_child_process,
  unit_thread, unit_mod_path, unit_mod_util, unit_mod_process, unit_rest;

{.$R *.res}

{$IFDEF Windows}
  // CEF3 needs to set the LARGEADDRESSAWARE flag which allows 32-bit processes to use up to 3GB of RAM.
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

begin
  GlobalCEFApp:= TCefApplication.Create;
  try
    InitGlobalCEFApp;
    if GlobalCEFApp.StartMainProcess then begin
      RequireDerivedFormResource:=True;
  Application.Scaled:=True;
      Application.ShowMainForm:= False;
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
      Application.Run;
    end;
  finally
    DestroyGlobalCEFApp;
  end;
end.


