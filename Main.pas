unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Generics.Collections, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  System.Actions, Vcl.ActnList;

type
  TState = (sMenu, sPlaying);

  TSong = (Comptine, Sviridov, Test, Ivan);

  TNoteArray = TArray<TArray<Integer>>;

  TMusicThread = class(TThread)
    private
      FNoteToColorDict: TDictionary<Integer, Integer>;
      FNoteToHeightDict: TDictionary<Integer, Integer>;

      FSong: TSong;
      FStart: Integer;
      FMultiplier: Integer;
      FSleepTime: Integer;

      {I will eventually condense these}

      FLH, FRH, FOff, FLH2, FRH2: TNoteArray;
      FLHD, FRHD, FLHD2, FRHD2: TArray<Integer>;

      FLHTotal, FRHTotal: TArray<TNoteArray>;

      procedure Read(Name: string; var Notes: TNoteArray; var Durations: TArray<Integer>);
      procedure Play;
    protected
      constructor Create(Sus: Boolean; Song: TSong);
      procedure Execute; override;
  end;

  TMainForm = class(TForm)
    Panel1: TPanel;
    Btn1: TSpeedButton;
    Panel2: TPanel;
    Btn2: TSpeedButton;
    Panel3: TPanel;
    Btn3: TSpeedButton;
    Panel4: TPanel;
    Btn4: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure BtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    private
      FState: TState;
      FPianoLeft: Integer;
      procedure DrawPiano;
      procedure Draw(a, Note, Color, Height: Integer); {Reorder these parameters}
      procedure Restart;
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
  LowestNote = 21;
  HighestNote = 108;

{I should make a note on procedure}

//------------------------------------------------------------------------------
function MIDIEncodeMessage(Msg, Param1, Param2: Integer): Integer;
begin
  Result := Msg + (Param1 shl 8) + (Param2 shl 16);
end;

//------------------------------------------------------------------------------
procedure TMainForm.FormCreate(Sender: TObject);
begin
  FState := sMenu;
end;

//------------------------------------------------------------------------------
procedure TMainForm.FormResize(Sender: TObject);
var
  n: Integer;
  Panels: TArray<TPanel>;
  Panel: TPanel;
begin
  n := (ClientWidth - 5*10) div 4;

  Panels := [Panel1, Panel2, Panel3, Panel4];
  for Panel in Panels do begin
    Panel.Width := n;
    Panel.Height := n;
    Panel.Top := ClientHeight div 2 - n div 2;
  end;

  Panel1.Left := 10;
  Panel2.Left := 10 + n + 10;
  Panel3.Left := 10 + n + 10 + n + 10;
  Panel4.Left := 10 + n + 10 + n + 10 + n + 10;
end;

//------------------------------------------------------------------------------
procedure TMainForm.DrawPiano;
var
  i: Integer;
begin
  FPianoLeft := ClientWidth div 2 - NoteSpacing*44;

  for i := LowestNote to HighestNote do begin
    Draw(-1, i, Ord(Colors[(i - 21) mod 12 + 1] = 'W')*clWhite+Ord(Colors[(i - 21) mod 12 + 1] = 'B')*clBlack, 1);
    Draw(-2, i, clWhite, 1);
  end;
end;

//------------------------------------------------------------------------------
procedure TMainForm.BtnClick(Sender: TObject);
begin
  Panel1.Visible := False;
  Panel2.Visible := False;
  Panel3.Visible := False;
  Panel4.Visible := False;
  DrawPiano;
  FState := sPlaying;
  TMusicThread.Create(False, TSong((Sender as TSpeedButton).Tag));
end;

//------------------------------------------------------------------------------
procedure TMainForm.Draw(a, Note, Color, Height: Integer);
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect(FPianoLeft + NoteSpacing*(Note - 21),
                       Floor - UnitHeight*a,
                       FPianoLeft + NoteSpacing*(Note - 21) + NoteWidth,
                       Floor - UnitHeight - UnitHeight*a - UnitHeight*(Height - 1)));
end;

//------------------------------------------------------------------------------
procedure TMusicThread.Read(Name: string; var Notes: TNoteArray; var Durations: TArray<Integer>);
var
  Stream: TResourceStream;
  sl: TStringList;
  s: string;
  Duration, LastNote, i, j: Integer;
begin

  {Read the file}

  Stream := TResourceStream.Create(HInstance, Name, RT_RCDATA);
  sl := TStringList.Create;
  sl.LoadFromStream(Stream);

  SetLength(Notes, sl.Count*FMultiplier);

  i := 0;
  for s in sl do begin
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
    SetLength(Notes, Length(Notes) + 1);

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

//------------------------------------------------------------------------------
constructor TMusicThread.Create(Sus: Boolean; Song: TSong);
var
  i, j: Integer;

  Notes: TNoteArray;
