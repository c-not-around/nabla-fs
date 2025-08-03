using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.VisualBasic.FileIO;


namespace NablaFs
{
    public partial class MainForm : Form
    {
        #region Fields
        private          TwinsPath    _Path;
        private          InfoTimer    _ProgressTimer;
        private readonly Settings     _Settings;
        private readonly NodeInfoForm _NodeInfoForm;

        private int    _TotalFilesCount;
        private long   _TotalFilesWeight;
        private int    _ToCompareCount;
        private int    _FileIndex;
        private object _FileIndexLocker;
        private int    _CompletedCount;
        private long   _CompletedWeight;
        private bool   _TaskCancel;
        private bool   _TaskInProgress;
        private bool   _NodeMenuShift;
        #endregion

        #region Override
        protected override void OnFormClosing(FormClosingEventArgs e) => e.Cancel = _TaskInProgress;
        #endregion

        #region Ctors
        public MainForm()
        {
            InitializeComponent();

            _SrcDesc.TabStop      = false;
            _SrcPath.Tag          = "Source";
            _SrcSelect.TabStop    = false;
            _SrcSelect.Tag        = _SrcPath;
            _DstDesc.TabStop      = false;
            _DstPath.Tag          = "Destination";
            _DstSelect.TabStop    = false;
            _DstSelect.Tag        = _DstPath;
            _StartCompare.TabStop = false;
            _ResetCompare.TabStop = false;
            _PathView.TabStop     = false;

            _ProgressBar.Visible = false;
            _PathView.Height    += 23;

            _Sep1Info.Visible = false;
            _Sep2Info.Visible = false;
            _Sep3Info.Visible = false;

            _NodeInfoForm = new NodeInfoForm(this);

            _Settings = Settings.Load(Application.StartupPath + "settings.json");
        }
        #endregion

        #region Compare
        private void LoadProgressUpdate(TimeSpan dt)
        {
            string elapsed = $"Elapsed: {dt.Hours}:{dt.Minutes:d2}:{dt.Seconds:d2}";
            string files   = $"Files: {_TotalFilesCount}";

            Invoke((MethodInvoker)(() =>
            {
                _ElapsedInfo.Text = elapsed;
                _FilesInfo.Text   = files;
            }));
        }

        private void CompareProgressUpdate(TimeSpan dt)
        {
            int  count  = _CompletedCount;
            long weight = _CompletedWeight;

            string remaininig = "Remaining: ";
            if (weight > 0)
            {
                double   v = (double)weight / dt.Ticks;
                TimeSpan t = new(Convert.ToInt64((_TotalFilesWeight - weight) / v));
                if (t.TotalSeconds < 1 && weight < _TotalFilesWeight)
                {
                    t = new TimeSpan(0, 0, 1);
                }
                remaininig += $"{t.Hours}:{t.Minutes:d2}:{t.Seconds:d2}";
            }
            else
            {
                remaininig += "-:--:--";
            }
            
            string elapsed = $"Elapsed: {dt.Hours}:{dt.Minutes:d2}:{dt.Seconds:d2}";
            string files   = $"Files: {count}/{_TotalFilesCount}";

            Invoke((MethodInvoker)(() =>
            {
                _ProgressBar.Value   = weight;
                _ElapsedInfo.Text    = elapsed;
                _RemainingInfo.Text  = remaininig;
                _FilesInfo.Text      = files;
            }));
        }

