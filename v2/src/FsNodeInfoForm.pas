unit FsNodeInfoForm;


{$reference System.Drawing.dll}
{$reference System.Windows.Forms.dll}


uses System;
uses System.Drawing;
uses System.Windows.Forms;
uses FsTreeNodes;


type
  NodeInfoForm = class(Form)
    {$region Fields}
    private _NodeInfoView: DataGridView;
    {$endregion}
    
    {$region Ctors}
    public constructor (SetOwner: Form);
    begin
      {$region Form}
      ClientSize      := new System.Drawing.Size(341, 135);
      FormBorderStyle := System.Windows.Forms.FormBorderStyle.None;
      ShowIcon        := false;
      ShowInTaskbar   := false;
      Owner           := SetOwner;
      StartPosition   := FormStartPosition.Manual;
      Opacity         := 0.75;
      {$endregion}
      
      {$region NodeInfoView}
      _NodeInfoView := new DataGridView();
      _NodeInfoView.Size                        := new System.Drawing.Size(Width, 135);
      _NodeInfoView.Location                    := new Point(0, 0);
      _NodeInfoView.ReadOnly                    := true;
      _NodeInfoView.GridColor                   := Color.White;
      _NodeInfoView.RowHeadersBorderStyle       := DataGridViewHeaderBorderStyle.None;
      _NodeInfoView.RowHeadersVisible           := false;
      _NodeInfoView.ScrollBars                  := ScrollBars.None;
      _NodeInfoView.AllowUserToAddRows          := false;
      _NodeInfoView.AllowUserToDeleteRows       := false;
      _NodeInfoView.AllowUserToResizeColumns    := false;
      _NodeInfoView.AllowUserToResizeRows       := false;
      _NodeInfoView.AllowUserToOrderColumns     := false;
      _NodeInfoView.AutoSizeRowsMode            := DataGridViewAutoSizeRowsMode.DisplayedCellsExceptHeaders;
      _NodeInfoView.ClipboardCopyMode           := DataGridViewClipboardCopyMode.Disable;
      _NodeInfoView.ColumnHeadersBorderStyle    := DataGridViewHeaderBorderStyle.Single;
      _NodeInfoView.ColumnHeadersHeightSizeMode := DataGridViewColumnHeadersHeightSizeMode.AutoSize;
      Controls.Add(_NodeInfoView);
      {$endregion}
      
      {$region Columns}
      var _InfoViewParams        := new DataGridViewTextBoxColumn();
      _InfoViewParams.Frozen     := true;
      _InfoViewParams.HeaderText := 'Property';
      _InfoViewParams.ReadOnly   := true;
      _InfoViewParams.Resizable  := DataGridViewTriState.False;
      _InfoViewParams.Width      := 55;
      _NodeInfoView.Columns.Add(_InfoViewParams);
      
      var _InfoViewSrc        := new DataGridViewTextBoxColumn();
      _InfoViewSrc.HeaderText := 'Source';
      _InfoViewSrc.ReadOnly   := true;
      _InfoViewSrc.Resizable  := DataGridViewTriState.False;
      _InfoViewSrc.Width      := 128;
      _InfoViewSrc.HeaderCell.Style.Alignment := DataGridViewContentAlignment.MiddleCenter;
      _NodeInfoView.Columns.Add(_InfoViewSrc);
      
      var _InfoViewDst        := new DataGridViewTextBoxColumn();
      _InfoViewDst.HeaderText := 'Destination';
      _InfoViewDst.ReadOnly   := true;
      _InfoViewDst.Resizable  := DataGridViewTriState.False;
      _InfoViewDst.Width      := 128;
      _InfoViewDst.HeaderCell.Style.Alignment := DataGridViewContentAlignment.MiddleCenter;
      _NodeInfoView.Columns.Add(_InfoViewDst);
      {$endregion}
    end;
    {$endregion}
    
    {$region Methods}
    public procedure Show(node: FsNode);
    begin
      var IsFolder := node is FolderNode;
      
      _NodeInfoView.Rows.Clear();
      
      if IsFolder then
        begin
          var info := (node as FolderNode).FoldersInfo;
          _NodeInfoView.Rows.Add('Folders', info.SrcFoldersToString(), info.DstFoldersToString());
          _NodeInfoView.Rows.Add('Files',   info.SrcFilesToString(),   info.DstFilesToString());
        end;
      var info := node.Info;
      _NodeInfoView.Rows.Add('Size',    info.SrcBytesToString(),   info.DstBytesToString());
      _NodeInfoView.Rows.Add('Created', info.SrcCreatedToString(), info.DstCreatedToString());
      _NodeInfoView.Rows.Add('Changed', info.SrcChangedToString(), info.DstChangedToString());
      
      _NodeInfoView.Size := _NodeInfoView.PreferredSize - (new System.Drawing.Size(31, IsFolder ? 26 : 24));
      Size := _NodeInfoView.Size;
      
      inherited Show();
      
      _NodeInfoView.ClearSelection();
    end;
    {$endregion}
  end;


end.