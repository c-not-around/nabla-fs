using System;
using System.IO;


namespace NablaFs
{
    internal enum TwinsType
    {
        Folder,
        File
    }

    internal enum TwinsStatus
    {
        None,
        Error,
        SrcOnly,
        DstOnly,
        Twins,
        Match
    };

    internal class TwinsPath(string source, string destination)
    {
        #region Static
        private static string GetParent(string path) => path[..path.LastIndexOf('\\')];
        #endregion

        #region Properties
        public string Source { get; private set; } = source;

        public string Destination { get; private set; } = destination;

        public TwinsPath Reverse => new(Destination, Source);

        public TwinsPath Parent => new(GetParent(Source), GetParent(Destination));

        public TwinsStatus FolderExists
        {
            get
            {
                bool src = Directory.Exists(Source);
                bool dst = Directory.Exists(Destination);

                return src ? (dst ? TwinsStatus.Twins : TwinsStatus.SrcOnly) : (dst ? TwinsStatus.DstOnly : TwinsStatus.None);
            }
        }

        public TwinsStatus FileExists
        {
            get
            {
                bool src = File.Exists(Source);
                bool dst = File.Exists(Destination);

                return src ? (dst ? TwinsStatus.Twins : TwinsStatus.SrcOnly) : (dst ? TwinsStatus.DstOnly : TwinsStatus.None);
            }
        }
        #endregion

        #region Methods
        public TwinsStatus Exists(TwinsType type) => type == TwinsType.Folder ? FolderExists : FileExists;

