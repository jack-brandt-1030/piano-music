unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, MMSystem;

type
  TFooThread = class(TThread)
    procedure Execute; override;
    private
      FNote, FLength: Integer;
    public
      constructor Create(Note, Length: Integer);
  end;

  TMIDIInstrument = (midiAcousticGrandPiano, midiBrightAcousticPiano,
                     midiElectricGrandPiano, midiHonkyTonkPiano,
                     midiRhodesPiano, midiChorusedPiano, midiHarpsichord,
                     midiClavinet, midiCelesta, midiGlockenspiel,
                     midiMusicBox, midiVibraphone, midiMarimba, midiXylophone,
                     midiTubularBells, midiDulcimer, midiHammondOrgan,
                     midiPercussiveOrgan, midiRockOrgan, midiChurchOrgan,
                     midiReedOrgan, midiAccordion, midiHarmonica,
                     midiTangoAccordion, midiAcousticGuitarNylon,
                     midiAcousticGuitarSteel, midiElectricGuitarJazz,
                     midiElectricGuitarClean, midiElectricGuitarMuted,
                     midiOverdrivenGuitar, midiDistortionGuitar,
                     midiGuitarHarmonics, midiAcousticBass, midiElectricBassFinger,
                     midiElectricBassPick, midiFretlessBass, midiSlapBass1,
                     midiSlapBass2, midiSynthBass1, midiSynthBass2, midiViolin,
                     midiViola, midiCello, midiContrabass, midiTremoloStrings,
                     midiPizzicatoStrings, midiOrchestralHarp, midiTimpani,
                     midiStringEnsemble1, midiStringEnsemble2, midiSynthStrings1,
                     midiSynthStrings2, midiChoirAahs, midiVoiceOohs,
                     midiSynthVoice, midiOrchestraHit, midiTrumpet, midiTrombone,
                     midiTuba, midiMutedTrumpet, midiFrenchHorn, midiBrassSection,
                     midiSynthBrass1, midiSynthBrass2, midiSopranoSax, midiAltoSax,
                     midiTenorSax, midiBaritoneSax, midiOboe, midiEnglishHorn,
                     midiBassoon, midiClarinet, midiPiccolo, midiFlute,
                     midiRecorder, midiPanFlute, midiBottleBlow, midiShakuhachi,
                     midiWhistle, midiOcarina, midiLead1Square,
                     midiLead2Sawtooth, midiLead3CalliopeLead, midiLead4ChiffLead,
                     midiLead5Charang, midiLead6Voice, midiLead7Fifths,
                     midiLead8BrassLead, midiPad1NewAge, midiPad2Warm,
                     midiPad3Polysynth, midiPad4Choir, midiPad5Bowed,
                     midiPad6Metallic, midiPad7Halo, midiPad8Sweep, midiFX1Rain,
                     midiFX2Soundtrack, midiFX3Crystal, midiFX4Atmosphere, midiFX5Brightness, midiFX6Goblins,
                     midiFX7Echoes, midiFX8SciFi, midiSitar, midiBanjo, midiShamisen,
                     midiKoto, midiKalimba, midiBagpipe, midiFiddle,
                     midiShanai, midiTinkleBelll, midiAgogo, midiSteelDrums,
                     midiWoodblock, midiTaikoDrum, midiMelodicTom, midiSynthDrum,
                     midiReverseCymbal, midiGuitarFretNoise, midiBreathNoise,
                     midiSeashore, midiBirdTweet, midiTelephoneRing,
                     midiHelicopter, midiApplause, midiGunshot);

  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    private
      FLength: Integer;

      procedure MIDIInit;
      function MIDIEncodeMessage(Msg, Param1, Param2: Integer): Integer;
      procedure SetCurrentInstrument(CurrentInstrument: TMIDIInstrument);
      procedure NoteOn(NewNote, NewIntensity: Byte);
      procedure NoteOff(NewNote, NewIntensity: Byte);
      procedure SetPlaybackVolume(PlaybackVolume: Cardinal);
      procedure Music;
      procedure Note(a, b: Integer);
      procedure DetermineLengths(const LHLines, RHLines: TStringList; out LHMath, RHMath: TStringList);
  end;
var
  MainForm: TMainForm;

implementation

{$R *.lfm}

var
  mo: HMIDIOUT;

const
  MIDI_NOTE_ON = $90;
  MIDI_NOTE_OFF = $80;
  MIDI_CHANGE_INSTRUMENT = $C0;
  MIDI_DEVICE = 0;
  MIDI_VEL = 108;

procedure TMainForm.MIDIInit;
begin
  midiOutOpen(@mo, MIDI_DEVICE, 0, 0, CALLBACK_NULL);
  SetPlaybackVolume($FFFFFFFF);
end;