        private void LoadFolderNode(FolderNode root, string src, string dst, List<FileNode> list)
        {
            root.FolderInfo = new TwinsFolderInfo(new DirectoryInfo(src), new DirectoryInfo(dst));

            try
            {
                string[] SrcFolders = Directory.GetDirectories(src);
                string[] SrcFiles   = Directory.GetFiles(src);
                string[] DstFolders = Directory.GetDirectories(dst);
                string[] DstFiles   = Directory.GetFiles(dst);

                root.FolderInfo.SrcFolders += SrcFolders.Length;
                root.FolderInfo.SrcFiles   += SrcFiles.Length;
                root.FolderInfo.DstFolders += DstFolders.Length;
                root.FolderInfo.DstFiles   += DstFiles.Length;

                foreach (string folder in SrcFolders)
                {
                    DirectoryInfo info = new(folder);
                    string        twin = dst + @"\" + info.Name;
                    FolderNode    node = new(info.Name)
                    {
                        Status           = Directory.Exists(twin) ? TwinsStatus.None : TwinsStatus.SrcOnly,
                        ContextMenuStrip = _NodeMenu
                    };
                    root.Nodes.Add(node);

                    if (node.Status == TwinsStatus.None)
                    {
                        node.FolderInfo = new TwinsFolderInfo(info, new DirectoryInfo(twin));

                        LoadFolderNode(node, folder, twin, list);
                    }
                    else
                    {
                        node.FolderInfo = new TwinsFolderInfo(info, null);
                    }
                    
                    root.FolderInfo += node.FolderInfo;

                    if (_TaskCancel)
                    {
                        return;
                    }
                }

                foreach (string file in SrcFiles)
                {
                    FileInfo info = new(file);
                    string   twin = dst + @"\" + info.Name;
                    FileNode node = new(info.Name)
                    {
                        Status           = File.Exists(twin) ? TwinsStatus.None : TwinsStatus.SrcOnly,
                        ContextMenuStrip = _NodeMenu
                    };
                    root.Nodes.Add(node);

                    if (node.Status == TwinsStatus.None)
                    {
                        FileInfo twinfo = new(twin);

                        node.FileInfo = new TwinsFileInfo(info, twinfo);

                        long size = twinfo.Length;

                        if (size == info.Length)
                        {
                            lock (_ProgressTimer.Locker)
                            {
                                _TotalFilesCount  += 1;
                                _TotalFilesWeight += size;
                            }

                            list.Add(node);
                        }
                        else
                        {
                            node.Status = TwinsStatus.Twins;
                        }

                        root.FolderInfo.DstBytes += size;
                    }
                    else
                    {
                        node.FileInfo = new TwinsFileInfo(info);
                    }

                    root.FolderInfo.SrcBytes += info.Length;

                    if (_TaskCancel)
                    {
                        return;
                    }
                }

                foreach (string folder in DstFolders)
                {
                    DirectoryInfo info = new(folder);

                    if (!Directory.Exists(src + @"\" + info.Name))
                    {
                        FolderNode node = new(info.Name)
                        {
                            Status           = TwinsStatus.DstOnly,
                            ContextMenuStrip = _NodeMenu,
                            FolderInfo       = new TwinsFolderInfo(null, info)
                        };
                        root.FolderInfo += node.FolderInfo;
                        root.Nodes.Add(node);
                    }

                    if (_TaskCancel)
                    {
                        return;
                    }
                }

                foreach (string file in DstFiles)
                {
                    FileInfo info = new(file);

                    if (!File.Exists(src + @"\" + info.Name))
                    {
                        FileNode node = new(info.Name)
                        {
                            Status           = TwinsStatus.DstOnly,
                            ContextMenuStrip = _NodeMenu,
                            FileInfo         = new TwinsFileInfo(null, info)
                        };
                        root.FolderInfo.DstBytes += info.Length;
                        root.Nodes.Add(node);
                    }

                    if (_TaskCancel)
                    {
                        return;
                    }
                }
            }
            catch (Exception ex)
            {
                root.Status      = TwinsStatus.Error;
                root.ToolTipText = ex.Message;
            }
        }

        private static int ReadChunk(byte[] chunk, string fname, long offset, int size)
        {
            int result = 0;

            FileStream? data = null;
            try
            {
                data          = File.OpenRead(fname);
                data.Position = offset;
                result = data.Read(chunk, 0, size);
            }
            catch (Exception ex)
            {
                result = -1;
                File.AppendAllText(Thread.CurrentThread.Name?.ToString()+".log", $"\"{fname}\" read error: {ex.Message}\r\n");
            }
            finally
            {
                data?.Dispose();
            } 

            return result;
        }

        private TwinsStatus CompareFile(TwinsPath path, int ChunkSize)
        {
            try
            {
                long length = (new FileInfo(path.Source)).Length;

                if (length <= ChunkSize)
                {
                    byte[] SrcChunk = new byte[length];
                    byte[] DstChunk = new byte[length];

                    TwinsStatus result = TwinsStatus.Error;

                    if (ReadChunk(SrcChunk, path.Source,      0, (int)length) == length &&
                        ReadChunk(DstChunk, path.Destination, 0, (int)length) == length)
                    {
                        result = FsCompare.Compare(SrcChunk, DstChunk, (int)length) ? TwinsStatus.Match : TwinsStatus.Twins;
                    }

                    lock (_ProgressTimer.Locker)
                    {
                        _CompletedWeight += length;
                    }

                    return result;
                }
                else
                {
                    byte[] SrcChunk0 = new byte[ChunkSize];
                    byte[] DstChunk0 = new byte[ChunkSize];
                    byte[] SrcChunk1 = new byte[ChunkSize];
                    byte[] DstChunk1 = new byte[ChunkSize];

                    long pos    = 0;
                    bool result = true;
                    int  count  = 0;
                    int  odd    = 0;

                    Thread? CompareTask = null;

                    while (pos < length)
                    {
                        byte[] SrcChunk = odd == 0 ? SrcChunk0 : SrcChunk1;
                        byte[] DstChunk = odd == 0 ? DstChunk0 : DstChunk1;

                        int size   = (int)Math.Min(ChunkSize, length - pos);
                        int count1 = ReadChunk(SrcChunk, path.Source,      pos, size);
                        int count2 = ReadChunk(DstChunk, path.Destination, pos, size);

                        CompareTask?.Join();

                        if (!result || count1 < 0 || count2 < 0 || _TaskCancel)
                        {
                            long dw = length - pos;
                            lock (_ProgressTimer.Locker)
                            {
                                _CompletedWeight += dw;
                            }

                            break;
                        }

                        count = Math.Min(count1, count2);

                        CompareTask = new Thread(() =>
                        {
                            result = FsCompare.Compare(SrcChunk, DstChunk, count);

                            lock (_ProgressTimer.Locker)
                            {
                                _CompletedWeight += count;
                            }
                        });
                        CompareTask.Start();

                        pos += count;
                        odd ^= 0x01;
                    }

                    CompareTask?.Join();

                    return result ? TwinsStatus.Match : TwinsStatus.Twins;
                }
            }
            catch
            {
                
            }

            return TwinsStatus.Error;
        }

        private void FileCompareTask(Func<FileNode?> GetNextFileNode, int ChunkSize)
        {
            try
            {
                FileNode? node = GetNextFileNode();

                while (node != null) 
                {
                    node.Status = CompareFile(node.FileInfo.Path, ChunkSize);

                    lock (_ProgressTimer.Locker)
                    {
                        _CompletedCount += 1;
                    }

                    node = GetNextFileNode();
                }
            }
            catch (Exception ex)
            {
                File.AppendAllText(Thread.CurrentThread.Name + ".log", ex.Message + "\r\n");
            }
        }

        private static TwinsStatus SetNodesStatus(FolderNode root)
        {
            TwinsStatus result = TwinsStatus.Error;

            try
            {
                if (root.Status == TwinsStatus.None)
                {
                    result = TwinsStatus.Match;

                    foreach (FsNode node in root.Nodes)
                    {
                        TwinsStatus status = node is FolderNode folder ? SetNodesStatus(folder) : node.Status;

                        if (status != TwinsStatus.Match)
                        {
                            result = TwinsStatus.Twins;
                        }  
                    }

                    root.Status = result;
                }
                else
                {
                    result = TwinsStatus.Twins;
                }
            }
            catch
            {

            }

            return result;
        }

        private void FolderCompare(FolderNode root, TwinsPath path, Action? routine)
        {
            _TaskInProgress = true;
            _TaskCancel     = false;

            Invoke((MethodInvoker)(() =>
            {
                Cursor = Cursors.WaitCursor;
                _ResetCompare.Enabled = true;
            }));

            _TotalFilesCount  = 0;
            _TotalFilesWeight = 0;
            _ProgressTimer = new InfoTimer();

            Invoke((MethodInvoker)(() =>
            {
                _ElapsedInfo.Text      = "Elapsed: 0:00:00";
                _Sep1Info.Visible      = true;
                _RemainingInfo.Visible = false;
                _Sep2Info.Visible      = false;
                _FilesInfo.Text        = "Files: 0";
                _Sep3Info.Visible      = true;
                _StageInfo.Text        = "Load directories structure ...";
            }));

            _ProgressTimer.Start(500, LoadProgressUpdate);
            List<FileNode> ToCompare = [];
            LoadFolderNode(root, path.Source, path.Destination, ToCompare);
            _ProgressTimer.Stop();

            Invoke((MethodInvoker)(() => Cursor = Cursors.Default ));
            
            if (!_TaskCancel && ToCompare.Count > 0)
            {
                _CompletedCount  = 0;
                _CompletedWeight = 0;
                _ToCompareCount  = ToCompare.Count;
                _FileIndex       = 0;
                _FileIndexLocker = new object();

                Invoke((MethodInvoker)(() =>
                {
                    _ProgressBar.Value       = 0;
                    _ProgressBar.Maximmum    = _TotalFilesWeight;
                    _ProgressBar.Visible     = true;
                    _ProgressBar.TextVisible = true;
                    _PathView.Height        -= 23;

                    _RemainingInfo.Visible = true;
                    _Sep2Info.Visible      = true;
                    _RemainingInfo.Text    = "Remaining: -:--:--";
                    _StageInfo.Text        = "Compare files ...";
                }));

                _ProgressTimer.Start(1000, CompareProgressUpdate);

                int      cores   = Math.Min(_Settings.ThreadsCount, _ToCompareCount);
                Thread[] threads = new Thread[cores];
                FileNode? queue()
                {
                    FileNode? result = null;

                    if (!_TaskCancel)
                    {
                        lock (_FileIndexLocker)
                        {
                            if (_FileIndex < _ToCompareCount)
                            {
                                result = ToCompare[_FileIndex];
                                _FileIndex += 1;
                            }
                        }
                    }

                    return result;
                }
                for (int i = 0; i < cores; i++)
                {
                    threads[i] = new Thread(() => FileCompareTask(queue, _Settings.ChunkSize))
                    {
                        Name = $"thread_{i}"
                    };
                    threads[i].Start();
                }

                for (int i = 0; i < cores; i++)
                {
                    threads[i].Join();
                }
                    
                _ProgressTimer.Stop();

                if (!_TaskCancel)
                {
                    Invoke((MethodInvoker)(() => _StageInfo.Text = "Mark nodes ..." ));

                    SetNodesStatus(root);

                    if (routine != null)
                    {
                        Invoke((MethodInvoker)(() => routine()));
                    }
                }

                Invoke((MethodInvoker)(() =>
                {
                    _ProgressBar.Visible     = false;
                    _ProgressBar.TextVisible = false;
                    _PathView.Height        += 23;
                }));
            }

            _ProgressTimer.Dispose();

            Invoke((MethodInvoker)(() => 
            {
                _StageInfo.Text = _TaskCancel ? "Aborted." : "Done.";
                SetAbility(true);
            }));

            _TaskCancel     = false;
            _TaskInProgress = false;
        }
        #endregion

        #region Routines
        private static void PathKeyDown(TextBox src, TextBox dst)
        {
            if (src.TextLength > 0)
            {
                Regex exp = new(@"^[a-zA-Z]\:");

                if (exp.IsMatch(src.Text) && exp.IsMatch(dst.Text))
                {
                    dst.Text = string.Concat(dst.Text.AsSpan(0, 2), src.Text.AsSpan(2));
                }
                else
                {
                    dst.Text = src.Text;
                }
            }

            dst.Focus();
            dst.SelectionLength = 0;
            dst.SelectionStart  = dst.TextLength;
        }

        private static string GetFolderName(string path)
        {
            int pos = path.LastIndexOf('\\');
            return pos == -1 ? path : path[(pos + 1)..];
        }

        private void SetAbility(bool enable)
        {
            _SrcPath.Enabled      = enable;
            _DstPath.Enabled      = enable;
            _SrcSelect.Enabled    = enable;
            _DstSelect.Enabled    = enable;
            _StartCompare.Enabled = enable;
            _ResetCompare.Enabled = enable;
            _PathView.Enabled     = enable;
        }

        private void CompareReset()
        {
            _PathView.Nodes.Clear();
            _NodeInfoForm.Hide();

            _ElapsedInfo.Text   = "";
            _RemainingInfo.Text = "";
            _FilesInfo.Text     = "";
            _StageInfo.Text     = "";

            _Sep1Info.Visible = false;
            _Sep2Info.Visible = false;
            _Sep3Info.Visible = false;
        }

        private static void UpdateNodesStatusAndInfo(FolderNode node, TwinsFolderSpan span)
        {
            if (node != null)
            {
                TwinsStatus status = TwinsStatus.Match;

                for (int i = 0; i < node.Nodes.Count; i++)
                {
                    if (((FsNode)node.Nodes[i]).Status != TwinsStatus.Match)
                    {
                        status = TwinsStatus.Twins;
                        break;
                    }
                }
                        
                node.Status      = status;
                node.FolderInfo += span;

                if (node.Level > 0)
                {
                    UpdateNodesStatusAndInfo((FolderNode)node.Parent, span);
                }
            }
        }

        private void LoadFileNode(FileNode node, TwinsPath path)
        {
            FileInfo src = new(path.Source);
            FileInfo dst = new(path.Destination);

            if (src.Exists)
            {
                if (dst.Exists)
                {
                    node.Status = src.Length == dst.Length ? TwinsStatus.None : TwinsStatus.Twins;
                }
                else
                {
                    node.Status = TwinsStatus.SrcOnly;
                }
            }
            else
            {
                node.Status = TwinsStatus.DstOnly;
            }
            
            node.FileInfo = new TwinsFileInfo(src.Exists ? src : null, dst.Exists ? dst : null);

            if (node.Status == TwinsStatus.None)
            {
                _TotalFilesWeight = src.Length;
                _CompletedWeight  = 0;
                _ProgressTimer    = new InfoTimer();

                Invoke((MethodInvoker)(() =>
                {
                    Cursor = Cursors.WaitCursor;

                    _ProgressBar.Value       = 0;
                    _ProgressBar.Maximmum    = _TotalFilesWeight;
                    _ProgressBar.Visible     = true;
                    _ProgressBar.TextVisible = true;
                    _PathView.Height        -= 23;

                    _ElapsedInfo.Text   = "Elapsed: 0:00:00";
                    _RemainingInfo.Text = "Remaining: -:--:--";
                    _Sep2Info.Visible   = false;
                    _FilesInfo.Visible  = false;
                    _StageInfo.Text     = "Compare file ...";
                }));

                _ProgressTimer.Start(1000, dt =>
                {
                    long weight = _CompletedWeight;

                    string remaininig = "Remaining: ";
                    if (weight > 0)
                    {
                        double v = (double)weight / dt.Ticks;
                        TimeSpan t = new(Convert.ToInt64((_TotalFilesWeight - weight) / v));
                        if (t.TotalSeconds < 1 && weight < _TotalFilesWeight)
                        {
                            t = new TimeSpan(0, 0, 1);
                        }
                        remaininig += $"{t.Hours}:{t.Minutes:d2}:{t.Seconds:d2}";
                    }
                    else
                    {
                        remaininig += "-:--:--";
                    }

                    string elapsed = $"Elapsed: {dt.Hours}:{dt.Minutes:d2}:{dt.Seconds:d2}";

                    Invoke((MethodInvoker)(() =>
                    {
                        _ProgressBar.Value  = weight;
                        _ElapsedInfo.Text   = elapsed;
                        _RemainingInfo.Text = remaininig;
                    }));
                });

                node.Status = CompareFile(path, _Settings.ChunkSize);

                _ProgressTimer.Stop();

                Invoke((MethodInvoker)(() =>
                {
                    _ProgressBar.Visible     = false;
                    _ProgressBar.TextVisible = false;
                    _PathView.Height        += 23;

                    _Sep2Info.Visible  = true;
                    _FilesInfo.Visible = true;

                    Cursor = Cursors.Default;
                }));

                _ProgressTimer.Dispose();
            }
        }

        private void UpdateNode(FsNode node)
        {
            TwinsPath   path   = _Path + node.RelativePath;
            TreeNode    parent = node.Parent;
            int         index  = -1;
            bool        IsFile = node is FileNode;
            TwinsStatus Exists = path.Exists(IsFile ? TwinsType.File : TwinsType.Folder);
            FsNode?     root   = null;

            TwinsFolderSpan span = node.Span;

            if (Exists != TwinsStatus.None)
            {
                Invoke((MethodInvoker)(() => SetAbility(false) ));

                index = parent.Nodes.IndexOf(node);

                if (IsFile)
                {
                    FileNode file = new(node.Text);
                    LoadFileNode(file, path);
                    span += file.FileInfo;

                    root = file;
                }
                else
                {
                    FolderNode folder = new(node.Text);

                    if (Exists == TwinsStatus.Twins)
                    {
                        FolderCompare(folder, path, null);
                    }
                    else
                    {
                        DirectoryInfo src = new(path.Source);
                        DirectoryInfo dst = new(path.Destination);

                        folder.Status     = src.Exists ? TwinsStatus.SrcOnly : TwinsStatus.DstOnly;
                        folder.FolderInfo = new TwinsFolderInfo(src.Exists ? src : null, dst.Exists ? dst : null);
                    }

                    span += folder.FolderInfo;

                    root = folder;
                }

                root.ContextMenuStrip = _NodeMenu;
            }

            Invoke((MethodInvoker)(() =>
            {
                parent.Nodes.Remove(node);

                if (root != null && index != -1)
                {
                    parent.Nodes.Insert(index, root);
                }

                UpdateNodesStatusAndInfo((FolderNode)parent, span);

                SetAbility(true);
            }));
        }
        #endregion

        #region NodeMenu Routines
        private void NodeCopyTask(FsNode node, bool direct)
        {
            TwinsPath path = (direct ? _Path : _Path.Reverse) + node.RelativePath;

            try
            {
                if (node is FolderNode)
                {
                    FileSystem.CopyDirectory(path.Source, path.Destination, UIOption.AllDialogs);
                }  
                else
                {
                    FileSystem.CopyFile(path.Source, path.Destination, UIOption.AllDialogs);
                }

                UpdateNode(node);
            }
            catch (Exception ex)
            {
                Utils.Error($"\"{path.Source}\" copy error to {path.Destination}: {ex.Message}.");
            }
        }

        private void NodeDeleteTask(FsNode node, bool destination)
        {
            TwinsPath Path = _Path + node.RelativePath;
            string    path = destination ? Path.Destination : Path.Source;

            try
            {
                if (node is FolderNode)
                {
                    FileSystem.DeleteDirectory(path, UIOption.AllDialogs, RecycleOption.SendToRecycleBin);
                }
                else
                {
                    FileSystem.DeleteFile(path, UIOption.AllDialogs, RecycleOption.SendToRecycleBin);
                }

                Invoke((MethodInvoker)(() =>
                {
                    TwinsFolderSpan span   = node.Span;
                    FolderNode      parent = (FolderNode)node.Parent;
                    parent.Nodes.Remove(node);
                    UpdateNodesStatusAndInfo(parent, span);
                }));
            }
            catch (Exception ex)
            {
                Utils.Error($"\"{path}\" delete error: {ex.Message}.");
            }

            Invoke((MethodInvoker)(() => _PathView.Enabled = true ));
        }

        private static void NodeMove(string src, string dst, bool folder)
        {
            try
            {
                if (folder)
                {
                    FileSystem.MoveDirectory(src, dst);
                }
                else
                {
                    FileSystem.MoveFile(src, dst);
                }
            }
            catch (Exception ex)
            {
                Utils.Error($"rename \"{src}\" with \"{dst}\" error: {ex.Message}.");
            }
        }

        private void NodeRenameTask(FsNode node, string name)
        {
            TwinsPath OldPath = _Path + node.RelativePath;
            TwinsPath NewPath = OldPath.Rename(name);

            var f = node is FolderNode;
            var r = node.Status;

            if (r != TwinsStatus.DstOnly)
            {
                NodeMove(OldPath.Source, NewPath.Source, f);
            }
        
            if (r != TwinsStatus.SrcOnly)
            {
                NodeMove(OldPath.Destination, NewPath.Destination, f);
            }
            
            Invoke((MethodInvoker)(() => node.Text = name ));

            TreeNodeCollection ParentNodes = node.Parent.Nodes;
            foreach (TreeNode n in ParentNodes)
            {
                if (n.Text == name && n != node)
                {
                    ParentNodes.Remove(n);
                    break;
                }
            }

            UpdateNode(node);

            Invoke((MethodInvoker)(() => _PathView.LabelEdit = false ));
        }

        private void NodeCopy(bool direct)
        {
            _PathView.Enabled = false;
            FsNode node = (FsNode)_PathView.SelectedNode;
            Task.Factory.StartNew(() => NodeCopyTask(node, direct));
        }

        private void NodeDelete(bool destination)
        {
            _PathView.Enabled = false;
            FsNode node = (FsNode)_PathView.SelectedNode;
            Task.Factory.StartNew(() => NodeDeleteTask(node, destination));
        }

        private void NodeRename(FsNode node, string name)
        {
            _PathView.Enabled = false;
            Task.Factory.StartNew(() => NodeRenameTask(node, name) );
        }

        private void NodeUpdate()
        {
            _PathView.Enabled = false;
            FsNode node = (FsNode)_PathView.SelectedNode;
            Task.Factory.StartNew(() => UpdateNode(node) );
        }

        private static void WinRun(string fname, string args)
        {
            try
            {
                Process.Start(fname, args);
            }
            catch (Exception ex)
            {
                Utils.Error($"\"{fname} {args}\" execution error: {ex.Message}");
            }
        }

        private void Run(string app, string param = "", bool parent = false)
        {
            FsNode      node = (FsNode)_PathView.SelectedNode;
            TwinsStatus stat = node.Status;
            TwinsPath   path = _Path + node.RelativePath;

            if (parent)
            {
                path = path.Parent;
            }
              
            if (stat != TwinsStatus.DstOnly)
            {
                WinRun(app, $"{param} \"{path.Source}\"");
            }
            if (stat != TwinsStatus.SrcOnly)
            {
                WinRun(app, $"{param} \"{path.Destination}\"");
            }
        }
        #endregion

        #region Handlers
        private void SrcPathKeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Down)
            {
                PathKeyDown(_SrcPath, _DstPath);
            }
        }

        private void DstPathKeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Up)
            {
                PathKeyDown(_DstPath, _SrcPath);
            }
        }

