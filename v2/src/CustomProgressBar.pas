unit CustomProgressBar;


{$reference System.Drawing.dll}
{$reference System.Windows.Forms.dll}


uses System;
uses System.Globalization;
uses System.Drawing;
uses System.Drawing.Drawing2D;
uses System.Windows.Forms;


type
  FsProgressBar = class(Control)
    {$region Fields}
    private _Bitmap      : Bitmap;
    private _Graphics    : Graphics;
    private _BorderColor : System.Drawing.Color;
    private _BarColor    : System.Drawing.Color;
    private _Maximmum    : int64;
    private _Value       : int64;
    private _TextVisible : boolean;
    
    private static _FormatInfo := (new CultureInfo('en-US')).NumberFormat;
    {$endregion}
    
    {$region Override}
    protected procedure OnPaint(e: PaintEventArgs); override;
    begin
      inherited OnPaint(e);
      e.Graphics.DrawImage(_Bitmap, 0, 0);
    end;
    
    protected procedure OnSizeChanged(e: EventArgs); override;
    begin
      inherited OnSizeChanged(e);
      Init();
    end;
    {$endregion}
    
    {$region Accessors}
    private function GetSize() := inherited Size;
    private procedure SetSize(s: System.Drawing.Size);
    begin
      inherited Size := s;
      Init();
    end;
    
    private function GetWidth() := inherited Width;
    private procedure SetWidth(w: integer);
    begin
      inherited Width := w;
      Init();
    end;
    
    private function GetBackColor() := inherited BackColor;
    private procedure SetBackColor(c: System.Drawing.Color);
    begin
      inherited BackColor := c;
      Redraw();
      Invalidate();
    end;
    
    private private function GetForeColor() := inherited ForeColor;
    private private procedure SetForeColor(c: System.Drawing.Color);
    begin
      inherited ForeColor := c;
      Redraw();
      Invalidate();
    end;
    
    private procedure SetBorderColor(c: System.Drawing.Color);
    begin
      _BorderColor := c;
      Redraw();
      Invalidate();
    end;
    
    private procedure SetBarColor(c: System.Drawing.Color);
    begin
      _BarColor := c;
      Redraw();
      Invalidate();
    end;
    
    private procedure SetMaximmum(m: int64);
    begin
      _Maximmum := m;
      Redraw();
      Invalidate();
    end;
    
    private procedure SetValue(v: int64);
    begin
      _Value := v;
      Redraw();
      Invalidate();
    end;
    
    private procedure SetTextVisible(v: boolean);
    begin
      _TextVisible := v;
      Redraw();
      Invalidate();
    end;
    {$endregion}
    
    {$region Routines}
    private static function BytesPrefix(s: double): string;
    begin
      var p := 0;
      while s >= 1024.0 do
        begin
          s /= 1024.0;
          p += 1;
        end;
      
      var f := string('f');
      if s < 10.0 then
        f += '2'
      else if s < 100.0 then
        f += '1'
      else
        f += '0';
      
      result := s.ToString(f, _FormatInfo);
      
      if p > 0 then
        result += 'kMGTP'[p];
      
      result += 'b';
    end; 
    
    private procedure Redraw();
    begin
      var ClientWidth  := Width  - 3;
      var ClientHeight := Height - 3;
      
      var p := _Value / _Maximmum;
      var w := Convert.ToInt32(ClientWidth * p);
      
      _Graphics.Clear(BackColor);
      _Graphics.DrawRectangle(new Pen(_BorderColor), 0, 0, ClientWidth+2, ClientHeight+2);
      _Graphics.FillRectangle(new SolidBrush(_BarColor), 1, 1, w, ClientHeight);
      
      if _TextVisible then
        begin
          var pcnt := (100.0*p).ToString('f2', _FormatInfo);
          var text := $'{BytesPrefix(_Value)}/{BytesPrefix(_Maximmum)} ({pcnt}%)';
          var sz   := _Graphics.MeasureString(text, Font);
          var x    := 1 + Convert.ToInt32(Math.Round((ClientWidth - sz.Width) / 2));
          var y    := 1 + Convert.ToInt32(Math.Round((ClientHeight - sz.Height) / 2));
          
          _Graphics.DrawString(text, Font, new SolidBrush(ForeColor), x, y);
        end;
    end;
    
    private procedure Init();
    begin
      if Width > 0 then
        begin
          _Bitmap   := new Bitmap(Width, Height);
          _Graphics := Graphics.FromImage(_Bitmap);
          _Graphics.SmoothingMode := SmoothingMode.AntiAlias;
          
          Redraw();
          Invalidate();
        end;
    end;
    {$endregion}
    
    {$region Ctors}
    public constructor ();
    begin
      _BorderColor := Color.Gray;
      _BarColor    := Color.FromArgb($FF, $00, $78, $D7);
      _Maximmum    := 1024;
      _Value       := 0;
      _TextVisible := false;
      Size         := new System.Drawing.Size(100, 20);
      BackColor    := Color.FromArgb($FF, $F0, $F0, $F0);
      ForeColor    := Color.Black;
      
      SetStyle(ControlStyles.AllPaintingInWmPaint, true);
      SetStyle(ControlStyles.OptimizedDoubleBuffer, true);
      SetStyle(ControlStyles.UserPaint, true);
    end;
    {$endregion}
    
    {$region Properties}
    public property Size:        System.Drawing.Size  read GetSize        write SetSize;
    
    public property Width:       integer              read GetWidth       write SetWidth;
    
    public property BackColor:   System.Drawing.Color read GetBackColor   write SetBackColor;
    
    public property ForeColor:   System.Drawing.Color read GetForeColor   write SetForeColor;
    
    public property BorderColor: System.Drawing.Color read _BorderColor   write SetBorderColor;
    
    public property BarColor:    System.Drawing.Color read _BarColor      write SetBarColor;
    
    public property Maximmum:    int64                read _Maximmum      write SetMaximmum;
    
    public property Value:       int64                read _Value         write SetValue;
    
    public property TextVisible: boolean              read _TextVisible   write SetTextVisible;
    {$endregion}
  end;


end.