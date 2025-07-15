{$apptype windows}

{$reference System.Drawing.dll}
{$reference System.Windows.Forms.dll}
{$reference Microsoft.VisualBasic.dll}

{$resource res\icon.ico}
{$resource res\path.png}
{$resource res\compare.png}
{$resource res\reset.png}
{$resource res\file.png}
{$resource res\folder.png}
{$resource res\copy.png}
{$resource res\delete.png}
{$resource res\rename.png}
{$resource res\update.png}
{$resource res\fcmp.png}
{$resource res\cmder.png}
{$resource res\text.png}
{$resource res\hex.png}

{$mainresource res\res.res}


uses
  System,
  System.IO,
  System.Threading,
  System.Threading.Tasks,
  System.Diagnostics,
  System.Globalization,
  System.Drawing,
  System.Windows.Forms,
  Microsoft.VisualBasic.FileIO,
  Extensions,
  CompareForm;


type
  TwinPaths = record
    Source     : string;
    Destination: string;
    
    class function MoveName(path, name: string) := path.Remove(path.LastIndexOf('\') + 1) + name;
    
    function CombinePaths(path: string; direct: boolean := true): TwinPaths;
    begin
      path := path.Clip();
      
      result.Source      := (direct ? self.Source : self.Destination) + '\' + path;
      result.Destination := (direct ? self.Destination : self.Source) + '\' + path;
    end;
    
    function Move(name: string): TwinPaths;
    begin
      result.Source      := MoveName(self.Source, name);
      result.Destination := MoveName(self.Destination, name);
    end;
  end;
  
  FolderInfo = class
  private
    _Folders: integer;
    _Files  : integer;
    _Bytes  : int64;
    
    constructor (folders, files, bytes: integer);
    begin
      _Folders := folders;
      _Files   := files;
      _Bytes   := bytes;
    end;
    
    class function GetFolderInfo(path: string): FolderInfo;
    begin
      if &Directory.Exists(path) then
        begin
          result := new FolderInfo(0, 0, 0);
          
          try
            var folders := Directory.GetDirectories(path);
            if folders <> nil then
              begin
                foreach var f in folders do
                    result += GetFolderInfo(f);
                result._Folders += folders.Length;
              end;
            
            var files := Directory.GetFiles(path);
            if files <> nil then
              begin
                foreach var f in files do
                  result._Bytes += (new FileInfo(f)).Length;
                result._Files += files.Length;
              end;
            
            exit;
          except
          
          end;
        end;
      
      result := new FolderInfo(-1, -1, -1);
    end;
  public
    constructor (path: string);
    begin
      var info := GetFolderInfo(path);
      
      _Folders := info.Folders;
      _Files   := info._Files;
      _Bytes   := info._Bytes;
    end;
    
    property IsValid: boolean read (not ((_Folders < 0) or (_Files < 0) or (_Bytes < 0)));
    
    property Folders: integer read _Folders;
    
    property Files: integer read _Files;
    
    property Bytes: int64 read _Bytes;
    
    property ItemsCount: integer read (_Folders + _Files);
    
    function ToString() := $'Folders: {_Folders:d}, Files: {_Files:d}, Size: {_Bytes:d}bytes;';
    
    class function operator=(left, right: FolderInfo) := (left._Bytes = right._Bytes) and (left._Files = right._Files) and (left._Folders = right._Folders);
    
    class function operator<>(left, right: FolderInfo) := not (left = right);
    
    class function operator+(left, right: FolderInfo) := new FolderInfo(left._Folders + right._Folders, left._Files + right._Files, left._Bytes + right._Bytes);
    
    class procedure operator+=(var left: FolderInfo; right: FolderInfo) := begin left := left + right; end;
  end;
  
  CompareResult = ( None, Twins, SrcOnly, DstOnly, Matches );


const
  ICON_FILE      = 0;
  ICON_FOLDER    = 1;
  NM_COPY_SRC    = 0;
  NM_COPY_DST    = 1;
  NM_DELETE_SRC  = 2;
  NM_DELETE_DST  = 3;
  NM_RENAME      = 4;
  NM_UPDATE      = 5;
  NM_BW_COMPARE  = 6;
  NM_OPEN        = 7;
  NMO_TEXT       = 0;
  NMO_HEX        = 1;
  NMO_EXPLORER   = 2;
  NMO_TERMINAL   = 3;
  NMO_EXP_FOLDER = 4;
  NMO_TER_FOLDER = 5;


var
  Main        : Form;
  PathsBox    : Panel;
  SrcPath     : TextBox;
  DstPath     : TextBox;
  SrcSelect   : Button;
  DstSelect   : Button;
  ActionBox   : Panel;
  StartCompare: Button;
  ResetCompare: Button;
  PathView    : TreeView;
  NodeMenu    : ContextMenuStrip;
  NodeInfoForm: Form;
  NodeInfoView: DataGridView;
  Paths       : TwinPaths;
  MenuShift   : boolean := false;
  CmderPath   : string;
  HexEditor   : string;
  Notepad     : string;


{$region Routines}
function FillNode(root: TreeNode; src, dst: string): boolean;
begin
  result := true;
  
  try
    {$region Taget Folders}
    foreach var f: string in Directory.GetDirectories(src) do
      begin
        var info := new DirectoryInfo(f);
        var twin := dst+'\'+info.Name;
        
        var node                := new TreeNode();
        node.Text               := info.Name;
        node.ImageIndex         := ICON_FOLDER;
        node.SelectedImageIndex := ICON_FOLDER;
        node.ContextMenuStrip   := NodeMenu;
        
        Main.Invoke(() -> begin root.Nodes.Add(node); end);
        
        if Directory.Exists(twin) then
          begin
            var r := FillNode(node, f, twin);
            Main.Invoke(() ->
              begin
                node.Tag       := r ? CompareResult.Matches : CompareResult.Twins;
                node.ForeColor := r ? Color.Green           : Color.Red; 
              end
            );
            result := result and r;
          end
        else
          begin
            Main.Invoke(() -> 
              begin
                node.Tag       := CompareResult.SrcOnly;
                node.ForeColor := Color.Orange; 
              end
            );
            result := false;
          end;
      end;
    {$endregion}
    
    {$region Taget Files}
    foreach var f: string in Directory.GetFiles(src) do
      begin
        var info := new FileInfo(f);
        var twin := dst+'\'+info.Name;
        var twex := &File.Exists(twin);
        var mtch := twex and (info.Length = ((new FileInfo(twin)).Length));
        
        var node                := new TreeNode();
        node.Text               := info.Name;
        node.ImageIndex         := ICON_FILE;
        node.SelectedImageIndex := ICON_FILE;
        node.ContextMenuStrip   := NodeMenu;
        node.ForeColor          := twex ? (mtch ? Color.Green           : Color.Red          ) : Color.Orange;
        node.Tag                := twex ? (mtch ? CompareResult.Matches : CompareResult.Twins) : CompareResult.SrcOnly;
        
        Main.Invoke(() -> begin root.Nodes.Add(node); end);
        
        result := result and twex and mtch;
      end;
    {$endregion}
    
    {$region Destination Folders}
    foreach var f: string in Directory.GetDirectories(dst) do
      begin
        var info := new DirectoryInfo(f);
        var twin := src+'\'+info.Name;
        
        if not Directory.Exists(twin) then
          begin
            var node                := new TreeNode();
            node.Text               := info.Name;
            node.ImageIndex         := ICON_FOLDER;
            node.SelectedImageIndex := ICON_FOLDER;
            node.ContextMenuStrip   := NodeMenu;
            node.ForeColor          := Color.Orange;
            node.Tag                := CompareResult.DstOnly;
            
            Main.Invoke(() -> begin root.Nodes.Add(node); end);
            
            result := false;
          end;
      end;
    {$endregion}
    
    {$region Destination Files}
    foreach var f: string in Directory.GetFiles(dst) do
      begin
        var info := new FileInfo(f);
        var twin := src+'\'+info.Name;
        
        if not &File.Exists(twin) then
          begin
            var node                := new TreeNode();
            node.Text               := info.Name;
            node.ImageIndex         := ICON_FILE;
            node.SelectedImageIndex := ICON_FILE;
            node.ContextMenuStrip   := NodeMenu;
            node.ForeColor          := Color.Orange;
            node.Tag                := CompareResult.DstOnly;
            
            Main.Invoke(() -> begin root.Nodes.Add(node); end);
            
            result := false;
          end;
      end;
    {$endregion}
  except on ex: Exception do
    begin
      Main.Invoke(() -> 
        begin 
          root.ForeColor   := Color.Gray;
          root.ToolTipText := ex.Message;
        end
      );
      result := false;
    end;
  end;
end;

procedure CompareTask();
begin
  Main.Invoke(() -> begin Cursor.Current := Cursors.WaitCursor; end);
  
  var root                := new TreeNode();
  root.Text               := Paths.Source.Substring(Paths.Source.LastIndexOf('\') + 1);
  root.ImageIndex         := ICON_FOLDER;
  root.SelectedImageIndex := ICON_FOLDER;
  
  Main.Invoke(() -> begin PathView.Nodes.Add(root); end);
  
  var r := FillNode(root, Paths.Source, Paths.Destination);
  
  Main.Invoke(() -> 
    begin
      root.ForeColor       := r ? Color.Green : Color.Red;
      
      PathsBox.Enabled     := true;
      StartCompare.Enabled := true;
      
      Cursor.Current       := Cursors.Default;
    end
  );
end;

procedure CheckNodes(node: TreeNode);
begin
  if node <> nil then
    begin
      var r := CompareResult.Matches;
      
      for var i := 0 to node.Nodes.Count-1 do
        if CompareResult(node.Nodes[i].Tag) <> CompareResult.Matches then
          begin
            r := CompareResult.Twins;
            break;
          end;
      
      node.Tag       := r;
      node.ForeColor := r = CompareResult.Matches ? Color.Green : Color.Red;
      
      if node.Level >= 0 then
        CheckNodes(node.Parent);
    end;
end;

function CompareFile(src, dst: string): CompareResult;
begin
  if &File.Exists(src) then
    begin
      if &File.Exists(dst) then
        result := (new FileInfo(src)).Length = (new FileInfo(dst)).Length ? CompareResult.Matches : CompareResult.Twins
      else
        result := CompareResult.SrcOnly;
    end
  else
    result := &File.Exists(dst) ? CompareResult.DstOnly : CompareResult.None;
end;

function CompareFolder(src, dst: string): CompareResult;
begin
  if Directory.Exists(src) then
    begin
      if Directory.Exists(dst) then
        result := (new FolderInfo(src)) = (new FolderInfo(dst)) ? CompareResult.Matches : CompareResult.Twins
      else
        result := CompareResult.SrcOnly;
    end
  else
    result := Directory.Exists(dst) ? CompareResult.DstOnly : CompareResult.None;
end;

function NodeUpdate(node: TreeNode): boolean;
begin
  var path   := Paths.CombinePaths(node.FullPath);
  var parent := node.Parent;
  
  result := false;
  
  var IsFolder := node.ImageIndex = ICON_FOLDER;
  var r        := IsFolder ? CompareFolder(path.Source, path.Destination) : CompareFile(path.Source, path.Destination);
  
  if r <> CompareResult(node.Tag) then
    begin
      if r = CompareResult.None then
        begin
          Main.Invoke(() -> begin PathView.Nodes.Remove(node); end);
          result := true;
        end
      else
        begin
          if IsFolder then
            begin
              Main.Invoke(() -> begin node.Nodes.Clear(); end);
              FillNode(node, path.Source, path.Destination);
            end;
              
          node.Tag       := r;
          node.ForeColor := r = CompareResult.Matches ? Color.Green : (r = CompareResult.Twins ? Color.Red : Color.Orange);
        end;
      
      Main.Invoke(() -> begin CheckNodes(parent); end);
    end;
end;

procedure NodeCopyTask(direct: boolean; node: TreeNode);
begin
  var path := Paths.CombinePaths(node.FullPath, direct);
  
  try
    if node.ImageIndex = ICON_FOLDER then
      FileSystem.CopyDirectory(path.Source, path.Destination, UIOption.AllDialogs)
    else
      FileSystem.CopyFile(path.Source, path.Destination, UIOption.AllDialogs);
    
    NodeUpdate(node);
  except on ex: Exception do
    MessageBox.Show
    (
      $'"{path.Source}" copy error to {path.Destination}: {ex.Message}.', 'Error', 
      MessageBoxButtons.OK, MessageBoxIcon.Error
    );
  end;
  
  Main.Invoke(() -> begin Main.Enabled := true; end);
end;

procedure NodeCopy(direct: boolean);
begin
  Main.Enabled := false;
  Task.Factory.StartNew(() -> begin NodeCopyTask(direct, PathView.SelectedNode); end);
end;

procedure NodeDeleteTask(root: string; node: TreeNode);
begin
  var path := root + '\' + node.FullPath.Clip();
  
  try
    if node.ImageIndex = ICON_FOLDER then
      FileSystem.DeleteDirectory(path, UIOption.AllDialogs, RecycleOption.SendToRecycleBin)
    else
      FileSystem.DeleteFile(path, UIOption.AllDialogs, RecycleOption.SendToRecycleBin);
    
    Main.Invoke(() -> 
      begin
        var parent := node.Parent; 
        PathView.Nodes.Remove(node);
        CheckNodes(parent);
      end
    );
  except on ex: Exception do
    MessageBox.Show
    (
      $'"{path}" delete error: {ex.Message}.', 'Error', 
      MessageBoxButtons.OK, MessageBoxIcon.Error
    );
  end;
  
  Main.Invoke(() -> begin Main.Enabled := true; end);
end;

procedure NodeDelete(root: string);
begin
  Main.Enabled := false;
  Task.Factory.StartNew(() -> begin NodeDeleteTask(root, PathView.SelectedNode); end);
end;

procedure NodeMove(src, dst: string; folder: boolean);
begin
  try
    if folder then
      FileSystem.MoveDirectory(src, dst)
    else
      FileSystem.MoveFile(src, dst);
  except on ex: Exception do
    MessageBox.Show
    (
      $'rename "{src}" with "{dst}" error: {ex.Message}.', 'Error', 
      MessageBoxButtons.OK, MessageBoxIcon.Error
    );
  end;
end;

procedure NodeRenameTask(node: TreeNode; name: string);
begin
  var OldPaths := Paths.CombinePaths(node.FullPath);
  var NewPaths := OldPaths.Move(name);
  
  var f := node.ImageIndex = ICON_FOLDER;
  var r := CompareResult(node.Tag);
  
  if r <> CompareResult.DstOnly then
    NodeMove(OldPaths.Source, NewPaths.Source, f);
  
  if r <> CompareResult.SrcOnly then
    NodeMove(OldPaths.Destination, NewPaths.Destination, f);
  
  Main.Invoke(()->begin node.Text := name; end);
  
  var ParentNodes := node.Parent.Nodes;
  foreach var n: TreeNode in ParentNodes do
    begin
      if (n.Text = name) and (n <> node) then
        begin
          ParentNodes.Remove(n);
          break;
        end;
    end;
  
  NodeUpdate(node);
  
  Main.Invoke(() ->
    begin 
      PathView.LabelEdit := false;
      Main.Enabled       := true; 
    end
  );
end;

procedure NodeRename(node: TreeNode; name: string);
begin
  Main.Enabled := false;
  Task.Factory.StartNew(() -> begin NodeRenameTask(node, name); end);
end;

procedure WinRun(fname, args: string);
begin
  try
    Process.Start(fname, args);
  except on ex: Exception do
    MessageBox.Show
    (
      $'"{fname} {args}" execution error: {ex.Message}', 'Error', 
      MessageBoxButtons.OK, MessageBoxIcon.Error
    );
  end;
end;

procedure Run(app, format: string; parent: boolean := false);
begin
  var node := PathView.SelectedNode;
  var path := node.FullPath.Clip();
  var stat := CompareResult(node.Tag);
  if parent then
    path := path.Parent();
  
  if stat <> CompareResult.DstOnly then
    WinRun(app, String.Format(format, Paths.Source, path));
  if stat <> CompareResult.SrcOnly then
    WinRun(app, String.Format(format, Paths.Destination, path));
end;
{$endregion}

{$region Handlers}
procedure PathSelectClick(sender: object; e: EventArgs);
begin
  var tb := (sender as Button).Tag as TextBox;
  
  var dialog                 := new FolderBrowserDialog();
  dialog.ShowNewFolderButton := false;
  dialog.Description         := 'Select ' + tb.Name;
  
  if dialog.ShowDialog() = DialogResult.OK then
    tb.Text := dialog.SelectedPath;
  
  dialog.Dispose();
end;

procedure StartCompareClick(sender: object; e: EventArgs);
begin
  Paths.Source      := SrcPath.Text;
  Paths.Destination := DstPath.Text;
  
  if not Directory.Exists(Paths.Source) then
    begin
      MessageBox.Show('Incorrect source path.', 'Error', MessageBoxButtons.OK, MessageBoxIcon.Error);
      exit;
    end;
  
  if not Directory.Exists(Paths.Destination) then
    begin
      MessageBox.Show('Incorrect destination path.', 'Error', MessageBoxButtons.OK, MessageBoxIcon.Error);
      exit;
    end;
  
  PathsBox.Enabled     := false;
  StartCompare.Enabled := false;
  
  PathView.Nodes.Clear();
  NodeInfoView.Rows.Clear();
  NodeInfoForm.Hide();
  
  Task.Factory.StartNew(CompareTask);
end;

procedure ResetCompareClick(sender: object; e: EventArgs);
begin
  PathView.Nodes.Clear();
  NodeInfoView.Rows.Clear();
  NodeInfoForm.Hide();
end;

procedure PathViewMouseClick(sender: object; e: MouseEventArgs);
begin
  if PathView.SelectedNode <> nil then
    PathView.SelectedNode.BackColor := PathView.BackColor;
  
  var node := PathView.GetNodeAt(e.Location);
  
  if e.Button = MouseButtons.Right then
    begin
      node.BackColor        := Color.LightGray;
      PathView.SelectedNode := node;
      
      if (node <> nil) and (node.Level > 0) then
        begin
          var r    :  CompareResult;
          var path := Paths.CombinePaths(node.FullPath);
          
          NodeInfoView.Rows.Clear();
          
          if (node.Tag = nil) or NodeUpdate(node) then
            exit;
          
          if node.ImageIndex = ICON_FILE then
            begin
              r := CompareResult(node.Tag);
              
              var SrcInfo := r <> CompareResult.DstOnly ? new FileInfo(path.Source) : nil;
              var DstInfo := r <> CompareResult.SrcOnly ? new FileInfo(path.Destination) : nil;
              
              var SrcSize := SrcInfo <> nil ? SrcInfo.Length.ToString('N0') : '-';
              var DstSize := DstInfo <> nil ? DstInfo.Length.ToString('N0') : '-';
              NodeInfoView.Rows.Add('Size', SrcSize, DstSize);
              
              var SrcCreated := SrcInfo <> nil ? SrcInfo.CreationTime.ToString('yyyy-MM-dd HH:mm:ss') : '-';
              var DstCreated := DstInfo <> nil ? DstInfo.CreationTime.ToString('yyyy-MM-dd HH:mm:ss') : '-';
              NodeInfoView.Rows.Add('Created', SrcCreated, DstCreated);
              
              var SrcChanged := SrcInfo <> nil ? SrcInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') : '-';
              var DstChanged := DstInfo <> nil ? DstInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') : '-';
              NodeInfoView.Rows.Add('Changed', SrcChanged, DstChanged);
            end
          else
            begin
              r := CompareResult(node.Tag);
              
              var SrcInfo := new FolderInfo(path.Source);
              var DstInfo := new FolderInfo(path.Destination);
              
              var SrcFolders := SrcInfo.IsValid ? SrcInfo.Folders.ToString() : '-';
              var DstFolders := DstInfo.IsValid ? DstInfo.Folders.ToString() : '-';
              NodeInfoView.Rows.Add('Folders', SrcFolders, DstFolders);
              
              var SrcFiles := SrcInfo.IsValid ? SrcInfo.Files.ToString() : '-';
              var DstFiles := DstInfo.IsValid ? DstInfo.Files.ToString() : '-';
              NodeInfoView.Rows.Add('Files', SrcFiles, DstFiles);
              
              var SrcSize := SrcInfo.IsValid ? SrcInfo.Bytes.ToString('N0') : '-';
              var DstSize := DstInfo.IsValid ? DstInfo.Bytes.ToString('N0') : '-';
              NodeInfoView.Rows.Add('Size', SrcSize, DstSize);
              
              var SrcCreated := SrcInfo.IsValid ? Directory.GetCreationTime(path.Source).ToString('yyyy-MM-dd HH:mm:ss') : '-';
              var DstCreated := DstInfo.IsValid ? Directory.GetCreationTime(path.Destination).ToString('yyyy-MM-dd HH:mm:ss') : '-';
              NodeInfoView.Rows.Add('Created', SrcCreated, DstCreated);
              
              var SrcChanged := SrcInfo.IsValid ? Directory.GetLastWriteTime(path.Source).ToString('yyyy-MM-dd HH:mm:ss') : '-';
              var DstChanged := DstInfo.IsValid ? Directory.GetLastWriteTime(path.Destination).ToString('yyyy-MM-dd HH:mm:ss') : '-';
              NodeInfoView.Rows.Add('Changed', SrcChanged, DstChanged);
            end;
          
          NodeMenu.Items[NM_COPY_SRC].Enabled    := (r = CompareResult.Twins) or (r = CompareResult.SrcOnly) or MenuShift;
          NodeMenu.Items[NM_COPY_DST].Enabled    := (r = CompareResult.Twins) or (r = CompareResult.DstOnly) or MenuShift;
          NodeMenu.Items[NM_DELETE_SRC].Enabled  := (r = CompareResult.SrcOnly) or MenuShift;
          NodeMenu.Items[NM_DELETE_DST].Enabled  := (r = CompareResult.DstOnly) or MenuShift;
          NodeMenu.Items[NM_BW_COMPARE].Enabled  := (node.ImageIndex = ICON_FILE) and ((r = CompareResult.Twins) or (r = CompareResult.Matches));
          
          var nmo := (NodeMenu.Items[NM_OPEN] as ToolStripMenuItem).DropDownItems;
          
          nmo[NMO_TEXT].Visible       := node.ImageIndex = ICON_FILE;
          nmo[NMO_HEX].Visible        := node.ImageIndex = ICON_FILE;
          nmo[NMO_EXPLORER].Visible   := node.ImageIndex = ICON_FILE;
          nmo[NMO_TERMINAL].Visible   := node.ImageIndex = ICON_FILE;
          nmo[NMO_EXP_FOLDER].Visible := node.ImageIndex = ICON_FOLDER;
          nmo[NMO_TER_FOLDER].Visible := node.ImageIndex = ICON_FOLDER;
          
          NodeInfoView.Size     := NodeInfoView.PreferredSize - (new Size(31, node.ImageIndex = ICON_FILE ? 24 : 26));
          NodeInfoForm.Size     := NodeInfoView.Size;
          NodeInfoForm.Location := Main.Location + PathView.Location + e.Location + (new Point(NodeMenu.Size.Width + 10, 33));
          NodeInfoForm.Show();
          NodeInfoView.ClearSelection();
          
          MenuShift := false;
        end
      else
        NodeInfoForm.Hide();
    end
  else 
    NodeInfoForm.Hide();
end;
{$endregion}

begin
  {$region App}
  Application.CurrentInputLanguage := InputLanguage.FromCulture(new CultureInfo('en-US'));
  Application.EnableVisualStyles();
  Application.SetCompatibleTextRenderingDefault(false);
  {$endregion}
  
  {$region MainForm}
  Main                 := new Form();
  Main.ClientSize      := new Size(410, 520);
  Main.MinimumSize     := new Size(425, 555);
  Main.Icon            := new Icon(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('icon.ico'));
  Main.StartPosition   := FormStartPosition.CenterScreen;
  Main.Text            := 'Nabla•Fs';
  {$endregion}
  
  {$region Paths Select}
  PathsBox          := new Panel();
  PathsBox.Size     := new Size(Main.ClientSize.Width-2*5-30, 50);
  PathsBox.Location := new Point(5, 5);
  PathsBox.Anchor   := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right;
  Main.Controls.Add(PathsBox);
  
  var SourceDesc       := new &Label();
  SourceDesc.Size      := new Size(65, 15);
  SourceDesc.Location  := new Point(5, 5);
  SourceDesc.TextAlign := ContentAlignment.MiddleRight;
  SourceDesc.TabStop   := false;
  SourceDesc.Text      := 'Source:';
  PathsBox.Controls.Add(SourceDesc);
  
  SrcPath          := new TextBox();
  SrcPath.Size     := new Size(275, 15);
  SrcPath.Location := new Point(71, 3);
  SrcPath.Anchor   := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right;
  SrcPath.Name     := 'Source';
  SrcPath.KeyDown  += (sender, e) ->
    begin
      if e.KeyData = Keys.Down then
        begin
          if SrcPath.TextLength > 0 then
            DstPath.Text := SrcPath.Text;
          DstPath.Focus();
          DstPath.SelectionLength := 0;
          DstPath.SelectionStart  := DstPath.TextLength;
        end;
    end;
  PathsBox.Controls.Add(SrcPath);
  
  SrcSelect            := new Button();
  SrcSelect.Size       := new Size(24, 22);
  SrcSelect.Location   := new Point(SrcPath.Left+SrcPath.Width+1, SrcPath.Top-1);
  SrcSelect.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
  SrcSelect.Image      := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('path.png'));
  SrcSelect.ImageAlign := ContentAlignment.MiddleRight;
  SrcSelect.TabStop    := false;
  SrcSelect.Tag        := SrcPath;
  SrcSelect.Click      += PathSelectClick;
  PathsBox.Controls.Add(SrcSelect);
  
  var DestinationDesc       := new &Label();
  DestinationDesc.Size      := new Size(65, 15);
  DestinationDesc.Location  := new Point(5, 27);
  DestinationDesc.TextAlign := ContentAlignment.MiddleRight;
  DestinationDesc.Text      := 'Destination:';
  DestinationDesc.TabStop   := false;
  PathsBox.Controls.Add(DestinationDesc);
  
  DstPath          := new TextBox();
  DstPath.Size     := new Size(275, 15);
  DstPath.Location := new Point(71, 25);
  DstPath.Anchor   := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right;
  DstPath.Name     := 'Destination';
  DstPath.KeyDown  += (sender, e) ->
    begin
      if e.KeyData = Keys.Up then
        begin
          if DstPath.TextLength > 0 then
            SrcPath.Text := DstPath.Text;
          SrcPath.Focus();
          SrcPath.SelectionLength := 0;
          SrcPath.SelectionStart  := SrcPath.TextLength;
        end;
    end;
  PathsBox.Controls.Add(DstPath);
  
  DstSelect            := new Button();
  DstSelect.Size       := new Size(24, 22);
  DstSelect.Location   := new Point(DstPath.Left+DstPath.Width+1, DstPath.Top-1);
  DstSelect.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
  DstSelect.Image      := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('path.png'));
  DstSelect.ImageAlign := ContentAlignment.MiddleRight;
  DstSelect.TabStop    := false;
  DstSelect.Tag        := DstPath;
  DstSelect.Click      += PathSelectClick;
  PathsBox.Controls.Add(DstSelect);
  {$endregion}
  
  {$region ActionBox}
  ActionBox          := new Panel();
  ActionBox.Size     := new Size(30, PathsBox.Height);
  ActionBox.Location := new Point(PathsBox.Left+PathsBox.Width, PathsBox.Top);
  ActionBox.Anchor   := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right;
  Main.Controls.Add(ActionBox);
  
  StartCompare            := new Button();
  StartCompare.Size       := new Size(24, 22);
  StartCompare.Location   := new Point(2, SrcSelect.Top);
  StartCompare.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
  StartCompare.Image      := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('compare.png'));
  StartCompare.ImageAlign := ContentAlignment.MiddleRight;
  StartCompare.TabStop    := false;
  StartCompare.Click      += StartCompareClick;
  ActionBox.Controls.Add(StartCompare);
  
  ResetCompare            := new Button();
  ResetCompare.Size       := new Size(24, 22);
  ResetCompare.Location   := new Point(2, DstSelect.Top);
  ResetCompare.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
  ResetCompare.Image      := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('reset.png'));
  ResetCompare.ImageAlign := ContentAlignment.MiddleRight;
  ResetCompare.TabStop    := false;
  ResetCompare.Click      += ResetCompareClick;
  ActionBox.Controls.Add(ResetCompare);
  {$endregion}
  
  {$region PathView}
  var ImgList        := new ImageList();
  ImgList.ColorDepth := ColorDepth.Depth32Bit;
  ImgList.ImageSize  := new Size(16,16);
  ImgList.Images.Add('file',   (new Bitmap(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('file.png'))));
  ImgList.Images.Add('folder', (new Bitmap(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('folder.png'))));
  
  PathView                  := new TreeView();
  PathView.Size             := new System.Drawing.Size(PathsBox.Width+ActionBox.Width, Main.ClientSize.Height-(PathsBox.Top+PathsBox.Height+5));
  PathView.Location         := new System.Drawing.Point(PathsBox.Left, PathsBox.Top+PathsBox.Height+1);
  PathView.Anchor           := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right or AnchorStyles.Bottom;
  PathView.ImageList        := ImgList;
  PathView.ItemHeight       := 18;
  PathView.ShowPlusMinus    := true;
  PathView.Scrollable       := true;
  PathView.ShowNodeToolTips := true;
  PathView.TabStop          := false;
  PathView.KeyDown          += (sender, e) -> begin MenuShift := e.Shift; end;
  PathView.MouseClick       += PathViewMouseClick;
  PathView.AfterLabelEdit   += (sender,e ) ->
    begin
      if e.Label <> '' then
        NodeRename(e.Node, e.Label);
      e.CancelEdit := true;
    end;
  Main.Controls.Add(PathView);
  
  NodeMenu        := new ContextMenuStrip();
  NodeMenu.Closed += (sender, e) -> NodeInfoForm.Hide();
  
  var SrcToDst   := new ToolStripMenuItem();
  SrcToDst.Text  := 'Src -> Dst'; 
  SrcToDst.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('copy.png'));
  SrcToDst.Click += (sender, e) -> NodeCopy(true);
  NodeMenu.Items.Add(SrcToDst);
  
  var DstToSrc   := new ToolStripMenuItem();
  DstToSrc.Text  := 'Src <- Dst'; 
  DstToSrc.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('copy.png'));
  DstToSrc.Click += (sender, e) -> NodeCopy(false);
  NodeMenu.Items.Add(DstToSrc);
  
  var SrcDelte   := new ToolStripMenuItem();
  SrcDelte.Text  := 'Src Delete'; 
  SrcDelte.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('delete.png'));
  SrcDelte.Click += (sender, e) -> NodeDelete(Paths.Source);
  NodeMenu.Items.Add(SrcDelte);
  
  var DstDelte   := new ToolStripMenuItem();
  DstDelte.Text  := 'Dst Delete'; 
  DstDelte.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('delete.png'));
  DstDelte.Click += (sender, e) -> NodeDelete(Paths.Destination);
  NodeMenu.Items.Add(DstDelte);
  
  var Rename := new ToolStripMenuItem();
  Rename.Text  := 'Rename'; 
  Rename.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('rename.png'));
  Rename.Click += (sender, e) ->
    begin
      PathView.LabelEdit := true;
      PathView.SelectedNode.BeginEdit();
    end;
  NodeMenu.Items.Add(Rename);
  
  var NodeUpd   := new ToolStripMenuItem();
  NodeUpd.Text  := 'Update'; 
  NodeUpd.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('update.png'));
  NodeUpd.Click += (sender, e) -> Task.Factory.StartNew(() -> NodeUpdate(PathView.SelectedNode));
  NodeMenu.Items.Add(NodeUpd);
  
  var NodeCmp   := new ToolStripMenuItem();
  NodeCmp.Text  := 'Bytewise Compare'; 
  NodeCmp.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('fcmp.png'));
  NodeCmp.Click += (sender, e) ->
    begin
      var paths := Paths.CombinePaths(PathView.SelectedNode.FullPath);
      (new FileCompareForm()).ShowDialog(paths.Source, paths.Destination);
    end;
  NodeMenu.Items.Add(NodeCmp);
  
  var NodeOpenFile   := new ToolStripMenuItem();
  NodeOpenFile.Text  := 'Open'; 
  NodeMenu.Items.Add(NodeOpenFile);
  
  var OpenAsText   := new ToolStripMenuItem();
  OpenAsText.Text  := 'With Notepad++'; 
  OpenAsText.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('text.png'));
  OpenAsText.Click += (sender, e) -> Run(Notepad, '"{0}\{1}"');
  NodeOpenFile.DropDownItems.Add(OpenAsText);
  
  var OpenAsBin   := new ToolStripMenuItem();
  OpenAsBin.Text  := 'With Be.HexEditor'; 
  OpenAsBin.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('hex.png'));
  OpenAsBin.Click += (sender, e) -> Run(HexEditor, '"{0}\{1}"');
  NodeOpenFile.DropDownItems.Add(OpenAsBin);
  
  var OpenParentFolder   := new ToolStripMenuItem();
  OpenParentFolder.Text  := 'Parent Folder in Explorer'; 
  OpenParentFolder.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('path.png'));
  OpenParentFolder.Click += (sender, e) -> Run('explorer.exe', '"{0}\{1}"', true);
  NodeOpenFile.DropDownItems.Add(OpenParentFolder);
  
  var OpenParentFolderCmd   := new ToolStripMenuItem();
  OpenParentFolderCmd.Text  := 'Parent Forlder in Terminal'; 
  OpenParentFolderCmd.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('cmder.png'));
  OpenParentFolderCmd.Click += (sender, e) -> Run(CmderPath, '/start "{0}\{1}"', true);
  NodeOpenFile.DropDownItems.Add(OpenParentFolderCmd);
  
  var OpenFolder   := new ToolStripMenuItem();
  OpenFolder.Text  := 'in Explorer'; 
  OpenFolder.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('path.png'));
  OpenFolder.Click += (sender, e) -> Run('explorer.exe', '"{0}\{1}"');
  NodeOpenFile.DropDownItems.Add(OpenFolder);
  
  var OpenFolderCmd   := new ToolStripMenuItem();
  OpenFolderCmd.Text  := 'in Terminal'; 
  OpenFolderCmd.Image := Image.FromStream(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('cmder.png'));
  OpenFolderCmd.Click += (sender, e) -> Run(CmderPath, '/start "{0}\{1}"');
  NodeOpenFile.DropDownItems.Add(OpenFolderCmd);
  {$endregion}
  
  {$region NodeInfoForm}
  NodeInfoForm                 := new Form();
  NodeInfoForm.ClientSize      := new Size(341, 135);
  NodeInfoForm.FormBorderStyle := FormBorderStyle.None;
  NodeInfoForm.ShowIcon        := false;
  NodeInfoForm.ShowInTaskbar   := false;
  NodeInfoForm.Owner           := Main;
  NodeInfoForm.StartPosition   := FormStartPosition.Manual;
  NodeInfoForm.Opacity         := 0.75;
  
  NodeInfoView := new DataGridView();
  NodeInfoView.Size                        := new Size(NodeInfoForm.Width, 135);
  NodeInfoView.Location                    := new Point(0, 0);
  NodeInfoView.ReadOnly                    := true;
  NodeInfoView.GridColor                   := Color.White;
  NodeInfoView.RowHeadersBorderStyle       := DataGridViewHeaderBorderStyle.None;
  NodeInfoView.RowHeadersVisible           := false;
  NodeInfoView.ScrollBars                  := ScrollBars.None;
  NodeInfoView.AllowUserToAddRows          := false;
  NodeInfoView.AllowUserToDeleteRows       := false;
  NodeInfoView.AllowUserToResizeColumns    := false;
  NodeInfoView.AllowUserToResizeRows       := false;
  NodeInfoView.AllowUserToOrderColumns     := false;
  NodeInfoView.AutoSizeRowsMode            := DataGridViewAutoSizeRowsMode.DisplayedCellsExceptHeaders;
  NodeInfoView.ClipboardCopyMode           := DataGridViewClipboardCopyMode.Disable;
  NodeInfoView.ColumnHeadersBorderStyle    := DataGridViewHeaderBorderStyle.Single;
  NodeInfoView.ColumnHeadersHeightSizeMode := DataGridViewColumnHeadersHeightSizeMode.AutoSize;
  NodeInfoForm.Controls.Add(NodeInfoView);
  
  var InfoViewParams        := new DataGridViewTextBoxColumn();
  InfoViewParams.Frozen     := true;
  InfoViewParams.HeaderText := 'Property';
  InfoViewParams.ReadOnly   := true;
  InfoViewParams.Resizable  := DataGridViewTriState.False;
  InfoViewParams.Width      := 55;
  NodeInfoView.Columns.Add(InfoViewParams);
  
  var InfoViewSrc        := new DataGridViewTextBoxColumn();
  InfoViewSrc.HeaderText := 'Source';
  InfoViewSrc.ReadOnly   := true;
  InfoViewSrc.Resizable  := DataGridViewTriState.False;
  InfoViewSrc.Width      := 128;
  InfoViewSrc.HeaderCell.Style.Alignment := DataGridViewContentAlignment.MiddleCenter;
  NodeInfoView.Columns.Add(InfoViewSrc);
  
  var InfoViewDst        := new DataGridViewTextBoxColumn();
  InfoViewDst.HeaderText := 'Destination';
  InfoViewDst.ReadOnly   := true;
  InfoViewDst.Resizable  := DataGridViewTriState.False;
  InfoViewDst.Width      := 128;
  InfoViewDst.HeaderCell.Style.Alignment := DataGridViewContentAlignment.MiddleCenter;
  NodeInfoView.Columns.Add(InfoViewDst);
  {$endregion}
  
  {$region Init}
  begin
    var path := Application.ExecutablePath.Parent() + '\path.h';
    
    if &File.Exists(path) then
      foreach var line in &File.ReadAllLines(path) do
        if line <> '' then
          begin
            var kw := line.Split('=');
            if kw.Length = 2 then
              case kw[0].ToLower() of
                'terminal':  CmderPath := kw[1] + '\Cmder.exe';
                'hexeditor': HexEditor := kw[1] + '\Be.HexEditor.exe';
                'notepad':   Notepad   := kw[1] + '\notepad++.exe';
              end;
          end;
  end;
  {$endregion}
  
  {$region App}
  Application.Run(Main);
  {$endregion}
end.