        private void PathSelectClick(object sender, EventArgs e)
        {
            Button bt = (Button)sender;

            if (bt.Tag  != null)
            {
                TextBox tb = (TextBox)bt.Tag;

                FolderBrowserDialog dialog = new()
                {
                    ShowNewFolderButton = false,
                    Description = "Select " + tb.Tag?.ToString()
                };

                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    tb.Text = dialog.SelectedPath;
                }

                dialog.Dispose();
            } 
        }

        private void StartCompareClick(object sender, EventArgs e)
        {
            _Path = new TwinsPath(_SrcPath.Text.TrimEnd('\\'), _DstPath.Text.TrimEnd('\\'));

            if (_Path.Source == _Path.Destination)
            {
                Utils.Error("Source = Destination.");
                return;
            }

            if (!Directory.Exists(_Path.Source))
            {
                Utils.Error("Incorrect source path.");
                return;
            }

            if (!Directory.Exists(_Path.Destination))
            {
                Utils.Error("Incorrect destination path.");
                return;
            }

            SetAbility(false);

            CompareReset();

            FolderNode root = new(GetFolderName(_Path.Source) + " | " + GetFolderName(_Path.Destination));
            Task.Factory.StartNew(() => FolderCompare(root, _Path, () => _PathView.Nodes.Add(root)));
        }

