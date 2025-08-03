namespace NablaFs
{
    partial class MainForm
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MainForm));
            _SrcDesc = new System.Windows.Forms.Label();
            _SrcPath = new System.Windows.Forms.TextBox();
            _SrcSelect = new System.Windows.Forms.Button();
            _DstDesc = new System.Windows.Forms.Label();
            _DstPath = new System.Windows.Forms.TextBox();
            _DstSelect = new System.Windows.Forms.Button();
            _StartCompare = new System.Windows.Forms.Button();
            _ResetCompare = new System.Windows.Forms.Button();
            _PathView = new System.Windows.Forms.TreeView();
            _ImageList = new System.Windows.Forms.ImageList(components);
            _StatusBar = new System.Windows.Forms.StatusStrip();
            _ElapsedInfo = new System.Windows.Forms.ToolStripStatusLabel();
            _Sep1Info = new System.Windows.Forms.ToolStripStatusLabel();
            _RemainingInfo = new System.Windows.Forms.ToolStripStatusLabel();
            _Sep2Info = new System.Windows.Forms.ToolStripStatusLabel();
            _FilesInfo = new System.Windows.Forms.ToolStripStatusLabel();
            _Sep3Info = new System.Windows.Forms.ToolStripStatusLabel();
            _StageInfo = new System.Windows.Forms.ToolStripStatusLabel();
            _ProgressBar = new FsProgressBar();
            _NodeMenu = new System.Windows.Forms.ContextMenuStrip(components);
            _NodeMenuSrcToDst = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuDstToSrc = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuSrcDelete = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuDstDelete = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuRename = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuUpdate = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpen = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpenAsText = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpenAsBin = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpenParentFolder = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpenParentTerminal = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpenFolder = new System.Windows.Forms.ToolStripMenuItem();
            _NodeMenuOpenTerminal = new System.Windows.Forms.ToolStripMenuItem();
            _StatusBar.SuspendLayout();
            _NodeMenu.SuspendLayout();
            SuspendLayout();
            // 
            // _SrcDesc
            // 
            _SrcDesc.Location = new System.Drawing.Point(0, 10);
            _SrcDesc.Margin = new System.Windows.Forms.Padding(4, 0, 4, 0);
            _SrcDesc.Name = "_SrcDesc";
            _SrcDesc.Size = new System.Drawing.Size(74, 15);
            _SrcDesc.TabIndex = 0;
            _SrcDesc.Text = "Source:";
            _SrcDesc.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // _SrcPath
            // 
            _SrcPath.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right;
            _SrcPath.Location = new System.Drawing.Point(75, 7);
            _SrcPath.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _SrcPath.Name = "_SrcPath";
            _SrcPath.Size = new System.Drawing.Size(397, 23);
            _SrcPath.TabIndex = 1;
            _SrcPath.KeyDown += SrcPathKeyDown;
            // 
            // _SrcSelect
            // 
            _SrcSelect.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right;
            _SrcSelect.Image = Properties.Resources.path;
            _SrcSelect.Location = new System.Drawing.Point(473, 6);
            _SrcSelect.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _SrcSelect.Name = "_SrcSelect";
            _SrcSelect.Size = new System.Drawing.Size(28, 25);
            _SrcSelect.TabIndex = 2;
            _SrcSelect.UseVisualStyleBackColor = true;
            _SrcSelect.Click += PathSelectClick;
            // 
            // _DstDesc
            // 
            _DstDesc.Location = new System.Drawing.Point(0, 35);
            _DstDesc.Margin = new System.Windows.Forms.Padding(4, 0, 4, 0);
            _DstDesc.Name = "_DstDesc";
            _DstDesc.Size = new System.Drawing.Size(74, 15);
            _DstDesc.TabIndex = 0;
            _DstDesc.Text = "Destination:";
            _DstDesc.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // _DstPath
            // 
            _DstPath.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right;
            _DstPath.Location = new System.Drawing.Point(75, 32);
            _DstPath.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _DstPath.Name = "_DstPath";
            _DstPath.Size = new System.Drawing.Size(397, 23);
            _DstPath.TabIndex = 1;
            _DstPath.KeyDown += DstPathKeyDown;
            // 
            // _DstSelect
            // 
            _DstSelect.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right;
            _DstSelect.Image = Properties.Resources.path;
            _DstSelect.Location = new System.Drawing.Point(473, 31);
            _DstSelect.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _DstSelect.Name = "_DstSelect";
            _DstSelect.Size = new System.Drawing.Size(28, 25);
            _DstSelect.TabIndex = 2;
            _DstSelect.UseVisualStyleBackColor = true;
            _DstSelect.Click += PathSelectClick;
            // 
            // _StartCompare
            // 
            _StartCompare.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right;
            _StartCompare.Image = Properties.Resources.compare;
            _StartCompare.Location = new System.Drawing.Point(505, 6);
            _StartCompare.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _StartCompare.Name = "_StartCompare";
            _StartCompare.Size = new System.Drawing.Size(28, 25);
            _StartCompare.TabIndex = 3;
            _StartCompare.UseVisualStyleBackColor = true;
            _StartCompare.Click += StartCompareClick;
            // 
            // _ResetCompare
            // 
            _ResetCompare.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right;
            _ResetCompare.Image = Properties.Resources.reset;
            _ResetCompare.Location = new System.Drawing.Point(505, 31);
            _ResetCompare.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _ResetCompare.Name = "_ResetCompare";
            _ResetCompare.Size = new System.Drawing.Size(28, 25);
            _ResetCompare.TabIndex = 4;
            _ResetCompare.UseVisualStyleBackColor = true;
            _ResetCompare.Click += ResetCompareClick;
            // 
            // _PathView
            // 
            _PathView.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right;
            _PathView.ImageIndex = 0;
            _PathView.ImageList = _ImageList;
            _PathView.ItemHeight = 18;
            _PathView.Location = new System.Drawing.Point(5, 58);
            _PathView.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _PathView.Name = "_PathView";
            _PathView.SelectedImageIndex = 0;
            _PathView.ShowNodeToolTips = true;
            _PathView.Size = new System.Drawing.Size(527, 492);
            _PathView.TabIndex = 5;
            _PathView.AfterLabelEdit += PathViewAfterLabelEdit;
            _PathView.KeyDown += PathViewKeyDown;
            _PathView.MouseClick += PathViewMouseClick;
            // 
            // _ImageList
            // 
            _ImageList.ColorDepth = System.Windows.Forms.ColorDepth.Depth32Bit;
            _ImageList.ImageStream = (System.Windows.Forms.ImageListStreamer)resources.GetObject("_ImageList.ImageStream");
            _ImageList.TransparentColor = System.Drawing.Color.Transparent;
            _ImageList.Images.SetKeyName(0, "folder");
            _ImageList.Images.SetKeyName(1, "file");
            // 
            // _StatusBar
            // 
            _StatusBar.Items.AddRange(new System.Windows.Forms.ToolStripItem[] { _ElapsedInfo, _Sep1Info, _RemainingInfo, _Sep2Info, _FilesInfo, _Sep3Info, _StageInfo });
            _StatusBar.LayoutStyle = System.Windows.Forms.ToolStripLayoutStyle.HorizontalStackWithOverflow;
            _StatusBar.Location = new System.Drawing.Point(0, 578);
            _StatusBar.Name = "_StatusBar";
            _StatusBar.Size = new System.Drawing.Size(537, 22);
            _StatusBar.SizingGrip = false;
            _StatusBar.TabIndex = 6;
            _StatusBar.Text = "statusStrip1";
            // 
            // _ElapsedInfo
            // 
            _ElapsedInfo.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _ElapsedInfo.Name = "_ElapsedInfo";
            _ElapsedInfo.Size = new System.Drawing.Size(0, 17);
            _ElapsedInfo.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // _Sep1Info
            // 
            _Sep1Info.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _Sep1Info.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            _Sep1Info.ForeColor = System.Drawing.Color.Gray;
            _Sep1Info.Name = "_Sep1Info";
            _Sep1Info.Size = new System.Drawing.Size(11, 17);
            _Sep1Info.Text = "|";
            // 
            // _RemainingInfo
            // 
            _RemainingInfo.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _RemainingInfo.Name = "_RemainingInfo";
            _RemainingInfo.Size = new System.Drawing.Size(0, 17);
            _RemainingInfo.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // _Sep2Info
            // 
            _Sep2Info.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _Sep2Info.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            _Sep2Info.ForeColor = System.Drawing.Color.Gray;
            _Sep2Info.Name = "_Sep2Info";
            _Sep2Info.Size = new System.Drawing.Size(11, 17);
            _Sep2Info.Text = "|";
            // 
            // _FilesInfo
            // 
            _FilesInfo.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _FilesInfo.Name = "_FilesInfo";
            _FilesInfo.Size = new System.Drawing.Size(0, 17);
            _FilesInfo.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // _Sep3Info
            // 
            _Sep3Info.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _Sep3Info.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            _Sep3Info.ForeColor = System.Drawing.Color.Gray;
            _Sep3Info.Name = "_Sep3Info";
            _Sep3Info.Size = new System.Drawing.Size(11, 17);
            _Sep3Info.Text = "|";
            // 
            // _StageInfo
            // 
            _StageInfo.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            _StageInfo.Name = "_StageInfo";
            _StageInfo.Size = new System.Drawing.Size(0, 17);
            _StageInfo.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // _ProgressBar
            // 
            _ProgressBar.Anchor = System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right;
            _ProgressBar.BackColor = System.Drawing.Color.FromArgb(216, 216, 216);
            _ProgressBar.BarColor = System.Drawing.Color.FromArgb(0, 120, 215);
            _ProgressBar.BorderColor = System.Drawing.Color.Gray;
            _ProgressBar.ForeColor = System.Drawing.Color.Black;
            _ProgressBar.Location = new System.Drawing.Point(5, 554);
            _ProgressBar.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            _ProgressBar.Maximmum = 1024L;
            _ProgressBar.Name = "_ProgressBar";
            _ProgressBar.Size = new System.Drawing.Size(527, 20);
            _ProgressBar.TabIndex = 7;
            _ProgressBar.Text = "fsProgressBar1";
            _ProgressBar.TextVisible = false;
            _ProgressBar.Value = 0L;
            // 
            // _NodeMenu
            // 
            _NodeMenu.Items.AddRange(new System.Windows.Forms.ToolStripItem[] { _NodeMenuSrcToDst, _NodeMenuDstToSrc, _NodeMenuSrcDelete, _NodeMenuDstDelete, _NodeMenuRename, _NodeMenuUpdate, _NodeMenuOpen });
            _NodeMenu.Name = "_NodeMenu";
            _NodeMenu.Size = new System.Drawing.Size(128, 158);
            _NodeMenu.Closed += NodeMenuClosed;
            // 
            // _NodeMenuSrcToDst
            // 
            _NodeMenuSrcToDst.Image = Properties.Resources.srcdst;
            _NodeMenuSrcToDst.Name = "_NodeMenuSrcToDst";
            _NodeMenuSrcToDst.Size = new System.Drawing.Size(127, 22);
            _NodeMenuSrcToDst.Text = "Src -> Dst";
            _NodeMenuSrcToDst.Click += NodeMenuSrcToDstClick;
            // 
            // _NodeMenuDstToSrc
            // 
            _NodeMenuDstToSrc.Image = Properties.Resources.dstsrc;
            _NodeMenuDstToSrc.Name = "_NodeMenuDstToSrc";
            _NodeMenuDstToSrc.Size = new System.Drawing.Size(127, 22);
            _NodeMenuDstToSrc.Text = "Src <- Dst";
            _NodeMenuDstToSrc.Click += NodeMenuDstToSrcClick;
            // 
            // _NodeMenuSrcDelete
            // 
            _NodeMenuSrcDelete.Image = Properties.Resources.delete;
            _NodeMenuSrcDelete.Name = "_NodeMenuSrcDelete";
            _NodeMenuSrcDelete.Size = new System.Drawing.Size(127, 22);
            _NodeMenuSrcDelete.Text = "Src Delete";
            _NodeMenuSrcDelete.Click += NodeMenuSrcDeleteClick;
            // 
            // _NodeMenuDstDelete
            // 
            _NodeMenuDstDelete.Image = Properties.Resources.delete;
            _NodeMenuDstDelete.Name = "_NodeMenuDstDelete";
            _NodeMenuDstDelete.Size = new System.Drawing.Size(127, 22);
            _NodeMenuDstDelete.Text = "Dst Delete";
            _NodeMenuDstDelete.Click += NodeMenuDstDeleteClick;
            // 
            // _NodeMenuRename
            // 
            _NodeMenuRename.Image = Properties.Resources.rename;
            _NodeMenuRename.Name = "_NodeMenuRename";
            _NodeMenuRename.Size = new System.Drawing.Size(127, 22);
            _NodeMenuRename.Text = "Rename";
            _NodeMenuRename.Click += NodeMenuRenameClick;
            // 
            // _NodeMenuUpdate
            // 
            _NodeMenuUpdate.Image = Properties.Resources.update;
            _NodeMenuUpdate.Name = "_NodeMenuUpdate";
            _NodeMenuUpdate.Size = new System.Drawing.Size(127, 22);
            _NodeMenuUpdate.Text = "Update";
            _NodeMenuUpdate.Click += NodeMenuUpdateClick;
            // 
            // _NodeMenuOpen
            // 
            _NodeMenuOpen.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] { _NodeMenuOpenAsText, _NodeMenuOpenAsBin, _NodeMenuOpenParentFolder, _NodeMenuOpenParentTerminal, _NodeMenuOpenFolder, _NodeMenuOpenTerminal });
            _NodeMenuOpen.Name = "_NodeMenuOpen";
            _NodeMenuOpen.Size = new System.Drawing.Size(127, 22);
            _NodeMenuOpen.Text = "Open";
            // 
            // _NodeMenuOpenAsText
            // 
            _NodeMenuOpenAsText.Image = Properties.Resources.text;
            _NodeMenuOpenAsText.Name = "_NodeMenuOpenAsText";
            _NodeMenuOpenAsText.Size = new System.Drawing.Size(205, 22);
            _NodeMenuOpenAsText.Text = "With Notepad++";
            _NodeMenuOpenAsText.Click += NodeMenuOpenAsTextClick;
            // 
            // _NodeMenuOpenAsBin
            // 
            _NodeMenuOpenAsBin.Image = Properties.Resources.hex;
            _NodeMenuOpenAsBin.Name = "_NodeMenuOpenAsBin";
            _NodeMenuOpenAsBin.Size = new System.Drawing.Size(205, 22);
            _NodeMenuOpenAsBin.Text = "With Be.HexEditor";
            _NodeMenuOpenAsBin.Click += NodeMenuOpenAsBinClick;
            // 
            // _NodeMenuOpenParentFolder
            // 
            _NodeMenuOpenParentFolder.Image = Properties.Resources.path;
            _NodeMenuOpenParentFolder.Name = "_NodeMenuOpenParentFolder";
            _NodeMenuOpenParentFolder.Size = new System.Drawing.Size(205, 22);
            _NodeMenuOpenParentFolder.Text = "Parent Folder in Explorer";
            _NodeMenuOpenParentFolder.Click += NodeMenuOpenParentFolderClick;
            // 
            // _NodeMenuOpenParentTerminal
            // 
            _NodeMenuOpenParentTerminal.Image = Properties.Resources.cmder;
            _NodeMenuOpenParentTerminal.Name = "_NodeMenuOpenParentTerminal";
            _NodeMenuOpenParentTerminal.Size = new System.Drawing.Size(205, 22);
            _NodeMenuOpenParentTerminal.Text = "Parent Folder in Terminal";
            _NodeMenuOpenParentTerminal.Click += NodeMenuOpenParentTerminalClick;
            // 
            // _NodeMenuOpenFolder
            // 
            _NodeMenuOpenFolder.Image = Properties.Resources.path;
            _NodeMenuOpenFolder.Name = "_NodeMenuOpenFolder";
            _NodeMenuOpenFolder.Size = new System.Drawing.Size(205, 22);
            _NodeMenuOpenFolder.Text = "in Explorer";
            _NodeMenuOpenFolder.Click += NodeMenuOpenFolderClick;
            // 
            // _NodeMenuOpenTerminal
            // 
            _NodeMenuOpenTerminal.Image = Properties.Resources.cmder;
            _NodeMenuOpenTerminal.Name = "_NodeMenuOpenTerminal";
            _NodeMenuOpenTerminal.Size = new System.Drawing.Size(205, 22);
            _NodeMenuOpenTerminal.Text = "in Terminal";
            _NodeMenuOpenTerminal.Click += NodeMenuOpenTerminalClick;
            // 
            // MainForm
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            ClientSize = new System.Drawing.Size(537, 600);
            Controls.Add(_ProgressBar);
            Controls.Add(_StatusBar);
            Controls.Add(_PathView);
            Controls.Add(_ResetCompare);
            Controls.Add(_StartCompare);
            Controls.Add(_SrcSelect);
            Controls.Add(_SrcPath);
            Controls.Add(_SrcDesc);
            Controls.Add(_DstSelect);
            Controls.Add(_DstPath);
            Controls.Add(_DstDesc);
            Icon = (System.Drawing.Icon)resources.GetObject("$this.Icon");
            Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            MinimumSize = new System.Drawing.Size(553, 639);
            Name = "MainForm";
            Text = "Nabla•Fs";
            _StatusBar.ResumeLayout(false);
            _StatusBar.PerformLayout();
            _NodeMenu.ResumeLayout(false);
            ResumeLayout(false);
            PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label _SrcDesc;
        private System.Windows.Forms.TextBox _SrcPath;
        private System.Windows.Forms.Button _SrcSelect;
        private System.Windows.Forms.Label _DstDesc;
        private System.Windows.Forms.TextBox _DstPath;
        private System.Windows.Forms.Button _DstSelect;
        private System.Windows.Forms.Button _StartCompare;
        private System.Windows.Forms.Button _ResetCompare;
        private System.Windows.Forms.TreeView _PathView;
        private System.Windows.Forms.StatusStrip _StatusBar;
        private FsProgressBar _ProgressBar;
        private System.Windows.Forms.ImageList _ImageList;
        private System.Windows.Forms.ToolStripStatusLabel _ElapsedInfo;
        private System.Windows.Forms.ToolStripStatusLabel _Sep1Info;
        private System.Windows.Forms.ToolStripStatusLabel _RemainingInfo;
        private System.Windows.Forms.ToolStripStatusLabel _Sep2Info;
        private System.Windows.Forms.ToolStripStatusLabel _FilesInfo;
        private System.Windows.Forms.ToolStripStatusLabel _Sep3Info;
        private System.Windows.Forms.ToolStripStatusLabel _StageInfo;
        private System.Windows.Forms.ContextMenuStrip _NodeMenu;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuSrcToDst;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuDstToSrc;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuSrcDelete;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuDstDelete;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuRename;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuUpdate;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpen;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpenAsText;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpenAsBin;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpenParentFolder;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpenParentTerminal;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpenFolder;
        private System.Windows.Forms.ToolStripMenuItem _NodeMenuOpenTerminal;
    }
}
