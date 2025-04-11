unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TMainForm = class(TForm)
    RandomButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure RandomButtonClick(Sender: TObject);
    private
      FLHNotes, FRHNotes, FOffList: TStringList;
      procedure DetermineLengths(const LHNotes, RHNotes: TStringList; out LHDurations, RHDurations: TStringList);
      procedure Info;
      procedure Play;
  end;
  TMusicThread = class(TThread)
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

procedure TMainForm.DetermineLengths(const LHNotes, RHNotes: TStringList; out LHDurations, RHDurations: TStringList);
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

procedure TMainForm.Info;
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

procedure TMainForm.Play;
var
  i, j, k: Integer;
begin
  MidiOutOpen(@MO, MIDI_DEVICE, 0, 0, CALLBACK_NULL);

  for i := 0 to FLHNotes.Count - 1 do begin
    j := 1;
    while j < Length(FOffList[i]) do begin
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_OFF, StrToInt(FOffList[i][j]+ FOffList[i][j+1]), 127));
      Inc(j, 2);
    end;

    k := 1;
    while k < Length(FLHNotes[i]) do begin
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, StrToInt(FLHNotes[i][k] + FLHNotes[i][k+1]), 127));
      Inc(k, 2);
    end;
    k := 1;
    while k < Length(FRHNotes[i]) do begin
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, StrToInt(FRHNotes[i][k] + FRHNotes[i][k+1]), 127));
      Inc(k, 2);
    end;

    Sleep(150);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Info;
end;

procedure TMainForm.RandomButtonClick(Sender: TObject);
begin
  TMusicThread.Create(False);
end;

procedure TMusicThread.Execute;
begin
  MainForm.Play;
end;

end.
