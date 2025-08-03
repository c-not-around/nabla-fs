using System.Drawing;
using System.Windows.Forms;


namespace NablaFs
{
    internal abstract class FsNode : TreeNode
    {
        #region Fields
        private TwinsStatus _Status;
        #endregion

        #region Ctors
        public FsNode(string key, string name)
        {
            base.ImageKey         = key;
            base.SelectedImageKey = key;

            Text = name;
        }
        #endregion

        #region Properties
        public new string ImageKey => base.ImageKey;

        public new string SelectedImageKey => base.SelectedImageKey;

        public new Color ForeColor => base.ForeColor;

        public TwinsStatus Status
        {
            get => _Status;
            set
            {
                _Status = value;

                base.ForeColor = _Status switch
                {
                    TwinsStatus.None  => Color.Black,
                    TwinsStatus.Error => Color.Gray,
                    TwinsStatus.Twins => Color.Red,
                    TwinsStatus.Match => Color.Green,
                    _                 => Color.Orange,
                };
            }
        }

        public abstract TwinsObjectInfo Info { get; }

        public abstract TwinsFolderSpan Span { get; }

        public string RelativePath
        {
            get
            {
                string path = FullPath;
                return path[(path.IndexOf('\\') + 1)..];
            }
        }
        #endregion
    }

    internal class FolderNode(string name) : FsNode("folder", name)
    {
        #region Properties
        public TwinsFolderInfo FolderInfo { get; set; }

        public override TwinsObjectInfo Info => FolderInfo;

        public override TwinsFolderSpan Span => -FolderInfo;
        #endregion
    }

    internal class FileNode(string name) : FsNode("file", name)
    {
        #region Properties
        public TwinsFileInfo FileInfo { get; set; }

        public override TwinsObjectInfo Info => FileInfo;

        public override TwinsFolderSpan Span => -FileInfo;
        #endregion
    }
}