unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Generics.Collections;

type
  TSong = (Comptine, Sviridov, Test, Ivan);

  TMusicThread = class(TThread)
    private
      FLH, FRH, FOff: TArray<TArray<Integer>>;
      FLHD, FRHD: TArray<Integer>;

      FStart: Integer;
      FMultiplier: Integer;
      FSong: Integer;
      FFileNames: TStringList;
      FSleepTime: Integer;

      FNoteToColorDict: TDictionary<Integer, Integer>;
      FNoteToHeightDict: TDictionary<Integer, Integer>;

      procedure Read(Name: string; var Notes: TArray<TArray<Integer>>; var Durations: TArray<Integer>);
      procedure Play;
    protected
      constructor Create(Sus: Boolean);
      procedure Execute; override;
  end;

  TMainForm = class(TForm)
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    private
      FPianoLeft: Integer;
      procedure Draw(a, Note, Color, Height: Integer); {Reorder these parameters}
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  MMSystem, Math;

const
  Colors = 'WBWWBWBWWBWB';
  Floor = 850;
  NoteSpacing = 10;
  NoteWidth = 10;
  UnitHeight = 20;

{I should make a note procedure}

function MIDIEncodeMessage(Msg, Param1, Param2: Integer): Integer;
begin
  Result := Msg + (Param1 shl 8) + (Param2 shl 16);
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: Integer;
begin
  if Key = 13 then begin

    FPianoLeft := ClientWidth div 2 - NoteSpacing*44;

    for i := 21 to 108 do begin
      Draw(-1, i, Ord(Colors[(i - 21) mod 12 + 1] = 'W')*clWhite+Ord(Colors[(i - 21) mod 12 + 1] = 'B')*clBlack, 1);
      Draw(-2, i, clWhite, 1);
    end;

    TMusicThread.Create(False);
  end;
end;

procedure TMainForm.Draw(a, Note, Color, Height: Integer);
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect(FPianoLeft + NoteSpacing*(Note - 21),
                       Floor-UnitHeight*a,
                       FPianoLeft + NoteSpacing*(Note - 21) + NoteWidth,
                       Floor - UnitHeight - UnitHeight*a - UnitHeight*(Height - 1)));
end;

procedure TMusicThread.Read(Name: string; var Notes: TArray<TArray<Integer>>; var Durations: TArray<Integer>);
var
  f: TextFile;
  s: string;
  Duration, LastNote, i, j: Integer;
begin

  {Read the file}

  AssignFile(f, Name);
  Reset(f);i := 0;
  while not Eof(f) do begin
    ReadLn(f, s);
    SetLength(Notes, Length(Notes) + FMultiplier);
    if (s <> '') and (s[1] = '*') then
      Notes[i] := [-1]
    else begin
      LastNote := i;
      Duration := FMultiplier;
      j := 1;
      while j < Length(s) do begin
        Notes[i] := Notes[i] + [StrToInt(s[j] + s[j + 1])];
        Inc(j, 2);
      end;
    end;
    Inc(i, FMultiplier);
  end;
  if s = '' then
    SetLength(Notes, Length(Notes) + FMultiplier);

  {Determine lengths}

  SetLength(Durations, Length(Notes));
  LastNote := -1;
  for i := 0 to Length(Notes) - 1 do
    if Notes[i] <> nil then begin
      if LastNote <> -1 then
        Durations[LastNote] := Duration;
      if Notes[i, 0] <> -1 then begin
        LastNote := i;
        Duration := 1;
      end else
        LastNote := -1;
    end else if LastNote <> -1 then
      Inc(Duration);
  if LastNote <> -1 then
    Durations[LastNote] := Duration;

  {Remove rests}

  for i := 0 to Length(Notes) - 1 do begin
    if (Notes[i] <> nil) and (Notes[i, 0] = -1) then
      Notes[i] := nil;
  end;

  {Add a final blank entry}

  SetLength(Notes, Length(Notes) + 1);
  SetLength(Durations, Length(Durations) + 1);
end;

constructor TMusicThread.Create(Sus: Boolean);
var
  i, j: Integer;
begin
  inherited;

  {Improve this}

  FNoteToColorDict := TDictionary<Integer, Integer>.Create;
  FNoteToHeightDict := TDictionary<Integer, Integer>.Create;
  for i := 21 to 108 do begin
    FNoteToColorDict.Add(i, Ord(Colors[(i - 21) mod 12 + 1] = 'W')*clWhite+Ord(Colors[(i - 21) mod 12 + 1] = 'B')*clBlack);
    FNoteToHeightDict.Add(i, Ord(Colors[(i - 21) mod 12 + 1] = 'W')*2 + Ord(Colors[(i - 21) mod 12 + 1] = 'B')*1);
  end;

  {Improve this}

  FSong := 0;
  FFileNames := TStringList.Create;

  if FSong = 0 then begin
    FFileNames.Add('..\..\music\comptine\LH.txt');
    FFileNames.Add('..\..\music\comptine\RH.txt');
    FStart := 0;
    FMultiplier := 4;
    FSleepTime := 35;
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
  end else if FSong = 3 then begin
    FFileNames.Add('..\..\music\ivan\LH.txt');
    FFileNames.Add('..\..\music\ivan\RH.txt');
    FStart := 0;
    FMultiplier := 1;
    FSleepTime := 100;
  end;

  Read(FFileNames[0], FLH, FLHD);
  Read(FFileNames[1], FRH, FRHD);

  SetLength(FOff, Length(FLH) + 1);
  for i := 0 to Length(FLH) - 1 do begin
    if (Length(FLH[i]) > 0) and (FLH[i, 0] <> -1) then
      FOff[i + FLHD[i]] := Concat(FOff[i + FLHD[i]], FLH[i]);
    if (Length(FRH[i]) > 0) and (FRH[i, 0] <> -1) then
      FOff[i + FRHD[i]] := Concat(FOff[i + FRHD[i]], FRH[i]);
  end;

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

  for i := FStart to Length(FLH) - 1 do begin
    for n in FLH[i] do
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));
    for n in FRH[i] do
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));

    Queue(
      procedure
      var
        a, n: Integer;
      begin

        {Erase piano keys}
        for n in FOff[i] do
          MainForm.Draw(-FNoteToHeightDict[n], n, FNoteToColorDict[n], FNoteToHeightDict[n]);

        {Piano keys}
        for n in FLH[i] do
          MainForm.Draw(-FNoteToHeightDict[n], n, $00EECCAA, FNoteToHeightDict[n]);
        for n in FRH[i] do
          MainForm.Draw(-FNoteToHeightDict[n], n, $00AACCEE, FNoteToHeightDict[n]);

        for a := 0 to Min(39, Length(FLH) - 1 - i) do begin
          {Erase}
          for n in FOff[i + a] do
            MainForm.Draw(a, n, clBtnFace, 1);
          {Draw}
          for n in FLH[i + a] do
            MainForm.Draw(a, n, $00EECCAA, 1);
          for n in FRH[i + a] do begin
            MainForm.Draw(a, n, $00AACCEE, 1);
          end;
        end;
      end);

    Sleep(FSleepTime);

    for n in FOff[i + 1] do
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_OFF, n, 127));
  end;
end;

end.
