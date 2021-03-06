unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cefvcl, ceflib, cefgui, GR32_Image, AppEvnts;

type
  TMainform = class(TForm)
    PaintBox: TPaintBox32;
    chrmosr: TChromiumOSR;
    AppEvents: TApplicationEvents;
    procedure PaintBoxResize(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure AppEventsMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure chrmosrCursorChange(Sender: TObject; const browser: ICefBrowser;
      cursor: HICON);
    procedure chrmosrPaint(Sender: TObject; const browser: ICefBrowser;
      kind: TCefPaintElementType; dirtyRectsCount: Cardinal;
      const dirtyRects: PCefRectArray; const buffer: Pointer; width,
      height: Integer);
    procedure chrmosrGetRootScreenRect(Sender: TObject;
      const browser: ICefBrowser; rect: PCefRect; out Result: Boolean);
  end;

var
  Mainform: TMainform;

implementation

{$R *.dfm}

procedure TMainform.AppEventsMessage(var Msg: tagMSG; var Handled: Boolean);
var
  event: TCefKeyEvent;
begin
  chrmosr.Browser.Host.SendKeyEvent(@event);
  case Msg.message of
    WM_CHAR:
     begin
       FillChar(event, SizeOf(TCefKeyEvent), 0);
       event.type_ := KEYEVENT_CHAR;
       event.windows_key_code := Msg.wParam;
       event.native_key_code := Msg.lParam;
       chrmosr.Browser.Host.SendKeyEvent(@event);
     end;
  end;

end;

procedure TMainform.chrmosrCursorChange(Sender: TObject;
  const browser: ICefBrowser; cursor: HICON);
begin
  SetCursor(cursor)
end;

procedure TMainform.chrmosrGetRootScreenRect(Sender: TObject;
  const browser: ICefBrowser; rect: PCefRect; out Result: Boolean);
begin
  rect.x := 0;
  rect.y := 0;
  rect.width := PaintBox.Width;
  rect.height := PaintBox.Height;
  Result := True;
end;

procedure TMainform.chrmosrPaint(Sender: TObject; const browser: ICefBrowser;
  kind: TCefPaintElementType; dirtyRectsCount: Cardinal;
  const dirtyRects: PCefRectArray; const buffer: Pointer; width, height: Integer);
var
  src, dst: PByte;
  offset, i, j, w: Integer;
begin
  if (width <> PaintBox.Width) or (height <> PaintBox.Height) then Exit;

  with PaintBox.Buffer do
    begin
      PaintBox.Canvas.Lock;
      Lock;
      try
//        Move(buffer^, Bits^, vw * vh * 4);
//        PaintBox.Invalidate;
        for j := 0 to dirtyRectsCount - 1 do
        begin
          w := Width * 4;
          offset := ((dirtyRects[j].y * Width) + dirtyRects[j].x) * 4;
          src := @PByte(buffer)[offset];
          dst := @PByte(Bits)[offset];
          offset := dirtyRects[j].width * 4;
          for i := 0 to dirtyRects[j].height - 1 do
          begin
            Move(src^, dst^, offset);
            Inc(dst, w);
            Inc(src, w);
          end;
          PaintBox.Flush(Rect(dirtyRects[j].x, dirtyRects[j].y,
            dirtyRects[j].x + dirtyRects[j].width,  dirtyRects[j].y + dirtyRects[j].height));
        end;
      finally
        Unlock;
        PaintBox.Canvas.Unlock;
      end;
    end;
end;


function getModifiers(Shift: TShiftState): TCefEventFlags;
begin
  Result := [];
  if ssShift in Shift then Include(Result, EVENTFLAG_SHIFT_DOWN);
  if ssAlt in Shift then Include(Result, EVENTFLAG_ALT_DOWN);
  if ssCtrl in Shift then Include(Result, EVENTFLAG_CONTROL_DOWN);
  if ssLeft in Shift then Include(Result, EVENTFLAG_LEFT_MOUSE_BUTTON);
  if ssRight in Shift then Include(Result, EVENTFLAG_RIGHT_MOUSE_BUTTON);
  if ssMiddle in Shift then Include(Result, EVENTFLAG_MIDDLE_MOUSE_BUTTON);
end;

function GetButton(Button: TMouseButton): TCefMouseButtonType;
begin
  case Button of
    TMouseButton.mbLeft: Result := MBT_LEFT;
    TMouseButton.mbRight: Result := MBT_RIGHT;
    TMouseButton.mbMiddle: Result := MBT_MIDDLE;
  end;
end;

procedure TMainform.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  event: TCefMouseEvent;
begin
  event.x := X;
  event.y := Y;
  event.modifiers := getModifiers(Shift);
  chrmosr.Browser.Host.SendMouseClickEvent(@event, GetButton(Button), False, 1);
end;

procedure TMainform.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  event: TCefMouseEvent;
begin
  event.x := X;
  event.y := Y;
  event.modifiers := getModifiers(Shift);
  chrmosr.Browser.Host.SendMouseMoveEvent(@event, not PaintBox.MouseInControl);
end;

procedure TMainform.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  event: TCefMouseEvent;
begin
  event.x := X;
  event.y := Y;
  event.modifiers := getModifiers(Shift);
  chrmosr.Browser.Host.SendMouseClickEvent(@event, GetButton(Button), True, 1);
end;

procedure TMainform.PaintBoxResize(Sender: TObject);
begin
  PaintBox.Buffer.SetSize(PaintBox.Width, PaintBox.Height);
  chrmosr.browser.Host.WasResized;
  chrmosr.Browser.Host.SendFocusEvent(True);
  Application.ProcessMessages;
end;

end.
