using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;


namespace NablaFs
{
    internal class FsProgressBar : Control
    {
        #region Fields
        private Bitmap?   _Bitmap;
        private Graphics? _Graphics;
        private Color     _BorderColor;
        private Color     _BarColor;
        private long      _Maximmum;
        private long      _Value;
        private bool      _TextVisible;
        #endregion

        #region Override
        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);

            if (_Bitmap != null)
            {
                e.Graphics.DrawImage(_Bitmap, 0, 0);
            }
        }

        protected override void OnSizeChanged(EventArgs e)
        {
            base.OnSizeChanged(e);
            Init();
        }
        #endregion

        #region Routines
        private void Redraw()
        {
            if (_Graphics != null)
            {
                int ClientWidth  = Width  - 3;
                int ClientHeight = Height - 3;

                double p = (double)_Value / _Maximmum;
                int    w = Math.Min(Convert.ToInt32(ClientWidth * p), ClientWidth);

                _Graphics.Clear(BackColor);
                _Graphics.DrawRectangle(new Pen(_BorderColor), 0, 0, ClientWidth + 2, ClientHeight + 2);
                _Graphics.FillRectangle(new SolidBrush(_BarColor), 1, 1, w, ClientHeight);

                if (_TextVisible)
                {
                    string pcnt = (100.0 * p).ToString("f2", Format.FormatInfo);
                    string text = $"{Format.BytesPrefix(_Value)}/{Format.BytesPrefix(_Maximmum)} ({pcnt}%)";
                    SizeF  sz   = _Graphics.MeasureString(text, Font);
                    int    x    = 1 + Convert.ToInt32(Math.Round((ClientWidth - sz.Width) / 2));
                    int    y    = 2 + Convert.ToInt32(Math.Round((ClientHeight - sz.Height) / 2));

                    _Graphics.DrawString(text, Font, new SolidBrush(ForeColor), x, y);
                }

                Invalidate();
            }
        }

        private void Init()
        {
            if (Width > 0)
            {
                _Bitmap   = new Bitmap(Width, Height);
                _Graphics = Graphics.FromImage(_Bitmap);
                _Graphics.SmoothingMode = SmoothingMode.AntiAlias;

                Redraw();
            }
        }
        #endregion

        #region Ctors
        public FsProgressBar()
        {
            _BorderColor  = Color.Gray;
            _BarColor     = Color.FromArgb(0xFF, 0x00, 0x78, 0xD7);
            _Maximmum     = 1024;
            _Value        = 0;
            _TextVisible  = false;
            Size          = new Size(100, 20);
            BackColor     = Color.FromArgb(0xFF, 0xD8, 0xD8, 0xD8);
            ForeColor     = Color.Black;

            SetStyle(ControlStyles.AllPaintingInWmPaint, true);
            SetStyle(ControlStyles.OptimizedDoubleBuffer, true);
            SetStyle(ControlStyles.UserPaint, true);
        }
        #endregion

        #region Properties
        public Color BorderColor
        {
            get => _BorderColor;
            set
            {
                if (value != _BorderColor)
                {
                    _BorderColor = value;
                    Redraw();
                }
            }
        }

        public Color BarColor
        {
            get => _BarColor;
            set
            {
                if (value != _BarColor)
                {
                    _BarColor = value;
                    Redraw();
                }
            }
        }

        public long Maximmum
        {
            get => _Maximmum;
            set
            {
                if (value != _Maximmum)
                {
                    _Maximmum = value;
                    Redraw();
                }
            }
        }

        public long Value
        {
            get => _Value;
            set
            {
                if (value != _Value)
                {
                    _Value = value;
                    Redraw();
                }
            }
        }

        public bool TextVisible
        {
            get => _TextVisible;
            set
            {
                if (value != _TextVisible)
                {
                    _TextVisible = value;
                    Redraw();
                }
            }
        }
        #endregion
    }
}