        private void ResetCompareClick(object sender, EventArgs e)
        {
            if (_TaskInProgress)
            {
                Invoke((MethodInvoker)(() => _StageInfo.Text = "Canceling ..." ));
                _ResetCompare.Enabled = false;
                _TaskCancel           = true;
            }
            else
            {
                CompareReset();
            }
        }

        private void PathViewKeyDown(object sender, KeyEventArgs e)
        {
            _NodeMenuShift = e.Shift;
        }

        private void PathViewMouseClick(object sender, MouseEventArgs e)
        {
            if (_PathView.SelectedNode != null)
            {
                _PathView.SelectedNode.BackColor = _PathView.BackColor;
            }

            FsNode node = (FsNode)_PathView.GetNodeAt(e.Location);
            bool   hide = true;

            if (e.Button == MouseButtons.Right)
            {
                node.BackColor         = Color.LightGray;
                _PathView.SelectedNode = node;

                if (node != null && node.Level > 0)
                {
                    TwinsStatus r = node.Status;
                    bool        f = node is FileNode;

                    _NodeMenuSrcToDst.Enabled  = _NodeMenuShift || (r == TwinsStatus.Twins) || (r == TwinsStatus.SrcOnly);
                    _NodeMenuDstToSrc.Enabled  = _NodeMenuShift || (r == TwinsStatus.Twins) || (r == TwinsStatus.DstOnly);
                    _NodeMenuSrcDelete.Enabled = _NodeMenuShift || (r == TwinsStatus.SrcOnly);
                    _NodeMenuDstDelete.Enabled = _NodeMenuShift || (r == TwinsStatus.DstOnly);

                    _NodeMenuOpenAsText.Visible         = f;
                    _NodeMenuOpenAsBin.Visible          = f;
                    _NodeMenuOpenParentFolder.Visible   = f;
                    _NodeMenuOpenParentTerminal.Visible = f;
                    _NodeMenuOpenFolder.Visible         = !f;
                    _NodeMenuOpenTerminal.Visible       = !f;

                    _NodeInfoForm.Show(node, Location, _PathView.Location, e.Location, new Point(_NodeMenu.Size.Width + 10, 33));

                    hide = false;
                }
            }

            if (hide)
            {
                _NodeInfoForm.Hide();
            }
        }

