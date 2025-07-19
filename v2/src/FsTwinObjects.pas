unit FsTwinObjects;


uses System;
uses System.IO;


type
  TwinPaths = class
    {$region Fields}
    private _Source      : string;
    private _Destination : string;
    {$endregion}
    
    {$region Static}
    private static function GetParent(path: string) := path.Substring(0, path.LastIndexOf('\'));
    {$endregion}
  
    {$region Ctors}
    public constructor ();
    begin
    
    end;
    
    public constructor (source, destination: string);
    begin
      _Source      := source;
      _Destination := destination;
    end;
    {$endregion}
    
    {$region Properties}
    public property Source: string read _Source write _Source;
    
    public property Destination: string read _Destination write _Destination;
    
    public property Reverse: TwinPaths read (new TwinPaths(self.Destination, self.Source));
    
    public property Parents: TwinPaths read (new TwinPaths(GetParent(_Source), GetParent(_Destination)));
    
    public property Rename[name: string]: TwinPaths read (new TwinPaths(GetParent(_Source) + '\' + name, GetParent(_Destination) + '\' + name));
    
    public property OneOrMoreFoldersExists: boolean read (Directory.Exists(_Source) or Directory.Exists(_Destination));
    
    public property OneOrMoreFilesExists: boolean read (&File.Exists(_Source) or &File.Exists(_Destination));
    
    public property OneOrMoreExists: boolean read (OneOrMoreFoldersExists or OneOrMoreFilesExists);
    
    public property BothFoldersExists: boolean read (Directory.Exists(_Source) and Directory.Exists(_Destination));
    {$endregion}
    
    {$region Operators}
    public static function operator+(left: TwinPaths; right: string) := new TwinPaths(left.Source+'\'+right, left.Destination+'\'+right);
    {$endregion}
  end;
  
  TwinFolderInfoSpan = class
    {$region Fields}
    private _SrcFolders : integer;
    private _SrcFiles   : integer;
    private _SrcBytes   : int64;
    private _DstFolders : integer;
    private _DstFiles   : integer;
    private _DstBytes   : int64;
    {$endregion}
    
    {$region Ctors}
    public constructor ();
    begin
      
    end;
    {$endregion}
    
    {$region Properties}
    public property SrcFolders : integer read _SrcFolders;
    
    public property SrcFiles   : integer read _SrcFiles;
    
    public property SrcBytes   : int64   read _SrcBytes;
    
    public property DstFolders : integer read _DstFolders;
    
    public property DstFiles   : integer read _DstFiles;
    
    public property DstBytes   : int64   read _DstBytes;
    {$endregion}
  end;
  
  TwinFsObjectInfo = abstract class
    {$region Fields}
    protected _SrcBytes   : int64;
    protected _DstBytes   : int64;
    protected _SrcCreated : DateTime;
    protected _DstCreated : DateTime;
    protected _SrcChanged : DateTime;
    protected _DstChanged : DateTime;
    {$endregion}
    
    {$region Ctors}
    public constructor ();
    begin
    
    end;
    {$endregion}
    
    {$region Properties}
    public property SrcIsValid: boolean   read (_SrcBytes >= 0);
    
    public property DstIsValid: boolean   read (_DstBytes >= 0);
    
    public property SrcBytes:   int64     read (SrcIsValid ? _SrcBytes : 0);
    
    public property SrcCreated: DateTime  read _SrcCreated;
    
    public property SrcChanged: DateTime  read _SrcChanged;
    
    public property DstBytes:   int64     read (DstIsValid ? _DstBytes : 0);
    
    public property DstCreated: DateTime  read _DstCreated;
    
    public property DstChanged: DateTime  read _DstChanged;
    {$endregion}
    
    {$region Methods}
    public function SrcBytesToString()   := SrcIsValid ? _SrcBytes.ToString('N0') : '-';
    
    public function SrcCreatedToString() := SrcIsValid ? _SrcCreated.ToString('yyyy-MM-dd HH:mm:ss') : '-';
    
    public function SrcChangedToString() := SrcIsValid ? _SrcChanged.ToString('yyyy-MM-dd HH:mm:ss') : '-';
    
    public function DstBytesToString()   := DstIsValid ? _DstBytes.ToString('N0') : '-';
    
    public function DstCreatedToString() := DstIsValid ? _DstCreated.ToString('yyyy-MM-dd HH:mm:ss') : '-';
    
    public function DstChangedToString() := DstIsValid ? _DstChanged.ToString('yyyy-MM-dd HH:mm:ss') : '-';
    {$endregion}
  end;
  
  TwinFileInfo = class(TwinFsObjectInfo)
    {$region Fields}
    private _Paths : TwinPaths;
    {$endregion}
    
    {$region Ctors}
    public constructor (src: FileInfo := nil; dst: FileInfo := nil);
    begin
      if src <> nil then
        begin
          _SrcBytes   := src.Length;
          _SrcCreated := src.CreationTime;
          _SrcChanged := src.LastWriteTime;
        end
      else
        _SrcBytes := -1;
      
      if dst <> nil then
        begin
          _DstBytes   := dst.Length;
          _DstCreated := dst.CreationTime;
          _DstChanged := dst.LastWriteTime;
        end
      else
        _DstBytes := -1;
      
      _Paths := new TwinPaths(src <> nil ? src.FullName : '', dst <> nil ? dst.FullName : '');
    end;
    {$endregion}
    
    {$region Properties}
    public property Paths: TwinPaths read _Paths;
    {$endregion}
    
    {$region Operators}
    public static function operator-(right: TwinFileInfo): TwinFolderInfoSpan;
    begin
      result := new TwinFolderInfoSpan();
      
      result._SrcFolders := 0;
      result._SrcFiles   := -(right.SrcIsValid ? 1 : 0);
      result._SrcBytes   := -right.SrcBytes;
      
      result._DstFolders := 0;
      result._DstFiles   := -(right.DstIsValid ? 1 : 0);
      result._DstBytes   := -right.DstBytes;
    end;
    
    public static function operator+(left: TwinFolderInfoSpan; right: TwinFileInfo): TwinFolderInfoSpan;
    begin
      result := new TwinFolderInfoSpan();
      
      result._SrcFolders := left.SrcFolders;
      result._SrcFiles   := left.SrcFiles + (right.SrcIsValid ? 1 : 0);
      result._SrcBytes   := left.SrcBytes + right.SrcBytes;
      
      result._DstFolders := left.DstFolders;
      result._DstFiles   := left.DstFiles + (right.DstIsValid ? 1 : 0);
      result._DstBytes   := left.DstBytes + right.DstBytes;
    end;
    {$endregion}
  end;
  
  TwinFolderInfo = class(TwinFsObjectInfo)
    {$region Fields}
    private _SrcFolders : integer;
    private _DstFolders : integer;
    private _SrcFiles   : integer;
    private _DstFiles   : integer;
    {$endregion}
    
    {$region Static}
    private static function GetFolderInfo(path: string): (integer, integer, int64);
    begin
      try
        var FoldersCount := 0;
        var FilesCount   := 0;
        var BytesCount   := 0;
        
        var folders := Directory.GetDirectories(path);
        var files   := Directory.GetFiles(path);
        
        if folders <> nil then
          begin
            FoldersCount += folders.Length;
            
            foreach var f: string in folders do
              begin
                var info := GetFolderInfo(f);
                
                if info[2] >= 0 then
                  begin
                    FoldersCount += info[0];
                    FilesCount   += info[1];
                    BytesCount   += info[2];
                  end;
              end;
          end;
        
        if files <> nil then
          begin
            FilesCount += files.Length;
            
            foreach var f: string in files do
              BytesCount += (new FileInfo(f)).Length;
          end;
        
        result := (FoldersCount, FilesCount, BytesCount);
      except on ex: Exception do
        result := (0, 0, -1);
      end;
    end;
    {$endregion}
    
    {$region Ctors}
    private constructor (ref: TwinFolderInfo);
    begin
      self._SrcCreated := ref._SrcCreated;
      self._SrcChanged := ref._SrcChanged;
      self._DstCreated := ref._DstCreated;
      self._DstChanged := ref._DstChanged;
    end;
    
    public constructor (src: DirectoryInfo := nil; dst: DirectoryInfo := nil);
    begin
      if src <> nil then
        begin
          _SrcCreated := src.CreationTime;
          _SrcChanged := src.LastWriteTime;
          
          if dst <> nil then
            begin
              _SrcFolders := 0;
              _SrcFiles   := 0;
              _SrcBytes   := 0;
            end
          else
            (_SrcFolders, _SrcFiles, _SrcBytes) := GetFolderInfo(src.FullName);
        end
      else
        _SrcBytes := -1;
      
      if dst <> nil then
        begin
          _DstCreated := dst.CreationTime;
          _DstChanged := dst.LastWriteTime;
          
          if src <> nil then
            begin
              _DstFolders := 0;
              _DstFiles   := 0;
              _DstBytes   := 0;
            end
          else
            (_DstFolders, _DstFiles, _DstBytes) := GetFolderInfo(dst.FullName);
        end
      else
        _DstBytes := -1;
    end;
    {$endregion}
    
    {$region Properties}
    public property SrcFolders: integer  read (SrcIsValid ? _SrcFolders : 0) write _SrcFolders;
    
    public property SrcFiles:   integer  read (SrcIsValid ? _SrcFiles   : 0) write _SrcFiles;
    
    public property SrcBytes:   int64    read (SrcIsValid ? _SrcBytes   : 0) write _SrcBytes;
    
    public property DstFolders: integer  read (DstIsValid ? _DstFolders : 0) write _DstFolders;
    
    public property DstFiles:   integer  read (DstIsValid ? _DstFiles   : 0) write _DstFiles;
    
    public property DstBytes:   int64    read (DstIsValid ? _DstBytes   : 0) write _DstBytes;
    {$endregion}
    
    {$region Methods}
    public function SrcFoldersToString() := SrcIsValid ? _SrcFolders.ToString('N0') : '-';
    
    public function SrcFilesToString()   := SrcIsValid ? _SrcFiles.ToString('N0') : '-';
    
    public function DstFoldersToString() := DstIsValid ? _DstFolders.ToString('N0') : '-';
    
    public function DstFilesToString()   := DstIsValid ? _DstFiles.ToString('N0') : '-';
    {$endregion}
    
    {$region Operators}
    public static function operator+(left: TwinFolderInfo; right: TwinFolderInfo): TwinFolderInfo;
    begin
      result := new TwinFolderInfo(left);
      
      result._SrcFolders := left.SrcFolders + right.SrcFolders;
      result._SrcFiles   := left.SrcFiles   + right.SrcFiles;
      result._SrcBytes   := left.SrcBytes   + right.SrcBytes;
      
      result._DstFolders := left.DstFolders + right.DstFolders;
      result._DstFiles   := left.DstFiles   + right.DstFiles;
      result._DstBytes   := left.DstBytes   + right.DstBytes;
    end;
    
    public static procedure operator+=(var left: TwinFolderInfo; right: TwinFolderInfo);
    begin
      left := left + right;
    end;
    
    public static function operator-(right: TwinFolderInfo): TwinFolderInfoSpan;
    begin
      result := new TwinFolderInfoSpan();
      
      result._SrcFolders := -right.SrcFolders;
      result._SrcFiles   := -right.SrcFiles;
      result._SrcBytes   := -right.SrcBytes;
      
      result._DstFolders := -right.DstFolders;
      result._DstFiles   := -right.DstFiles;
      result._DstBytes   := -right.DstBytes;
    end;
    
    public static function operator+(left: TwinFolderInfoSpan; right: TwinFolderInfo): TwinFolderInfoSpan;
    begin
      result := new TwinFolderInfoSpan();
      
      result._SrcFolders := left.SrcFolders + right.SrcFolders;
      result._SrcFiles   := left.SrcFiles   + right.SrcFiles;
      result._SrcBytes   := left.SrcBytes   + right.SrcBytes;
      
      result._DstFolders := left.DstFolders + right.DstFolders;
      result._DstFiles   := left.DstFiles   + right.DstFiles;
      result._DstBytes   := left.DstBytes   + right.DstBytes;
    end;
    
    public static function operator+(left: TwinFolderInfo; right: TwinFolderInfoSpan): TwinFolderInfo;
    begin
      result := new TwinFolderInfo(left);
      
      result._SrcFolders := left.SrcFolders + right.SrcFolders;
      result._SrcFiles   := left.SrcFiles   + right.SrcFiles;
      result._SrcBytes   := left.SrcBytes   + right.SrcBytes;
      
      result._DstFolders := left.DstFolders + right.DstFolders;
      result._DstFiles   := left.DstFiles   + right.DstFiles;
      result._DstBytes   := left.DstBytes   + right.DstBytes;
    end;
    
    public static procedure operator+=(var left: TwinFolderInfo; right: TwinFolderInfoSpan);
    begin
      left := left + right;
    end;
    {$endregion}
  end;


end.