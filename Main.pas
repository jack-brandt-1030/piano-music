unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type
  TMusicThread = class(TThread)
    private
      FLH, FRH, FOff, FLHTotal, FRHTotal: TArray<TArray<Integer>>;
      FLHD, FRHD: TArray<Integer>;
      FStart: Integer;
      FMultiplier: Integer;
      FSong: Integer;
      FFileNames: TStringList;
      FSleepTime: Integer;

      procedure Play;
      function Read(Name: string): TArray<TArray<Integer>>;
      procedure Draw(a: Integer; Note: Integer; Color: Integer);
    protected
      constructor Create(Sus: Boolean);
      procedure Execute; override;
  end;

  TMainForm = class(TForm)
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  MMSystem, Math;

{Maybe this adds to the lag?}

function Contains(Arr: array of Integer; Val: Integer): Boolean;
var
  i: Integer;
begin
  for i in Arr do
    if i = Val then begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

{I should just make a note procedure}

function MIDIEncodeMessage(Msg, Param1, Param2: Integer): Integer;
begin
  Result := Msg + (Param1 shl 8) + (Param2 shl 16);
end;

procedure NotesToDurations(Notes: TArray<TArray<Integer>>; var Durations: TArray<Integer>);
var
  i, j: Integer;
begin

  {Improve this}

  SetLength(Durations, Length(Notes));
  for i := 0 to Length(Notes) - 1 do
    if Length(Notes[i]) > 0 then begin
      j := i + 1;
      while j < Length(Notes) do
        if Length(Notes[j]) = 0 then
          Inc(j)
        else
         Break;
      Durations[i] := j - i;
    end;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
    TMusicThread.Create(False);
end;

function TMusicThread.Read(Name: string): TArray<TArray<Integer>>;
var
  Arr: TArray<TArray<Integer>>;
  f: TextFile;
  s: string;
  i, j: Integer;
begin

  {Remove SetLength eventually, no longer Lazarus}

  AssignFile(f, Name);
  Reset(f);
  i := 0;
  Arr := [];
  while not Eof(f) do begin
    ReadLn(f, s);
    SetLength(Arr, Length(Arr) + FMultiplier);
    if (s <> '') and (s[1] = '*') then
      Arr[i] := [-1]
    else begin
      j := 1;
      while j < Length(s) do begin
        SetLength(Arr[i], Length(Arr[i]) + 1);
        Arr[i][High(Arr[i])] := StrToInt(s[j] + s[j + 1]);
        Inc(j, 2);
      end;
    end;
    Inc(i, FMultiplier)
  end;
  if s = '' then
    SetLength(Arr, Length(Arr) + FMultiplier);
  Result := Arr;
end;

constructor TMusicThread.Create(Sus: Boolean);
var
  i, j: Integer;
begin
  inherited;

  FSong := 2;

  FFileNames := TStringList.Create;

  if FSong = 0 then begin
    FFileNames.Add('..\..\music\comptine\LH.txt');
    FFileNames.Add('..\..\music\comptine\RH.txt');
    FStart := (705 - 1)*3;
    FMultiplier := 3;
    FSleepTime := 50;
  end else if FSong = 1 then begin
    FFileNames.Add('..\..\music\sviridov\LH.txt');
    FFileNames.Add('..\..\music\sviridov\RH.txt');
    FStart := 0;
    FMultiplier := 2;
    FSleepTime := 50;
  end else if FSong = 2 then begin
    FFileNames.Add('..\..\music\test\LH.txt');
    FFileNames.Add('..\..\music\test\RH.txt');
    FStart := 0;
    FMultiplier := 1;
    FSleepTime := 100;
  end;

  FLH := Read(FFileNames[0]);
  FRH := Read(FFileNames[1]);

  NotesToDurations(FLH, FLHD);
  NotesToDurations(FRH, FRHD);

  SetLength(FOff, Length(FLH) + 1);
  for i := 0 to Length(FLH) - 1 do begin
    if (Length(FLH[i]) > 0) and (FLH[i, 0] <> -1) then
      FOff[i + FLHD[i]] := Concat(FOff[i + FLHD[i]], FLH[i]);
    if (Length(FRH[i]) > 0) and (FRH[i, 0] <> -1) then
      FOff[i + FRHD[i]] := Concat(FOff[i + FRHD[i]], FRH[i]);
  end;

  SetLength(FLHTotal, Length(FLH) + 1);
  SetLength(FRHTotal, Length(FLH) + 1);
  for i := 0 to Length(FLH) - 1 do begin
    if (Length(FLH[i]) > 0) and (FLH[i, 0] <> -1) then
      for j := 0 to FLHD[i] - 1 do
        FLHTotal[i + j] := FLH[i];
    if (Length(FRH[i]) > 0) and (FRH[i, 0] <> -1) then
      for j := 0 to FRHD[i] - 1 do
        FRHTotal[i + j] := FRH[i];
  end;

  {This is clumsy but for now it works}

  FLHTotal[High(FLHTotal)] := nil;
  FRHTotal[High(FRHTotal)] := nil;

  FLH := FLH + [nil];
  FRH := FRH + [nil];

  FreeOnTerminate := True;
end;

procedure TMusicThread.Execute;
begin
  Play;
end;

procedure TMusicThread.Play;
const
  MIDI_NOTE_ON = $90;
  MIDI_NOTE_OFF = $80;
  MIDI_DEVICE = 0;
var
  MO: HMIDIOUT;
  i, n: Integer;
begin
  MidiOutOpen(@MO, MIDI_DEVICE, 0, 0, CALLBACK_NULL);

  for i := FStart to Length(FLHTotal) - 1 do begin
    for n in FLH[i] do
      if n > 0 then
        MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));
    for n in FRH[i] do
      if n > 0 then
        MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));

    {This lags, so try to fix}

    Queue(
      procedure
      var
        a, n: Integer;
      begin
        for a := 0 to Min(39, Length(FLHTotal) - 1 - i) do begin
          {Erase}
          if i > FStart then begin
            for n in FLHTotal[i + a - 1] do
              if not Contains(FLHTotal[i + a], n) then
                Draw(a, n, clBtnFace);
            for n in FRHTotal[i + a - 1] do
              if not Contains(FRHTotal[i + a], n) then
                Draw(a, n, clBtnFace);
          end;
          {Draw}
          for n in FLHTotal[i + a] do
            if (i = FStart) or not Contains(FLHTotal[i + a - 1], n) then
              Draw(a, n, $00AACCEE);
          for n in FRHTotal[i + a] do begin
            if (i = FStart) or not Contains(FRHTotal[i + a - 1], n) then
              Draw(a, n, $00EECCAA);
          end;
        end;
      end);

    Sleep(FSleepTime);

    for n in FOff[i + 1] do
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_OFF, n, 127));
  end;
end;

procedure TMusicThread.Draw(a: Integer; Note: Integer; Color: Integer);
begin
  MainForm.Canvas.Brush.Color := Color;
  MainForm.Canvas.FillRect(Rect(10*Note, 850-20*a, 10*Note+10, 830-20*a));
end;

end.
