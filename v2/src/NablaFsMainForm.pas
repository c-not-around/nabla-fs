unit NablaFsMainForm;


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
{$resource res\cmder.png}
{$resource res\text.png}
{$resource res\hex.png}


uses System;
uses System.IO;
uses System.Collections.Generic;
uses System.Threading;
uses System.Threading.Tasks;
uses System.Diagnostics;
uses System.Drawing;
uses System.Windows.Forms;
uses Microsoft.VisualBasic.FileIO;
uses Extensions;
uses FsTwinObjects;
uses FsTreeNodes;
uses ExternalApps;
uses CustomProgressBar;
uses FsNodeInfoForm;


type
  MainForm = class(Form)
    {$region Override}
    protected procedure OnFormClosing(e: FormClosingEventArgs); override;
    begin
      e.Cancel := _TaskInProgress;
    end;
    {$endregion}
    
    {$region Fields}
    private _SrcPath         : TextBox;
    private _DstPath         : TextBox;
    private _SrcSelect       : Button;
    private _DstSelect       : Button;
    private _StartCompare    : Button;
    private _ResetCompare    : Button;
    private _PathView        : TreeView;
    private _NodeMenu        : System.Windows.Forms.ContextMenuStrip;
    private _ProgressBar     : FsProgressBar;
    private _StatusBar       : StatusStrip;
    private _ElapsedInfo     : ToolStripStatusLabel;
    private _RemainingInfo   : ToolStripStatusLabel;
    private _FilesCountInfo  : ToolStripStatusLabel;
    private _StageInfo       : ToolStripStatusLabel;
    
    private _Paths           : TwinPaths;
    private _TotalFilesCount : integer;
    private _TotalFilesWeight: int64;
    private _TotalFilesLocker: object;
    private _ToHashList      : List<FileNode>;
    private _ToHashListCount : integer;
    private _ProgressTimer   : System.Timers.Timer;
    private _StartTime       : DateTime;
    private _FileIndex       : integer;
    private _FileIndexLocker : object;
    private _CompletedCount  : integer;
    private _CompletedWeight : int64;
    private _CompleteLocker  : object;
    private _TaskCancel      : boolean;
    private _TaskInProgress  : boolean;
    private _NodeMenuShift   : boolean;
    private _NodeInfoForm    : NodeInfoForm;
    private _ExternalApps    : ExternalAppPaths;
    {$endregion}
    
    {$region Compare}
    private procedure LoadFolderNode(root: FolderNode; src, dst: string);
    begin
      root.FoldersInfo := new TwinFolderInfo(new DirectoryInfo(src), new DirectoryInfo(dst));
      
      try
        var SrcFolders := Directory.GetDirectories(src);
        var SrcFiles   := Directory.GetFiles(src);
        var DstFolders := Directory.GetDirectories(dst);
        var DstFiles   := Directory.GetFiles(dst);
        
        root.FoldersInfo.SrcFolders += SrcFolders.Length;
        root.FoldersInfo.SrcFiles   += SrcFiles.Length;
        root.FoldersInfo.DstFolders += DstFolders.Length;
        root.FoldersInfo.DstFiles   += DstFiles.Length;
        
        foreach var f: string in SrcFolders do
          begin
            var info              := new DirectoryInfo(f);
            var twin              := dst+'\'+info.Name;
            var node              := new FolderNode(info.Name);
            node.Status           := Directory.Exists(twin) ? CompareResult.None : CompareResult.SourceOnly;
            node.ContextMenuStrip := _NodeMenu;
            root.Nodes.Add(node);
            
            if node.Status = CompareResult.None then
              begin
                node.FoldersInfo := new TwinFolderInfo(info, new DirectoryInfo(twin));
                
                LoadFolderNode(node, f, twin);
              end
            else
              node.FoldersInfo := new TwinFolderInfo(info, nil);
            
            root.FoldersInfo += node.FoldersInfo;
            
            if _TaskCancel then
              exit;
          end;
        
        foreach var f: string in SrcFiles do
          begin
            var info              := new FileInfo(f);
            var twin              := dst+'\'+info.Name;
            var node              := new FileNode(info.Name);
            node.Status           := &File.Exists(twin) ? CompareResult.None : CompareResult.SourceOnly;
            node.ContextMenuStrip := _NodeMenu;
            root.Nodes.Add(node);
            
            if node.Status = CompareResult.None then
              begin
                var twinfo := new FileInfo(twin);
                
                node.FilesInfo := new TwinFileInfo(info, twinfo);
                
                var size := twinfo.Length;
                
                if size = info.Length then
                  begin
                    lock _TotalFilesLocker do
                      begin
                        _TotalFilesCount  += 1;
                        _TotalFilesWeight += size;
                      end;
                    _ToHashList.Add(node);
                  end
                else
                  node.Status := CompareResult.Twins;
                
                root.FoldersInfo.DstBytes += size;
              end
            else
              node.FilesInfo := new TwinFileInfo(info);
            
            root.FoldersInfo.SrcBytes += info.Length;
            
            if _TaskCancel then
              exit;
          end;
        
        foreach var f: string in DstFolders do
          begin
            var info := new DirectoryInfo(f);
            
            if not Directory.Exists(src+'\'+info.Name) then
              begin
                var node              := new FolderNode(info.Name);
                node.Status           := CompareResult.DestinationOnly;
                node.ContextMenuStrip := _NodeMenu;
                node.FoldersInfo      := new TwinFolderInfo(nil, info);
                root.FoldersInfo      += node.FoldersInfo;
                root.Nodes.Add(node);
              end;
            
            if _TaskCancel then
              exit;
          end;
        
        foreach var f: string in DstFiles do
          begin
            var info := new FileInfo(f);
            
            if not &File.Exists(src+'\'+info.Name) then
              begin
                var node                  := new FileNode(info.Name);
                node.Status               := CompareResult.DestinationOnly;
                node.ContextMenuStrip     := _NodeMenu;
                node.FilesInfo            := new TwinFileInfo(nil, info);
                root.FoldersInfo.DstBytes += info.Length;
                root.Nodes.Add(node);
              end;
            
            if _TaskCancel then
              exit;
          end;
      except on ex: Exception do
        begin
          root.Status      := CompareResult.Error;
          root.ToolTipText := ex.Message;
        end;
      end;
    end;
    
    private procedure LoadProgressUpdate();
    begin
      var dt      := DateTime.Now - _StartTime;
      var elapsed := $'Elapsed: {dt.Hours}:{dt.Minutes:d2}:{dt.Seconds:d2}';
      var files   := $'Files: {_TotalFilesCount}';
      
      self.Invoke(() ->
        begin
          _ElapsedInfo.Text    := elapsed;
          _FilesCountInfo.Text := files;
        end
      );
    end;
    
    private procedure CompareProgressUpdate();
    begin
      var dt := DateTime.Now - _StartTime;
      
      var remaininig := 'Remaining: ';
      if _CompletedWeight > 0 then
        begin
          var v  := _CompletedWeight / dt.Ticks;
          var t  := new TimeSpan(Convert.ToInt64((_TotalFilesWeight - _CompletedWeight) / v));
          if (t.TotalSeconds <= 0) and (_CompletedWeight < _TotalFilesWeight) then
            t := new TimeSpan(0, 0, 5);
          remaininig += $'{t.Hours}:{t.Minutes:d2}:{t.Seconds:d2}';
        end
      else
        remaininig += $'-:--:--';
      
      var elapsed := $'Elapsed: {dt.Hours}:{dt.Minutes:d2}:{dt.Seconds:d2}';
      var files   := $'Files: {_CompletedCount}/{_TotalFilesCount}';
      
      self.Invoke(() ->
        begin
          _ProgressBar.Value   := _CompletedWeight;
          _ElapsedInfo.Text    := elapsed;
          _RemainingInfo.Text  := remaininig;
          _FilesCountInfo.Text := files;
        end
      );
    end;
    
    private procedure ProgressTimerLoadElapsed(sender: object; e: System.Timers.ElapsedEventArgs) := LoadProgressUpdate();
    
    private procedure ProgressTimerCompareElapsed(sender: object; e: System.Timers.ElapsedEventArgs) := CompareProgressUpdate();
    
    private function GetNextFileIndex(): integer;
    begin
      lock _FileIndexLocker do
        begin
          if _FileIndex < _ToHashListCount then
            begin
              result     := _FileIndex;
              _FileIndex += 1;
            end
          else
            result := -1;
        end;
    end;
    
    private procedure FileCompareTask();
    begin
      var LogFileName := Thread.CurrentThread.Name;
      
      try
        var index := GetNextFileIndex();
        
        while index <> -1 do
          begin
            var node  := _ToHashList[index];
            var paths := node.FilesInfo.Paths;
            
            var res := -1;
            try
              res := CompareFiles(paths.Source, paths.Destination);
            except on exx: Exception do
              &File.AppendAllText(LogFileName+'_fcmp.log', exx.Message+#13#10);
            end;
            
            node.Status := res = 0 ? CompareResult.Matches : (res = 1 ? CompareResult.Twins : CompareResult.Error);
            
            var dw := (new FileInfo(paths.Source)).Length;
            lock _CompleteLocker do
              begin
                _CompletedCount  += 1;
                _CompletedWeight += dw;
              end;
            
            if _TaskCancel then
              break
            else
              index := GetNextFileIndex();
          end;
      except on ex: Exception do
        &File.AppendAllText(LogFileName+'.log', ex.Message+#13#10);
      end;
    end;
    
    private function SetNodesStatus(root: FolderNode): CompareResult;
    begin
      try
        if (root.Status = CompareResult.SourceOnly) or (root.Status = CompareResult.DestinationOnly) then
          result := CompareResult.Twins
        else
          begin
            result := CompareResult.Matches;
            
            foreach var node: FsNode in root.Nodes do
              begin
                var res := node is FolderNode ? SetNodesStatus(node as FolderNode) : node.Status;
                
                if res <> CompareResult.Matches then
                  result := CompareResult.Twins;
              end;
            
            root.Status := result;
          end;
      except on ex: Exception do
        
      end;
    end;
    
    private procedure FolderCompare(root: FolderNode; paths: TwinPaths; routine: procedure);
    begin
      _TaskInProgress := true;
      _TaskCancel     := false;
      
      _TotalFilesCount  := 0;
      _TotalFilesWeight := 0;
      _ToHashList       := new List<FileNode>();
      
      Invoke(() ->
        begin
          Cursor := Cursors.WaitCursor;
          
          _ResetCompare.Enabled := true;
          
          _ElapsedInfo.Text           := 'Elapsed: 0:00:00';
          _StatusBar.Items[1].Visible := true;
          _RemainingInfo.Visible      := false;
          _StatusBar.Items[3].Visible := false;
          _FilesCountInfo.Text        := 'Files: 0';
          _StatusBar.Items[5].Visible := true;
          _StageInfo.Text             := 'Load directories structure ...';
        end
      );
      
      _StartTime := DateTime.Now;
      _ProgressTimer.Interval := 500.0;
      _ProgressTimer.Elapsed  += ProgressTimerLoadElapsed;
      _ProgressTimer.Enabled  := true;
      _ProgressTimer.Start();
      
      _TotalFilesLocker := new Object();
      
      LoadFolderNode(root, paths.Source, paths.Destination);
      
      _ProgressTimer.Stop();
      _ProgressTimer.Enabled := false;
      _ProgressTimer.Elapsed -= ProgressTimerLoadElapsed;
      
      Invoke(() -> 
        begin
          LoadProgressUpdate();
          Cursor := Cursors.Default;
        end
      );
      
      if (not _TaskCancel) and (_ToHashList.Count > 0) then
        begin
          Invoke(() ->
            begin
              _ProgressBar.Value       := 0;
              _ProgressBar.Maximmum    := _TotalFilesWeight;
              _ProgressBar.Visible     := true;
              _ProgressBar.TextVisible := true;
              _PathView.Height         -= 25;
              
              _RemainingInfo.Visible      := true;
              _StatusBar.Items[3].Visible := true;
              
              _RemainingInfo.Text := 'Remaining: -:--:--';
              _StageInfo.Text     := 'Compare files ...';
            end
          );
          
          _StartTime := DateTime.Now;
          _ProgressTimer.Interval := 1000.0;
          _ProgressTimer.Elapsed  += ProgressTimerCompareElapsed;
          _ProgressTimer.Enabled  := true;
          _ProgressTimer.Start();
          
          _FileIndex       := 0;
          _CompletedCount  := 0;
          _CompletedWeight := 0;
          _ToHashListCount := _ToHashList.Count;
          _CompleteLocker  := new Object();
          _FileIndexLocker := new Object();
          
          var cores   := Math.Min({Environment.ProcessorCount div 2}4, _ToHashListCount);
          var threads := new Thread[cores];
          for var i := 0 to cores-1 do
            begin
              threads[i]      := new Thread(FileCompareTask);
              threads[i].Name := $'thread_{i}';
              threads[i].Start();
            end;
          
          for var i := 0 to cores-1 do
            threads[i].Join();
          
          _ProgressTimer.Stop();
          _ProgressTimer.Enabled := false;
          _ProgressTimer.Elapsed -= ProgressTimerCompareElapsed;
          
          if not _TaskCancel then
            begin
              Invoke(() -> 
                begin
                  CompareProgressUpdate();
                  _StageInfo.Text := 'Mark nodes ...';
                end
              );
              
              SetNodesStatus(root);
              
              if routine <> nil then
                Invoke(() -> routine());
            end;
          
          Invoke(() -> 
            begin
              _ProgressBar.Visible     := false;
              _ProgressBar.TextVisible := false;
              _PathView.Height         += 25;
            end
          );
        end;
      
      Invoke(() -> 
        begin
          _StageInfo.Text := _TaskCancel ? 'Aborted.' : 'Done.';
          
          SetAbility(true);
        end
      );
      
      _TaskCancel     := false;
      _TaskInProgress := false;
    end;
    {$endregion}
    
    {$region Routines}
    private function GetFolderName(path: string): string;
    begin
      var pos := path.LastIndexOf('\');
      result := pos = -1 ? path : path.Substring(pos+1);
    end;
    
    private procedure SetAbility(enable: boolean);
    begin
      _SrcPath.Enabled      := enable;
      _DstPath.Enabled      := enable;
      _SrcSelect.Enabled    := enable;
      _DstSelect.Enabled    := enable;
      _StartCompare.Enabled := enable;
      _ResetCompare.Enabled := enable;
      _PathView.Enabled     := enable;
    end;
    
    private procedure CompareReset();
    begin
      _PathView.Nodes.Clear();
      _NodeInfoForm.Hide();
      
      _ElapsedInfo.Text    := '';
      _RemainingInfo.Text  := '';
      _FilesCountInfo.Text := '';
      _StageInfo.Text      := '';
      
      _StatusBar.Items[1].Visible := false;
      _StatusBar.Items[3].Visible := false;
      _StatusBar.Items[5].Visible := false;
    end;
    
    private procedure UpdateNodesStatusAndInfo(node: FolderNode; span: TwinFolderInfoSpan);
    begin
      if node <> nil then
        begin
          var status := CompareResult.Matches;
          
          for var i := 0 to node.Nodes.Count-1 do
            if (node.Nodes[i] as FsNode).Status <> CompareResult.Matches then
              begin
                status := CompareResult.Twins;
                break;
              end;
          
          node.Status      := status;
          node.FoldersInfo += span;
          
          if node.Level > 0 then
            UpdateNodesStatusAndInfo(node.Parent as FolderNode, span);
        end;
    end;
    
    private procedure LoadFileNode(node: FileNode; paths: TwinPaths);
    begin
      var src := new FileInfo(paths.Source);
      var dst := new FileInfo(paths.Destination);
      
      if src.Exists then
        begin
          if dst.Exists then
            node.Status := src.Length = dst.Length ? CompareResult.None : CompareResult.Twins
          else
            node.Status := CompareResult.SourceOnly;
        end
      else
        node.Status := CompareResult.DestinationOnly;
      
      node.FilesInfo := new TwinFileInfo(src.Exists ? src : nil, dst.Exists ? dst : nil);
      
      if node.Status = CompareResult.None then
        begin
          Invoke(() -> begin Cursor := Cursors.WaitCursor; end);
          
          var res := -1;
          try
            res := CompareFiles(paths.Source, paths.Destination);
          except
            
          end;
          
          node.Status := res = 0 ? CompareResult.Matches : (res = 1 ? CompareResult.Twins : CompareResult.Error);
          
          Invoke(() -> begin Cursor := Cursors.Default; end);
        end;
    end;
    
    private procedure UpdateNode(node: FsNode);
    begin
      var paths  := _Paths + node.RelativePath;
      var parent := node.Parent;
      var index  := -1;
      var root   : FsNode;
      
      if paths.OneOrMoreExists then
        begin
          Invoke(() -> SetAbility(false));
          
          index := parent.Nodes.IndexOf(node);
          
          if node is FileNode then
            begin
              root := new FileNode(node.Text);
              LoadFileNode(root as FileNode, paths);
            end
          else
            begin
              root := new FolderNode(node.Text);
              
              if paths.BothFoldersExists then
                FolderCompare(root as FolderNode, paths, nil)
              else
                begin
                  var src := new DirectoryInfo(paths.Source);
                  var dst := new DirectoryInfo(paths.Destination);
                  
                  root.Status := src.Exists ? CompareResult.SourceOnly : CompareResult.DestinationOnly;
                  (root as FolderNode).FoldersInfo := new TwinFolderInfo(src.Exists ? src : nil, dst.Exists ? dst : nil);
                end;
            end;
          
          root.ContextMenuStrip := _NodeMenu;
        end;
      
      Invoke(() -> 
        begin
          var span := node.InfoSpan;
          
          parent.Nodes.Remove(node);
          
          if index <> -1 then
            parent.Nodes.Insert(index, root);
          
          UpdateNodesStatusAndInfo(parent as FolderNode, span);
          
          SetAbility(true);
        end
      );
    end;
    {$endregion}
    
    {$region NodeMenu}
    private procedure NodeCopyTask(node: FsNode; direct: boolean);
    begin
      var path := (direct ? _Paths : _Paths.Reverse) + node.RelativePath;
      
      try
        if node is FolderNode then
          FileSystem.CopyDirectory(path.Source, path.Destination, UIOption.AllDialogs)
        else
          FileSystem.CopyFile(path.Source, path.Destination, UIOption.AllDialogs);
        
        UpdateNode(node);
      except on ex: Exception do
        Message.Error($'"{path.Source}" copy error to {path.Destination}: {ex.Message}.');
      end;
    end;
    
    private procedure NodeDeleteTask(node: FsNode; destination: boolean);
    begin
      var paths := _Paths + node.RelativePath;
      var path  := destination ? paths.Destination : paths.Source;
      
      try
        if node is FolderNode then
          FileSystem.DeleteDirectory(path, UIOption.AllDialogs, RecycleOption.SendToRecycleBin)
        else
          FileSystem.DeleteFile(path, UIOption.AllDialogs, RecycleOption.SendToRecycleBin);
        
        Invoke(() -> 
          begin
            var span   := node.InfoSpan;
            var parent := node.Parent as FolderNode;
            parent.Nodes.Remove(node);
            UpdateNodesStatusAndInfo(parent, span);
          end
        );
      except on ex: Exception do
        Message.Error($'"{path}" delete error: {ex.Message}.');
      end;
      
      Invoke(() -> begin _PathView.Enabled := true; end);
    end;
    
    private procedure NodeMove(src, dst: string; folder: boolean);
    begin
      try
        if folder then
          FileSystem.MoveDirectory(src, dst)
        else
          FileSystem.MoveFile(src, dst);
      except on ex: Exception do
        Message.Error($'rename "{src}" with "{dst}" error: {ex.Message}.');
      end;
    end;
    
    private procedure NodeRenameTask(node: FsNode; name: string);
    begin
      var OldPaths := _Paths + node.RelativePath;
      var NewPaths := OldPaths.Rename[name];
      
      var f := node is FolderNode;
      var r := node.Status;
      
      if r <> CompareResult.DestinationOnly then
        NodeMove(OldPaths.Source, NewPaths.Source, f);
      
      if r <> CompareResult.SourceOnly then
        NodeMove(OldPaths.Destination, NewPaths.Destination, f);
      
      Invoke(()-> begin node.Text := name; end);
      
      var ParentNodes := node.Parent.Nodes;
      foreach var n: TreeNode in ParentNodes do
        begin
          if (n.Text = name) and (n <> node) then
            begin
              ParentNodes.Remove(n);
              break;
            end;
        end;
      
      UpdateNode(node);
      
      Invoke(() -> begin _PathView.LabelEdit := false; end);
    end;
    
    private procedure NodeCopy(direct: boolean);
    begin
      _PathView.Enabled := false;
      Task.Factory.StartNew(() -> begin NodeCopyTask(_PathView.SelectedNode as FsNode, direct); end);
    end;
    
    private procedure NodeDelete(destination: boolean);
    begin
      _PathView.Enabled := false;
      Task.Factory.StartNew(() -> begin NodeDeleteTask(_PathView.SelectedNode as FsNode, destination); end);
    end;
    
    private procedure NodeRename(node: FsNode; name: string);
    begin
      _PathView.Enabled := false;
      Task.Factory.StartNew(() -> begin NodeRenameTask(node, name); end);
    end;
    
    private procedure NodeUpdate();
    begin
      _PathView.Enabled := false;
      Task.Factory.StartNew(() -> UpdateNode(_PathView.SelectedNode as FsNode));
    end;
    
    private procedure WinRun(fname, args: string);
    begin
      try
        Process.Start(fname, args);
      except on ex: Exception do
        Message.Error($'"{fname} {args}" execution error: {ex.Message}');
      end;
    end;
    
    private procedure Run(app: string; param: string := ''; parent: boolean := false);
    begin
      var node  := _PathView.SelectedNode as FsNode;
      var stat  := node.Status;
      var paths := _Paths + node.RelativePath;
      
      if parent then
        paths := paths.Parents;
      
      if stat <> CompareResult.DestinationOnly then
        WinRun(app, $'{param} "{paths.Source}"');
      if stat <> CompareResult.SourceOnly then
        WinRun(app, $'{param} "{paths.Destination}"');
    end;
    {$endregion}
    
    {$region Handlers}
    private procedure PathSelectClick(sender: object; e: EventArgs);
    begin
      var tb := (sender as Button).Tag as TextBox;
      
      var dialog                 := new FolderBrowserDialog();
      dialog.ShowNewFolderButton := false;
      dialog.Description         := 'Select ' + tb.Name;
      
      if dialog.ShowDialog() = System.Windows.Forms.DialogResult.OK then
        tb.Text := dialog.SelectedPath;
      
      dialog.Dispose();
    end;
    
    private procedure StartCompareClick(sender: object; e: EventArgs);
    begin
      _Paths := new TwinPaths(_SrcPath.Text.TrimEnd('\'), _DstPath.Text.TrimEnd('\'));
      
      if _Paths.Source = _Paths.Destination then
        begin
          Message.Error('Source = Destination.');
          exit;
        end;
      
      if not Directory.Exists(_Paths.Source) then
        begin
          Message.Error('Incorrect source path.');
          exit;
        end;
      
      if not Directory.Exists(_Paths.Destination) then
        begin
          Message.Error('Incorrect destination path.');
          exit;
        end;
      
      SetAbility(false);
      
      CompareReset();
      
      var root := new FolderNode(GetFolderName(_Paths.Source)+'|'+GetFolderName(_Paths.Destination));
      Task.Factory.StartNew(() -> FolderCompare(root, _Paths, () -> _PathView.Nodes.Add(root)));
    end;
    
    private procedure ResetCompareClick(sender: object; e: EventArgs);
    begin
      if _TaskInProgress then
        begin
          Invoke(() -> begin _StageInfo.Text := 'Canceling ...'; end);
          _ResetCompare.Enabled := false;
          _TaskCancel           := true;
        end
      else
        CompareReset();
    end;
    
    private procedure PathViewMouseClick(sender: object; e: MouseEventArgs);
    begin
      if _PathView.SelectedNode <> nil then
        _PathView.SelectedNode.BackColor := _PathView.BackColor;
      
      var node := _PathView.GetNodeAt(e.Location) as FsNode;
      
      if e.Button = System.Windows.Forms.MouseButtons.Right then
        begin
          node.BackColor         := Color.LightGray;
          _PathView.SelectedNode := node;
          
          if (node <> nil) and (node.Level > 0) then
            begin
              var r := node.Status;
              var f := node is FileNode;
              
              _NodeMenu.Items[0].Enabled := _NodeMenuShift or (r = CompareResult.Twins) or (r = CompareResult.SourceOnly);
              _NodeMenu.Items[1].Enabled := _NodeMenuShift or (r = CompareResult.Twins) or (r = CompareResult.DestinationOnly);
              _NodeMenu.Items[2].Enabled := _NodeMenuShift or (r = CompareResult.SourceOnly);
              _NodeMenu.Items[3].Enabled := _NodeMenuShift or (r = CompareResult.DestinationOnly);
              
              var nmo := (_NodeMenu.Items[6] as ToolStripMenuItem).DropDownItems;
              
              nmo[0].Visible := f;
              nmo[1].Visible := f;
              nmo[2].Visible := f;
              nmo[3].Visible := f;
              nmo[4].Visible := not f;
              nmo[5].Visible := not f;
              
              _NodeInfoForm.Location := Location + _PathView.Location + e.Location + (new Point(_NodeMenu.Size.Width + 10, 33));
              _NodeInfoForm.Show(node);
            end
          else
            _NodeInfoForm.Hide();
        end
      else
        _NodeInfoForm.Hide();
    end;
    {$endregion}
    
    {$region Ctors}
    public constructor ();
    begin
      {$region MainForm}
      ClientSize    := new System.Drawing.Size(460, 520);
      MinimumSize   := Size;
      Icon          := Resources.Icon('icon.ico');
      StartPosition := FormStartPosition.CenterScreen;
      Text          := 'Nabla•Fs';
      {$endregion}
      
      {$region SrcPath}
      var _SourceDesc       := new &Label();
      _SourceDesc.Size      := new System.Drawing.Size(65, 15);
      _SourceDesc.Location  := new Point(0, 10);
      _SourceDesc.TextAlign := ContentAlignment.MiddleRight;
      _SourceDesc.TabStop   := false;
      _SourceDesc.Text      := 'Source:';
      Controls.Add(_SourceDesc);
      
      _SrcPath          := new TextBox();
      _SrcPath.Size     := new System.Drawing.Size(335, 15);
      _SrcPath.Location := new Point(_SourceDesc.Left+_SourceDesc.Width+1, _SourceDesc.Top-2);
      _SrcPath.Anchor   := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right;
      _SrcPath.Name     := 'Source';
      _SrcPath.KeyDown  += (sender, e) ->
        begin
          if e.KeyData = Keys.Down then
            begin
              if _SrcPath.TextLength > 0 then
                _DstPath.Text := _SrcPath.Text;
              _DstPath.Focus();
              _DstPath.SelectionLength := 0;
              _DstPath.SelectionStart  := _DstPath.TextLength;
            end;
        end;
      Controls.Add(_SrcPath);
      
      _SrcSelect            := new Button();
      _SrcSelect.Size       := new System.Drawing.Size(24, 22);
      _SrcSelect.Location   := new Point(_SrcPath.Left+_SrcPath.Width+1, _SrcPath.Top-1);
      _SrcSelect.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
      _SrcSelect.Image      := Resources.Image('path.png');
      _SrcSelect.ImageAlign := ContentAlignment.MiddleRight;
      _SrcSelect.TabStop    := false;
      _SrcSelect.Tag        := _SrcPath;
      _SrcSelect.Click      += PathSelectClick;
      Controls.Add(_SrcSelect);
      {$endregion}
      
      {$region DstPath}
      var _DestinationDesc       := new &Label();
      _DestinationDesc.Size      := new System.Drawing.Size(_SourceDesc.Width, _SourceDesc.Height);
      _DestinationDesc.Location  := new Point(_SourceDesc.Left, _SourceDesc.Top+22);
      _DestinationDesc.TextAlign := ContentAlignment.MiddleRight;
      _DestinationDesc.Text      := 'Destination:';
      _DestinationDesc.TabStop   := false;
      Controls.Add(_DestinationDesc);
      
      _DstPath          := new TextBox();
      _DstPath.Size     := new System.Drawing.Size(_SrcPath.Width, _SrcPath.Height);
      _DstPath.Location := new Point(_DestinationDesc.Left+_DestinationDesc.Width+1, _DestinationDesc.Top-2);
      _DstPath.Anchor   := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right;
      _DstPath.Name     := 'Destination';
      _DstPath.KeyDown  += (sender, e) ->
        begin
          if e.KeyData = Keys.Up then
            begin
              if _DstPath.TextLength > 0 then
                _SrcPath.Text := _DstPath.Text;
              _SrcPath.Focus();
              _SrcPath.SelectionLength := 0;
              _SrcPath.SelectionStart  := _SrcPath.TextLength;
            end;
        end;
      Controls.Add(_DstPath);
      
      _DstSelect            := new Button();
      _DstSelect.Size       := new System.Drawing.Size(_SrcSelect.Width, _SrcSelect.Height);
      _DstSelect.Location   := new Point(_DstPath.Left+_DstPath.Width+1, _DstPath.Top-1);
      _DstSelect.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
      _DstSelect.Image      := Resources.Image('path.png');
      _DstSelect.ImageAlign := ContentAlignment.MiddleRight;
      _DstSelect.TabStop    := false;
      _DstSelect.Tag        := _DstPath;
      _DstSelect.Click      += PathSelectClick;
      Controls.Add(_DstSelect);
      {$endregion}
      
      {$region Action}
      _StartCompare            := new Button();
      _StartCompare.Size       := new System.Drawing.Size(_SrcSelect.Width, _SrcSelect.Height);
      _StartCompare.Location   := new Point(_SrcSelect.Left+_SrcSelect.Width+5, _SrcSelect.Top);
      _StartCompare.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
      _StartCompare.Image      := Resources.Image('compare.png');
      _StartCompare.ImageAlign := ContentAlignment.MiddleRight;
      _StartCompare.TabStop    := false;
      _StartCompare.Click      += StartCompareClick;
      Controls.Add(_StartCompare);
      
      _ResetCompare            := new Button();
      _ResetCompare.Size       := new System.Drawing.Size(_DstSelect.Width, _DstSelect.Height);
      _ResetCompare.Location   := new Point(_StartCompare.Left, _DstSelect.Top);
      _ResetCompare.Anchor     := AnchorStyles.Top or AnchorStyles.Right;
      _ResetCompare.Image      := Resources.Image('reset.png');
      _ResetCompare.ImageAlign := ContentAlignment.MiddleRight;
      _ResetCompare.TabStop    := false;
      _ResetCompare.Click      += ResetCompareClick;
      Controls.Add(_ResetCompare);
      {$endregion}
      
      {$region PathView}
      var _ImgList        := new ImageList();
      _ImgList.ColorDepth := ColorDepth.Depth32Bit;
      _ImgList.ImageSize  := new System.Drawing.Size(16, 16);
      _ImgList.Images.Add('file',   Resources.Image('file.png'));
      _ImgList.Images.Add('folder', Resources.Image('folder.png'));
      
      _PathView                  := new TreeView();
      _PathView.Location         := new Point(5, _DstPath.Top+_DstPath.Height+5);
      _PathView.Size             := new System.Drawing.Size(ClientSize.Width-2*5, ClientSize.Height-_PathView.Top-5-20-5-22);
      _PathView.Anchor           := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right or AnchorStyles.Bottom;
      _PathView.ImageList        := _ImgList;
      _PathView.ItemHeight       := 18;
      _PathView.ShowPlusMinus    := true;
      _PathView.Scrollable       := true;
      _PathView.ShowNodeToolTips := true;
      _PathView.TabStop          := false;
      _PathView.KeyDown          += (sender, e) -> begin _NodeMenuShift := e.Shift; end;
      _PathView.MouseClick       += PathViewMouseClick;
      _PathView.AfterLabelEdit   += (sender, e) ->
        begin
          if e.Label <> '' then
            NodeRename(e.Node as FsNode, e.Label);
          e.CancelEdit := true;
        end;
      Controls.Add(_PathView);
      {$endregion}
      
      {$region NodeMenu}
      _NodeMenu := new System.Windows.Forms.ContextMenuStrip();
      _NodeMenu.Closed += (sender, e) -> begin _NodeInfoForm.Hide(); end;
      
      var _SrcToDst   := new ToolStripMenuItem();
      _SrcToDst.Text  := 'Src -> Dst'; 
      _SrcToDst.Image := Resources.Image('copy.png');
      _SrcToDst.Click += (sender, e) -> NodeCopy(true);
      _NodeMenu.Items.Add(_SrcToDst);
      
      var _DstToSrc   := new ToolStripMenuItem();
      _DstToSrc.Text  := 'Src <- Dst'; 
      _DstToSrc.Image := Resources.Image('copy.png');
      _DstToSrc.Click += (sender, e) -> NodeCopy(false);
      _NodeMenu.Items.Add(_DstToSrc);
      
      var _SrcDelte   := new ToolStripMenuItem();
      _SrcDelte.Text  := 'Src Delete'; 
      _SrcDelte.Image := Resources.Image('delete.png');
      _SrcDelte.Click += (sender, e) -> NodeDelete(false);
      _NodeMenu.Items.Add(_SrcDelte);
      
      var _DstDelte   := new ToolStripMenuItem();
      _DstDelte.Text  := 'Dst Delete'; 
      _DstDelte.Image := Resources.Image('delete.png');
      _DstDelte.Click += (sender, e) -> NodeDelete(true);
      _NodeMenu.Items.Add(_DstDelte);
      
      var _NodeRename := new ToolStripMenuItem();
      _NodeRename.Text  := 'Rename'; 
      _NodeRename.Image := Resources.Image('rename.png');
      _NodeRename.Click += (sender, e) ->
        begin
          _PathView.LabelEdit := true;
          _PathView.SelectedNode.BeginEdit();
        end;
      _NodeMenu.Items.Add(_NodeRename);
      
      var _NodeUpdate   := new ToolStripMenuItem();
      _NodeUpdate.Text  := 'Update'; 
      _NodeUpdate.Image := Resources.Image('update.png');
      _NodeUpdate.Click += (sender, e) -> NodeUpdate();
      _NodeMenu.Items.Add(_NodeUpdate);
      
      var _NodeOpenFile   := new ToolStripMenuItem();
      _NodeOpenFile.Text  := 'Open'; 
      _NodeMenu.Items.Add(_NodeOpenFile);
      
      var _OpenAsText   := new ToolStripMenuItem();
      _OpenAsText.Text  := 'With Notepad++'; 
      _OpenAsText.Image := Resources.Image('text.png');
      _OpenAsText.Click += (sender, e) -> Run(_ExternalApps.AppPath['notepad']);
      _NodeOpenFile.DropDownItems.Add(_OpenAsText);
      
      var _OpenAsBin   := new ToolStripMenuItem();
      _OpenAsBin.Text  := 'With Be.HexEditor'; 
      _OpenAsBin.Image := Resources.Image('hex.png');
      _OpenAsBin.Click += (sender, e) -> Run(_ExternalApps.AppPath['hexeditor']);
      _NodeOpenFile.DropDownItems.Add(_OpenAsBin);
      
      var _OpenParentFolder   := new ToolStripMenuItem();
      _OpenParentFolder.Text  := 'Parent Folder in Explorer'; 
      _OpenParentFolder.Image := Resources.Image('path.png');
      _OpenParentFolder.Click += (sender, e) -> Run('explorer.exe', '', true);
      _NodeOpenFile.DropDownItems.Add(_OpenParentFolder);
      
      var _OpenParentFolderCmd   := new ToolStripMenuItem();
      _OpenParentFolderCmd.Text  := 'Parent Forlder in Terminal'; 
      _OpenParentFolderCmd.Image := Resources.Image('cmder.png');
      _OpenParentFolderCmd.Click += (sender, e) -> Run(_ExternalApps.AppPath['terminal'], '/start', true);
      _NodeOpenFile.DropDownItems.Add(_OpenParentFolderCmd);
      
      var _OpenFolder   := new ToolStripMenuItem();
      _OpenFolder.Text  := 'in Explorer'; 
      _OpenFolder.Image := Resources.Image('path.png');
      _OpenFolder.Click += (sender, e) -> Run('explorer.exe');
      _NodeOpenFile.DropDownItems.Add(_OpenFolder);
      
      var _OpenFolderCmd   := new ToolStripMenuItem();
      _OpenFolderCmd.Text  := 'in Terminal'; 
      _OpenFolderCmd.Image := Resources.Image('cmder.png');
      _OpenFolderCmd.Click += (sender, e) -> Run(_ExternalApps.AppPath['terminal'], '/start');
      _NodeOpenFile.DropDownItems.Add(_OpenFolderCmd);
      {$endregion}
      
      {$region ProgressBar}
      _ProgressBar          := new FsProgressBar();
      _ProgressBar.Location := new Point(_PathView.Left, _PathView.Top+_PathView.Height+5);
      _ProgressBar.Size     := new System.Drawing.Size(_PathView.Width, 20);
      _ProgressBar.Anchor   := AnchorStyles.Left or AnchorStyles.Right or AnchorStyles.Bottom;
      Controls.Add(_ProgressBar);
      {$endregion}
      
      {$region StatusBar}
      _StatusBar             := new StatusStrip();
      _StatusBar.Dock        := DockStyle.Bottom;
      _StatusBar.SizingGrip  := false;
      _StatusBar.LayoutStyle := ToolStripLayoutStyle.HorizontalStackWithOverflow;
      Controls.Add(_StatusBar);
      
      _ElapsedInfo              := new ToolStripStatusLabel();
      _ElapsedInfo.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _ElapsedInfo.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Regular);
      _ElapsedInfo.Alignment    := ToolStripItemAlignment.Left;
      _ElapsedInfo.TextAlign    := ContentAlignment.MiddleLeft;
      _StatusBar.Items.Add(_ElapsedInfo);
      
      var _Sep1Info          := new ToolStripStatusLabel();
      _Sep1Info.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _Sep1Info.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Bold);
      _Sep1Info.Alignment    := ToolStripItemAlignment.Left;
      _Sep1Info.TextAlign    := ContentAlignment.MiddleCenter;
      _Sep1Info.ForeColor    := Color.Gray;
      _Sep1Info.Text         := '|';
      _StatusBar.Items.Add(_Sep1Info);
      
      _RemainingInfo              := new ToolStripStatusLabel();
      _RemainingInfo.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _RemainingInfo.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Regular);
      _RemainingInfo.Alignment    := ToolStripItemAlignment.Left;
      _RemainingInfo.TextAlign    := ContentAlignment.MiddleLeft;
      _StatusBar.Items.Add(_RemainingInfo);
      
      var _Sep2Info          := new ToolStripStatusLabel();
      _Sep2Info.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _Sep2Info.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Bold);
      _Sep2Info.Alignment    := ToolStripItemAlignment.Left;
      _Sep2Info.TextAlign    := ContentAlignment.MiddleCenter;
      _Sep2Info.ForeColor    := Color.Gray;
      _Sep2Info.Text         := '|';
      _StatusBar.Items.Add(_Sep2Info);
      
      _FilesCountInfo              := new ToolStripStatusLabel();
      _FilesCountInfo.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _FilesCountInfo.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Regular);
      _FilesCountInfo.Alignment    := ToolStripItemAlignment.Left;
      _FilesCountInfo.TextAlign    := ContentAlignment.MiddleLeft;
      _StatusBar.Items.Add(_FilesCountInfo);
      
      var _Sep3Info          := new ToolStripStatusLabel();
      _Sep3Info.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _Sep3Info.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Bold);
      _Sep3Info.Alignment    := ToolStripItemAlignment.Left;
      _Sep3Info.TextAlign    := ContentAlignment.MiddleCenter;
      _Sep3Info.ForeColor    := Color.Gray;
      _Sep3Info.Text         := '|';
      _StatusBar.Items.Add(_Sep3Info);
      
      _StageInfo              := new ToolStripStatusLabel();
      _StageInfo.DisplayStyle := ToolStripItemDisplayStyle.Text;
      _StageInfo.Font         := new System.Drawing.Font('Segoe UI', 9.0, System.Drawing.FontStyle.Regular);
      _StageInfo.Alignment    := ToolStripItemAlignment.Left;
      _StageInfo.TextAlign    := ContentAlignment.MiddleLeft;
      _StatusBar.Items.Add(_StageInfo);
      {$endregion}
      
      {$region Init}
      _ProgressBar.Visible := false;
      _PathView.Height     += 25;
      
      _StatusBar.Items[1].Visible := false;
      _StatusBar.Items[3].Visible := false;
      _StatusBar.Items[5].Visible := false;
      
      _ProgressTimer         := new System.Timers.Timer();
      _ProgressTimer.Enabled := false;
      
      _NodeInfoForm := new NodeInfoForm(self);
      
      var path := Application.ExecutablePath;
      path := path.Substring(0, path.LastIndexOf('\') + 1) + 'path.h';
      _ExternalApps := new ExternalAppPaths(path);
      
      _SrcPath.Text := 'E:\Downloads\Utilits1';
      _DstPath.Text := 'E:\Downloads\Utilits2';
      {$endregion}
    end;
    {$endregion}
  end;


end.