function TMainForm.MIDIEncodeMessage(Msg, Param1, Param2: Integer): Integer;
begin
  result := Msg + (Param1 shl 8) + (Param2 shl 16);
end;

procedure TMainForm.SetCurrentInstrument(CurrentInstrument: TMIDIInstrument);
begin
  midiOutShortMsg(mo, MIDIEncodeMessage(MIDI_CHANGE_INSTRUMENT, Ord(CurrentInstrument), 0));
end;

procedure TMainForm.NoteOn(NewNote, NewIntensity: Byte);
begin
  midiOutShortMsg(mo, MIDIEncodeMessage(MIDI_NOTE_ON, NewNote, NewIntensity));
end;

procedure TMainForm.NoteOff(NewNote, NewIntensity: Byte);
begin
  midiOutShortMsg(mo, MIDIEncodeMessage(MIDI_NOTE_OFF, NewNote, NewIntensity));
end;

procedure TMainForm.SetPlaybackVolume(PlaybackVolume: Cardinal);
begin
  midiOutSetVolume(mo, PlaybackVolume);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MIDIInit;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
    Music;
end;

procedure TMainForm.Note(a, b: Integer);
begin
  NoteOn(a, 127);
  Sleep(FLength*b);
  NoteOff(a, 127);
end;

procedure TMainForm.DetermineLengths(const LHLines, RHLines: TStringList; out LHMath, RHMath: TStringList);
var
  i, j: Integer;
begin
  LHMath := TStringList.Create;
  for i := 0 to LHLines.Count - 1 do begin
    if Length(LHLines[i]) < 2 then
      LHMath.Add('0')
    else if i = LHLines.Count - 1 then
      LHMath.Add('1')
    else begin
      j := i + 1;
      while j < LHLines.Count do
        if Length(LHLines[j]) = 0 then
          Inc(j)
        else
          Break;
      LHMath.Add(IntToStr(j - i));
    end;
  end;

  RHMath := TStringList.Create;
  for i := 0 to RHLines.Count - 1 do begin
    if Length(RHLines[i]) < 2 then
      RHMath.Add('0')
    else if i = RHLines.Count - 1 then
      RHMath.Add('1')
    else begin
      j := i + 1;
      while j < RHLines.Count do
        if Length(RHLines[j]) = 0 then
          Inc(j)
        else
          Break;
      RHMath.Add(IntToStr(j - i));
    end;
  end;
end;

procedure TMainForm.Music;
var
  LHLines, RHLines, LHMath, RHMath: TStringList;
  i: Integer;
  Notes: array of Integer;
  n: Integer;
begin
  LHLines := TStringList.Create;
  LHLines.LoadFromFile('LH.txt');

  RHLines := TStringList.Create;
  RHLines.LoadFromFile('RH.txt');

  {449 is the halfway point}

  DetermineLengths(LHLines, RHLines, LHMath, RHMath);

  FLength := 150;

  for i := 0 to LHLines.Count - 1 do begin

    Color := $00AAAAAA;
    Canvas.Clear;

    Notes := [];
    if Length(LHLines[i]) > 1 then begin
      n := StrToInt(LHLines[i][1] + LHLines[i][2]);
      SetLength(Notes, Length(Notes)+1);
      Notes[High(Notes)] := n;
      TFooThread.Create(n, StrToInt(LHMath[i]));
    end;
    if Length(LHLines[i]) > 3 then begin
      n := StrToInt(LHLines[i][3] + LHLines[i][4]);
      SetLength(Notes, Length(Notes)+1);
      Notes[High(Notes)] := n;
      TFooThread.Create(n, StrToInt(LHMath[i]));
    end;
    if Length(RHLines[i]) > 1 then begin
      n := StrToInt(RHLines[i][1] + RHLines[i][2]);
      SetLength(Notes, Length(Notes)+1);
      Notes[High(Notes)] := n;
      TFooThread.Create(n, StrToInt(RHMath[i]));
    end;
    if Length(RHLines[i]) > 3 then begin
      n := StrToInt(RHLines[i][3] + RHLines[i][4]);
      SetLength(Notes, Length(Notes)+1);
      Notes[High(Notes)] := n;
      TFooThread.Create(n, StrToInt(RHMath[i]));
    end;

    Color := $00FFAAAA;
    for n in Notes do
      Canvas.FillRect(5*n, 0, 5*n+10, 50);

    Sleep(FLength);
  end;

  LHLines.Free();
  RHLines.Free();
  LHMath.Free();
  RHMath.Free();
end;

constructor TFooThread.Create(Note, Length: Integer);
begin
  inherited Create(False);
  FNote := Note;
  FLength := Length;
  FreeOnTerminate := True;
end;

procedure TFooThread.Execute;
begin
  MainForm.Note(FNote, FLength);
end;

end.
