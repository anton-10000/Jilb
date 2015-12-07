program Analyzer;

uses
  Forms,
  unMain_form in 'unMain_form.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