        private void PathViewAfterLabelEdit(object sender, NodeLabelEditEventArgs e)
        {
            if (e.Node != null && !String.IsNullOrEmpty(e.Label))
            {
                NodeRename((FsNode)e.Node, e.Label);
            }

            e.CancelEdit = true;
        }

        private void NodeMenuClosed(object sender, ToolStripDropDownClosedEventArgs e)
        {
            _NodeInfoForm.Hide();
        }

        private void NodeMenuSrcToDstClick(object sender, EventArgs e)
        {
            NodeCopy(true);
        }

        private void NodeMenuDstToSrcClick(object sender, EventArgs e)
        {
            NodeCopy(false);
        }

        private void NodeMenuSrcDeleteClick(object sender, EventArgs e)
        {
            NodeDelete(false);
        }

        private void NodeMenuDstDeleteClick(object sender, EventArgs e)
        {
            NodeDelete(true);
        }

        private void NodeMenuRenameClick(object sender, EventArgs e)
        {
            _PathView.LabelEdit = true;
            _PathView.SelectedNode.BeginEdit();
        }

        private void NodeMenuUpdateClick(object sender, EventArgs e)
        {
            NodeUpdate();
        }

        private void NodeMenuOpenAsTextClick(object sender, EventArgs e)
        {
            Run(_Settings.Notepad);
        }

        private void NodeMenuOpenAsBinClick(object sender, EventArgs e)
        {
            Run(_Settings.HexEditor);
        }

        private void NodeMenuOpenParentFolderClick(object sender, EventArgs e)
        {
            Run("explorer.exe", "", true);
        }

        private void NodeMenuOpenParentTerminalClick(object sender, EventArgs e)
        {
            Run(_Settings.Terminal, "/start", true);
        }

        private void NodeMenuOpenFolderClick(object sender, EventArgs e)
        {
            Run("explorer.exe");
        }

        private void NodeMenuOpenTerminalClick(object sender, EventArgs e)
        {
            Run(_Settings.Terminal, "/start");
        }
        #endregion
    }
}