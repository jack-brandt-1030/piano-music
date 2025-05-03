object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Music'
  ClientHeight = 461
  ClientWidth = 484
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  WindowState = wsMaximized
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object RadioGroup: TRadioGroup
    Left = 8
    Top = 8
    Width = 300
    Height = 200
    Caption = 'Please choose'
    Items.Strings = (
      'Comptine, by Yann Tiersen'
      'Romance, by Georgy Sviridov'
      'Test'
      'Ivan Sings, by Aram Khachaturian')
    TabOrder = 0
  end
end