begin
  inherited Create(Sus);

  {Improve this}

  FNoteToColorDict := TDictionary<Integer, Integer>.Create;
  FNoteToHeightDict := TDictionary<Integer, Integer>.Create;
  for i := 21 to 108 do begin
    FNoteToColorDict.Add(i, Ord(Colors[(i - 21) mod 12 + 1] = 'W')*clWhite+Ord(Colors[(i - 21) mod 12 + 1] = 'B')*clBlack);
    FNoteToHeightDict.Add(i, Ord(Colors[(i - 21) mod 12 + 1] = 'W')*2 + Ord(Colors[(i - 21) mod 12 + 1] = 'B')*1);
  end;

  {Improve this}

  FSong := Song;

  if FSong = Comptine then begin
    FStart := 0;
    FMultiplier := 4;
    FSleepTime := 35;
    Read('comptine_LH', FLH, FLHD);
    Read('comptine_RH', FRH, FRHD);
  end else if FSong = Sviridov then begin
    FStart := (129 - 1)*2;
    FMultiplier := 2;
    FSleepTime := 50;
    Read('sviridov_LH', FLH, FLHD);
    Read('sviridov_RH', FRH, FRHD);
    Read('sviridov_RH2', FRH2, FRHD2);
  end else if FSong = Test then begin
    FStart := 0;
    FMultiplier := 1;
    FSleepTime := 100;
    Read('test_LH', FLH, FLHD);
    Read('test_RH', FRH, FRHD);
  end else if FSong = Ivan then begin
    FStart := 0;
    FMultiplier := 5;
    FSleepTime := 25;
    Read('ivan_LH', FLH, FLHD);
    Read('ivan_LH2', FLH2, FLHD2);
    Read('ivan_RH', FRH, FRHD);
  end;

  {Clumsy but it works}

  SetLength(FLHTotal, Ord(Length(FLH) > 0) + Ord(Length(FLH2) > 0));
  FLHTotal[0] := FLH;
  if Length(FLH2) > 0 then
    FLHTotal[1] := FLH2;
  SetLength(FRHTotal, Ord(Length(FRH) > 0) + Ord(Length(FRH2) > 0));
  FRHTotal[0] := FRH;
  if Length(FRH2) > 0 then
    FRHTotal[1] := FRH2;

  {Also clumsy but it works}

  {Something is wrong here}
  {FRH[i] ?}
  {FLH and FRH have different lengths AH}

  SetLength(FOff, Length(FLH) + 1);
  for i := 0 to Length(FLH) - 1 do begin
    if (Length(FLH) > 0) and (Length(FLH[i]) > 0) and (FLH[i, 0] <> -1) then
      FOff[i + FLHD[i]] := Concat(FOff[i + FLHD[i]], FLH[i]);
    if (Length(FLH2) > 0) and (Length(FLH2[i]) > 0) and (FLH2[i, 0] <> -1) then
      FOff[i + FLHD2[i]] := Concat(FOff[i + FLHD2[i]], FLH2[i]);
    if (Length(FRH) > 0) and (Length(FRH[i]) > 0) and (FRH[i, 0] <> -1) then
      FOff[i + FRHD[i]] := Concat(FOff[i + FRHD[i]], FRH[i]);
    if (Length(FRH2) > 0) and (Length(FRH2[i]) > 0) and (FRH2[i, 0] <> -1) then
      FOff[i + FRHD2[i]] := Concat(FOff[i + FRHD2[i]], FRH2[i]);
  end;

  FreeOnTerminate := True;
end;

//------------------------------------------------------------------------------
procedure TMusicThread.Execute;
begin
  Play;
end;

//------------------------------------------------------------------------------
procedure TMusicThread.Play;
const
  MIDI_NOTE_ON = $90;
  MIDI_NOTE_OFF = $80;
  MIDI_DEVICE = 0;
var
  MO: HMIDIOUT;
  i, n: Integer;

  Notes: TNoteArray;
begin
  MidiOutOpen(@MO, MIDI_DEVICE, 0, 0, CALLBACK_NULL);

  for i := FStart to Length(FLH) - 1 do begin
    for Notes in FLHTotal do
      for n in Notes[i] do
        MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));
    for Notes in FRHTotal do
      for n in Notes[i] do
        MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_ON, n, 127));

    Queue(
      procedure
      var
        a, n: Integer;

        Notes: TNoteArray;
      begin

        {Erase piano keys}
        for n in FOff[i] do
          MainForm.Draw(-FNoteToHeightDict[n], n, FNoteToColorDict[n], FNoteToHeightDict[n]);

        {Piano keys}
        for Notes in FLHTotal do
          for n in Notes[i] do
            MainForm.Draw(-FNoteToHeightDict[n], n, $00EECCAA, FNoteToHeightDict[n]);
        for Notes in FRHTotal do
          for n in Notes[i] do
            MainForm.Draw(-FNoteToHeightDict[n], n, $00AACCEE, FNoteToHeightDict[n]);

        for a := 0 to Min(39, Length(FLH) - 1 - i) do begin
          {Erase}
          for n in FOff[i + a] do
            MainForm.Draw(a, n, clBtnFace, 1);
          {Draw}
          for Notes in FLHTotal do
            for n in Notes[i + a] do
              MainForm.Draw(a, n, $00EECCAA, 1);
          for Notes in FRHTotal do
            for n in Notes[i + a] do
              MainForm.Draw(a, n, $00AACCEE, 1);
        end;
      end);

    Sleep(FSleepTime);

    for n in FOff[i + 1] do
      MidiOutShortMsg(MO, MIDIEncodeMessage(MIDI_NOTE_OFF, n, 127));
  end;

  MidiOutClose(MO);

  MainForm.Restart;
end;

//------------------------------------------------------------------------------
procedure TMainForm.Restart;
begin
  Panel1.Visible := True;
  Panel2.Visible := True;
  Panel3.Visible := True;
  Panel4.Visible := True;
  Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  FState := sMenu;
end;

end.
