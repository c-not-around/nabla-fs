unit CustomProgressBar;


{$reference System.Drawing.dll}
{$reference System.Windows.Forms.dll}


uses
  System,
  System.Drawing,
  System.Windows.Forms;


type
  ColorProgressBar = class(ProgressBar)
  protected
    procedure OnPaint(e: PaintEventArgs); override;
    begin
      var rect := e.ClipRectangle;
      
      if ProgressBarRenderer.IsSupported then
        ProgressBarRenderer.DrawHorizontalBar(e.Graphics, e.ClipRectangle);
      
      rect.Width  := Convert.ToInt32(rect.Width * (Value / Maximum)) - 2;
      rect.Height -= 2;
      
      e.Graphics.FillRectangle(_BarBrush, 1, 1, rect.Width, rect.Height);
    end;
  private
    _BarBrush: Brush;
    
    function GetForeColor() := inherited ForeColor;
    
    procedure SetForeColor(c: System.Drawing.Color);
    begin
      _BarBrush := new SolidBrush(c);
      inherited ForeColor := c;
    end;
  public
    constructor ();
    begin
      inherited Create();
      
      _BarBrush := new SolidBrush(Color.LightBlue);
      
      SetStyle(ControlStyles.UserPaint, true);
    end;
    
    property ForeColor: System.Drawing.Color read GetForeColor write SetForeColor;
  end;


end.