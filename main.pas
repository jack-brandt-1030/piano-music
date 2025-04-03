unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, MMSystem;

type
  TFooThread = class(TThread)
    private
      FNote: Integer;
      procedure Execute; override;
    public
      constructor Create(Note: Integer);
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
      procedure Note(a: Integer);
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

procedure TMainForm.Note(a: Integer);
begin
  NoteOn(a, 127);
  Sleep(FLength);
  NoteOff(a, 127);
end;

procedure TMainForm.Music;
var
  LHLines, RHLines, AllLines: TStringList;
  Line: string;
  i: Integer;
begin
  LHLines := TStringList.Create;
  LHLines.LoadFromFile('LH.txt');

  RHLines := TStringList.Create;
  RHLines.LoadFromFile('RH.txt');

  AllLines := TStringList.Create;
  for i := 0 to LHLines.Count - 1 do
    AllLines.Add(LHLines[i] + RHLines[i]);

  {449 is the halfway point}

  FLength := 150;
  for i := 0 to AllLines.Count - 1 do begin
    Line := AllLines[i];
    if Length(Line) > 1 then
      TFooThread.Create(StrToInt(Line[1] + Line[2]));
    if Length(Line) > 3 then
      TFooThread.Create(StrToInt(Line[3] + Line[4]));
    if Length(Line) > 5 then
      TFooThread.Create(StrToInt(Line[5] + Line[6]));
    if Length(Line) > 7 then
      TFooThread.Create(StrToInt(Line[7] + Line[8]));
    Sleep(FLength);
  end;

  LHLines.Free();
  RHLines.Free();
  AllLines.Free();
end;

constructor TFooThread.Create(Note: Integer);
begin
  inherited Create(False);
  FNote := Note;
  FreeOnTerminate := True;
end;

procedure TFooThread.Execute;
begin
  MainForm.Note(FNote);
end;

end.