        public TwinsPath Rename(string name) => new(GetParent(Source) + @"\" + name, GetParent(Destination) + @"\" + name);
        #endregion

        #region Operators
        public static TwinsPath operator+(TwinsPath left, string right) => new(left.Source + @"\" + right, left.Destination + @"\" + right);
        #endregion
    }

    internal abstract class TwinsObjectInfo
    {
        #region Fields
        protected long     _SrcBytes;
        protected DateTime _SrcCreated;
        protected DateTime _SrcChanged;
        protected long     _DstBytes;
        protected DateTime _DstCreated;
        protected DateTime _DstChanged;
        #endregion

        #region Static
        protected static string Format(bool v, long u) => v ? u.ToString("N0") : "-";

        protected static string Format(bool v, DateTime dt) => v ? dt.ToString("yyyy-MM-dd HH:mm:ss") : "-";
        #endregion

        #region Properties
        public bool SrcValid => _SrcBytes > -1;

        public long SrcBytes => SrcValid ? _SrcBytes : 0;

        public DateTime SrcCreated => _SrcCreated;

        public DateTime SrcChanged => _SrcChanged;

        public string SrcBytesToString => Format(SrcValid, _SrcBytes);

        public string SrcCreatedToString => Format(SrcValid, _SrcCreated);

        public string SrcChangedToString => Format(SrcValid, _SrcChanged);

        public bool DstValid => _DstBytes > -1;

        public long DstBytes => DstValid ? _DstBytes : 0;

        public DateTime DstCreated => _DstCreated;

        public DateTime DstChanged => _DstChanged;

        public string DstBytesToString => Format(DstValid, _DstBytes);

        public string DstCreatedToString => Format(DstValid, _DstCreated);

        public string DstChangedToString => Format(DstValid, _DstChanged);
        #endregion
    }

    internal class TwinsFolderInfo : TwinsObjectInfo
    {
        #region Fields
        private int _SrcFolders;
        private int _SrcFiles;
        private int _DstFolders;
        private int _DstFiles;
        #endregion

        #region Static
        private static (int, int, long) GetFolderInfo(string path)
        {
            try
            {
                int  folders = 0;
                int  files   = 0;
                long bytes   = 0;

                string[] Folders = Directory.GetDirectories(path);
                string[] Files   = Directory.GetFiles(path);

                if (Folders != null)
                {
                    folders += Folders.Length;

                    foreach (string folder in Folders)
                    {
                        var (fo, fi, by) = GetFolderInfo(folder);

                        if (by > -1)
                        {
                            folders += fo;
                            files   += fi;
                            bytes   += by;
                        }
                    }
                }

                if (Files != null)
                {
                    files += Files.Length;

                    foreach (string file in Files)
                    {
                        bytes += (new FileInfo(file)).Length;
                    }
                }

                return (folders, files, bytes);
            }
            catch
            {
                return (0, 0, -1);
            }
        }
        #endregion

        #region Ctors
        private TwinsFolderInfo(TwinsFolderInfo info)
        {
            _SrcCreated = info._SrcCreated;
            _SrcChanged = info._SrcChanged;
            _DstCreated = info._DstCreated;
            _DstChanged = info._DstChanged;
        }

        public TwinsFolderInfo(DirectoryInfo? src, DirectoryInfo? dst)
        {
            if (src != null && src.Exists)
            {
                _SrcCreated = src.CreationTime;
                _SrcChanged = src.LastWriteTime;

                if (dst != null && dst.Exists)
                {
                    _SrcFolders = 0;
                    _SrcFiles   = 0;
                    _SrcBytes   = 0;
                }
                else
                {
                    (_SrcFolders, _SrcFiles, _SrcBytes) = GetFolderInfo(src.FullName);
                }
            }
            else
            {
                _SrcBytes = -1;
            }

            if (dst != null && dst.Exists)
            {
                _DstCreated = dst.CreationTime;
                _DstChanged = dst.LastWriteTime;

                if (src != null && src.Exists)
                {
                    _DstFolders = 0;
                    _DstFiles   = 0;
                    _DstBytes   = 0;
                }
                else
                {
                    (_DstFolders, _DstFiles, _DstBytes) = GetFolderInfo(dst.FullName);
                }
            }
            else
            {
                _DstBytes = -1;
            }
        }
        #endregion

        #region Properties
        public int SrcFolders
        {
            get => SrcValid ? _SrcFolders : 0;
            set => _SrcFolders = value;
        }

        public int SrcFiles
        {
            get => SrcValid ? _SrcFiles : 0;
            set => _SrcFiles = value;
        }

        public new long SrcBytes
        {
            get => SrcValid ? _SrcBytes : 0;
            set => _SrcBytes = value;
        }

        public int DstFolders
        {
            get => DstValid ? _DstFolders : 0;
            set => _DstFolders = value;
        }

        public int DstFiles
        {
            get => DstValid ? _DstFiles : 0;
            set => _DstFiles = value;
        }

        public new long DstBytes
        {
            get => DstValid ? _DstBytes : 0;
            set => _DstBytes = value;
        }

        public string SrcFoldersToString => Format(SrcValid, _SrcFolders);

        public string SrcFilesToString => Format(SrcValid, _SrcFiles);

        public string DstFoldersToString => Format(DstValid, _DstFolders);

        public string DstFilesToString => Format(DstValid, _DstFiles);
        #endregion

        #region Operators
        public static TwinsFolderInfo operator+(TwinsFolderInfo left, TwinsFolderInfo right)
        {
            TwinsFolderInfo result = new(left)
            {
                _SrcFolders = left.SrcFolders + right.SrcFolders,
                _SrcFiles   = left.SrcFiles   + right.SrcFiles,
                _SrcBytes   = left.SrcBytes   + right.SrcBytes,

                _DstFolders = left.DstFolders + right.DstFolders,
                _DstFiles   = left.DstFiles   + right.DstFiles,
                _DstBytes   = left.DstBytes   + right.DstBytes
            };

            return result;
        }

        public static TwinsFolderSpan operator-(TwinsFolderInfo right)
        {
            TwinsFolderSpan result = new()
            {
                SrcFolders = -(right.SrcFolders + (right.SrcValid ? 1 : 0)),
                SrcFiles   = -right.SrcFiles,
                SrcBytes   = -right.SrcBytes,

                DstFolders = -(right.DstFolders + (right.DstValid ? 1 : 0)),
                DstFiles   = -right.DstFiles,
                DstBytes   = -right.DstBytes
            };

            return result;
        }

        public static TwinsFolderSpan operator+(TwinsFolderSpan left, TwinsFolderInfo right)
        {
            TwinsFolderSpan result = new()
            {
                SrcFolders = left.SrcFolders + right.SrcFolders + (right.SrcValid ? 1 : 0),
                SrcFiles   = left.SrcFiles   + right.SrcFiles,
                SrcBytes   = left.SrcBytes   + right.SrcBytes,

                DstFolders = left.DstFolders + right.DstFolders + (right.DstValid ? 1 : 0),
                DstFiles   = left.DstFiles   + right.DstFiles,
                DstBytes   = left.DstBytes   + right.DstBytes
            };

            return result;
        }

        public static TwinsFolderInfo operator+(TwinsFolderInfo left, TwinsFolderSpan right)
        {
            TwinsFolderInfo result = new(left)
            {
                _SrcFolders = left.SrcFolders + right.SrcFolders,
                _SrcFiles   = left.SrcFiles   + right.SrcFiles,
                _SrcBytes   = left.SrcBytes   + right.SrcBytes,

                _DstFolders = left.DstFolders + right.DstFolders,
                _DstFiles   = left.DstFiles   + right.DstFiles,
                _DstBytes   = left.DstBytes   + right.DstBytes
            };

            return result;
        }
        #endregion
    }

    internal class TwinsFileInfo : TwinsObjectInfo
    {
        #region Ctors
        public TwinsFileInfo(FileInfo? src = null, FileInfo? dst = null)
        {
            if (src != null && src.Exists)
            {
                _SrcBytes   = src.Length;
                _SrcCreated = src.CreationTime;
                _SrcChanged = src.LastWriteTime;
            }
            else
            {
                _SrcBytes = -1;
            }

            if (dst != null && dst.Exists)
            {
                _DstBytes   = dst.Length;
                _DstCreated = dst.CreationTime;
                _DstChanged = dst.LastWriteTime;
            }
            else
            {
                _DstBytes = -1;
            }

            Path = new TwinsPath(src != null ? src.FullName : "", dst != null ? dst.FullName : "");
        }
        #endregion

        #region Properties
        public TwinsPath Path { get; private set; }
        #endregion

        #region Operators
        public static TwinsFolderSpan operator-(TwinsFileInfo right)
        {
            TwinsFolderSpan result = new()
            {
                SrcFolders = 0,
                SrcFiles   = -(right.SrcValid ? 1 : 0),
                SrcBytes   = -right.SrcBytes,

                DstFolders = 0,
                DstFiles   = -(right.DstValid ? 1 : 0),
                DstBytes   = -right.DstBytes
            };

            return result;
        }

        public static TwinsFolderSpan operator+(TwinsFolderSpan left, TwinsFileInfo right)
        {
            TwinsFolderSpan result = new()
            {
                SrcFolders = left.SrcFolders,
                SrcFiles   = left.SrcFiles + (right.SrcValid ? 1 : 0),
                SrcBytes   = left.SrcBytes + right.SrcBytes,

                DstFolders = left.DstFolders,
                DstFiles   = left.DstFiles + (right.DstValid ? 1 : 0),
                DstBytes   = left.DstBytes + right.DstBytes
            };

            return result;
        }
        #endregion
    }

    internal class TwinsFolderSpan
    {
        public int SrcFolders { get; set; }

        public int SrcFiles { get; set; }

        public long SrcBytes { get; set; }

        public int DstFolders { get; set; }

        public int DstFiles { get; set; }

        public long DstBytes { get; set; }
    }
}