object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Music'
  ClientHeight = 348
  ClientWidth = 484
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -20
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  WindowState = wsMaximized
  StyleElements = [seFont, seClient]
  OnClick = BtnClick
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 28
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 468
    Height = 50
    BevelOuter = bvNone
    Color = clLightskyblue
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    ParentBackground = False
    TabOrder = 0
    object Btn1: TSpeedButton
      Left = 5
      Top = 5
      Width = 458
      Height = 40
      Align = alClient
      Caption = 'Comptine, by Yann Tiersen'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      OnClick = BtnClick
      OnMouseEnter = MouseEnter
      OnMouseLeave = MouseLeave
      ExplicitLeft = 216
      ExplicitTop = -24
      ExplicitWidth = 250
      ExplicitHeight = 50
    end
  end
  object Panel2: TPanel
    Left = 8
    Top = 64
    Width = 468
    Height = 50
    BevelOuter = bvNone
    Color = clLightskyblue
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    ParentBackground = False
    TabOrder = 1
    object Btn2: TSpeedButton
      Tag = 1
      Left = 5
      Top = 5
      Width = 458
      Height = 40
      Align = alClient
      Caption = 'Romance, by Georgy Sviridov'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      OnClick = BtnClick
      OnMouseEnter = MouseEnter
      OnMouseLeave = MouseLeave
      ExplicitLeft = 216
      ExplicitTop = -24
      ExplicitWidth = 250
      ExplicitHeight = 50
    end
  end
  object Panel3: TPanel
    Left = 8
    Top = 120
    Width = 468
    Height = 50
    BevelOuter = bvNone
    Color = clLightskyblue
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    ParentBackground = False
    TabOrder = 2
    object Btn3: TSpeedButton
      Tag = 2
      Left = 5
      Top = 5
      Width = 458
      Height = 40
      Align = alClient
      Caption = 'Test'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      OnClick = BtnClick
      OnMouseEnter = MouseEnter
      OnMouseLeave = MouseLeave
      ExplicitLeft = 216
      ExplicitTop = -24
      ExplicitWidth = 250
      ExplicitHeight = 50
    end
  end
  object Panel4: TPanel
    Left = 8
    Top = 176
    Width = 468
    Height = 50
    BevelOuter = bvNone
    Color = clLightskyblue
    Padding.Left = 5
    Padding.Top = 5
    Padding.Right = 5
    Padding.Bottom = 5
    ParentBackground = False
    TabOrder = 3
    object Btn4: TSpeedButton
      Tag = 3
      Left = 5
      Top = 5
      Width = 458
      Height = 40
      Align = alClient
      Caption = 'Ivan Sings, by Aram Khachaturian'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      OnClick = BtnClick
      OnMouseEnter = MouseEnter
      OnMouseLeave = MouseLeave
      ExplicitLeft = 216
      ExplicitTop = -24
      ExplicitWidth = 250
      ExplicitHeight = 50
    end
  end
  object Panel5: TPanel
    Left = 0
    Top = 280
    Width = 484
    Height = 68
    Align = alBottom
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object Panel6: TPanel
    Left = 0
    Top = 0
    Width = 484
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Piano in Delphi!'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
end
