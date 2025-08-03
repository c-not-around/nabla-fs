using System.Drawing;
using System.Windows.Forms;


namespace NablaFs
{
    internal partial class NodeInfoForm : Form
    {
        #region Ctors
        public NodeInfoForm()
        {
            InitializeComponent();

            _InfoViewParams.HeaderCell.Style.Alignment = DataGridViewContentAlignment.MiddleCenter;
            _InfoViewSrc.HeaderCell.Style.Alignment    = DataGridViewContentAlignment.MiddleCenter;
            _InfoViewDst.HeaderCell.Style.Alignment    = DataGridViewContentAlignment.MiddleCenter;

            _NodeInfoView.Paint += (ssender, e) => e.Graphics.DrawRectangle(Pens.Gray, 0, 0, _NodeInfoView.Width - 1, _NodeInfoView.Height - 1);
        }
        
        public NodeInfoForm(Form owner) : this()
        {
            Owner = owner;
        }
        #endregion

        #region Methods
        public void Show(FsNode node, params Point[] points)
        {
            if (node != null)
            {
                bool IsFolder = node is FolderNode;

                _NodeInfoView.Rows.Clear();

                if (IsFolder)
                {
                    TwinsFolderInfo info = ((FolderNode)node).FolderInfo;
                    _NodeInfoView.Rows.Add("Folders", info.SrcFoldersToString, info.DstFoldersToString);
                    _NodeInfoView.Rows.Add("Files",   info.SrcFilesToString,   info.DstFilesToString);
                }
                {
                    TwinsObjectInfo? info = node.Info;
                    _NodeInfoView.Rows.Add("Size",    info.SrcBytesToString,   info.DstBytesToString);
                    _NodeInfoView.Rows.Add("Created", info.SrcCreatedToString, info.DstCreatedToString);
                    _NodeInfoView.Rows.Add("Changed", info.SrcChangedToString, info.DstChangedToString);
                }

                _NodeInfoView.Size = _NodeInfoView.PreferredSize - (new Size(16, IsFolder ? 45 : 33));
                Size = _NodeInfoView.Size;

                if (points != null && points.Length > 0)
                {
                    int x = 0;
                    int y = 0;

                    foreach (Point point in points)
                    {
                        x += point.X;
                        y += point.Y;
                    }

                    Location = new Point(x, y);
                }

                Show();

                _NodeInfoView.ClearSelection();
            }
        }
        #endregion
    }
}