unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TMainForm = class(TForm)
    RandomButton: TButton;
    procedure RandomButtonClick(Sender: TObject);
  end;
  TMusicThread = class(TThread)
    private
      fn: Integer;
      lh, rh, off: array of Integer;
      FLHNotes, FRHNotes, FOffList: TStringList;
      procedure DetermineLengths(const LHNotes, RHNotes: TStringList; out LHDurations, RHDurations: TStringList);
      procedure Info;
      procedure Play;
      procedure Visualize;
    protected
      procedure Execute; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  MMSystem;

var
  MO: HMIDIOUT;

const
  MIDI_NOTE_ON = $90;
  MIDI_NOTE_OFF = $80;
  MIDI_DEVICE = 0;

function MIDIEncodeMessage(Msg, Param1, Param2: Integer): Integer;
begin
  Result := Msg + (Param1 shl 8) + (Param2 shl 16);
end;

procedure Save(Name: string; Info: TStringList; First: Integer = -1; Last: Integer = -1);
var
  F: TextFile;
  i: Integer;
begin
  if First = -1 then
    First := 0;
  if Last = -1 then
    Last := Info.Count - 1;

  AssignFile(F, Name);
  try
    ReWrite(F);
    for i := First to Last do
      if i = First then
        Write(F, '[''' + Info[i] + ''', ')
      else if i = Last then
        Write(F, '''' + Info[i] + '''] ')
      else
        Write(F, '''' + Info[i] + ''', ');
  finally
    CloseFile(F);
  end;
end;

procedure TMainForm.RandomButtonClick(Sender: TObject);
begin
  RandomButton.Visible := False;
  TMusicThread.Create(False);
end;

procedure TMusicThread.DetermineLengths(const LHNotes, RHNotes: TStringList; out LHDurations, RHDurations: TStringList);
var
  i, j: Integer;
begin
  LHDurations := TStringList.Create;
  for i := 0 to LHNotes.Count - 1 do begin
    if Length(LHNotes[i]) < 2 then
      LHDurations.Add('0')
    else if i = LHNotes.Count - 1 then
      LHDurations.Add('1')
    else begin
      j := i + 1;
      while j < LHNotes.Count do
        if Length(LHNotes[j]) = 0 then
          Inc(j)
        else
          Break;
      LHDurations.Add(IntToStr(j - i));
    end;
  end;

  RHDurations := TStringList.Create;
  for i := 0 to RHNotes.Count - 1 do begin
    if Length(RHNotes[i]) < 2 then
      RHDurations.Add('0')
    else if i = RHNotes.Count - 1 then
      RHDurations.Add('1')
    else begin
      j := i + 1;
      while j < RHNotes.Count do
        if Length(RHNotes[j]) = 0 then
          Inc(j)
        else
          Break;
      RHDurations.Add(IntToStr(j - i));
    end;
  end;
end;

procedure TMusicThread.Info;
var
  LHNotes, RHNotes, LHDurations, RHDurations, OffList: TStringList;
  i: Integer;
begin
  LHNotes := TStringList.Create;
  LHNotes.LoadFromFile('LH.txt');

  RHNotes := TStringList.Create;
  RHNotes.LoadFromFile('RH.txt');

  DetermineLengths(LHNotes, RHNotes, LHDurations, RHDurations);

  OffList := TStringList.Create;
  while OffList.Count <> LHNotes.Count + 1 do
    OffList.Add('');
  for i := 0 to LHNotes.Count - 1 - 1 do begin
    if Length(LHNotes[i]) > 1 then
      OffList[i+StrToInt(LHDurations[i])] := OffList[i+StrToInt(LHDurations[i])] + LHNotes[i];
    if Length(RHNotes[i]) > 1 then
      OffList[i+StrToInt(RHDurations[i])] := OffList[i+StrToInt(RHDurations[i])] + RHNotes[i];
  end;

  FLHNotes := LHNotes;
  FRHNotes := RHNotes;
  FOffList := OffList;
end;

procedure TMusicThread.Play;
var
  i, j, n: Integer;
  LHNotes, RHNotes, Offlist: array of Integer;
begin
  MidiOutOpen(@MO, MIDI_DEVICE, 0, 0, CALLBACK_NULL);

  for i := 0 to FLHNotes.Count - 1 do begin

    LHNotes := [];
    RHNotes := [];
    Offlist := [];

    j := 1;
    while j < Length(FOffList[i]) do begin
      n := StrToInt(FOffList[i][j]+ FOffList[i][j+1]);
      SetLength(Offlist, Length(Offlist)+1);
      Offlist[High(Offlist)] := n;
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_OFF, n, 127));
      Inc(j, 2);
    end;
    j := 1;
    while j < Length(FLHNotes[i]) do begin
      n := StrToInt(FLHNotes[i][j] + FLHNotes[i][j+1]);
      SetLength(LHNotes, Length(LHNotes)+1);
      LHNotes[High(LHNotes)] := n;
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));
      Inc(j, 2);
    end;
    j := 1;
    while j < Length(FRHNotes[i]) do begin
      n := StrToInt(FRHNotes[i][j] + FRHNotes[i][j+1]);
      SetLength(RHNotes, Length(RHNotes)+1);
      RHNotes[High(RHNotes)] := n;
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));
      Inc(j, 2);
    end;

    lh := LHNotes;
    rh := RHNotes;
    off := Offlist;
    Queue(@Visualize);

    Sleep(150);
  end;
end;

procedure TMusicThread.Execute;
begin
  Info;
  Play;
end;

procedure TMusicThread.Visualize;
begin
  for fn in off do begin
    MainForm.Canvas.Brush.Color := clDefault;
    MainForm.Canvas.FillRect(Rect(10*fn, 0, 10*fn+10, 50));
  end;
  for fn in lh do begin
    MainForm.Canvas.Brush.Color := $00AACCEE;
    MainForm.Canvas.FillRect(Rect(10*fn, 0, 10*fn+10, 50));
  end;
  for fn in rh do begin
    MainForm.Canvas.Brush.Color := $00EECCAA;
    MainForm.Canvas.FillRect(Rect(10*fn, 0, 10*fn+10, 50));
  end;
end;

end.
