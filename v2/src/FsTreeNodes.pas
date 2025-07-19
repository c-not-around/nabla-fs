unit FsTreeNodes;


{$reference System.Drawing.dll}
{$reference System.Windows.Forms.dll}


uses System;
uses System.Drawing;
uses System.Windows.Forms;
uses FsTwinObjects;


type
  CompareResult = ( None, Error, Twins, SourceOnly, DestinationOnly, Matches );
  
  FsNode = abstract class(TreeNode) 
    {$region Fields}
    private _Status: CompareResult;
    {$endregion}
    
    {$region Accessors}
    private function GetImageKey() := inherited ImageKey;
    
    private function GetSelectedImageKey() := inherited SelectedImageKey;
    
    private function GetForeColor() := inherited ForeColor;
    
    private procedure SetStatus(s: CompareResult);
    begin
      _Status := s;
      
      case _Status of
        CompareResult.None :   inherited ForeColor := Color.Black;
        CompareResult.Error:   inherited ForeColor := Color.Gray;
        CompareResult.Twins:   inherited ForeColor := Color.Red;
        CompareResult.Matches: inherited ForeColor := Color.Green;
        else                   inherited ForeColor := Color.Orange;
      end;
    end;
    
    private function GetRelativePath(): string;
    begin
      var path := FullPath;
      result := path.Substring(path.IndexOf('\') + 1);
    end;
    {$endregion}
    
    {$region Ctors}
    public constructor (key, name: string);
    begin
      inherited Create();
      
      inherited ImageKey         := key;
      inherited SelectedImageKey := key;
      
      Text := name;
    end;
    {$endregion}
    
    {$region Properties}
    public property ImageKey: string read GetImageKey;
    
    public property SelectedImageKey: string read GetSelectedImageKey;
    
    public property ForeColor: System.Drawing.Color read GetForeColor;
    
    public property Status: CompareResult read _Status write SetStatus;
    
    public property RelativePath: string read GetRelativePath;
    
    public property Info: TwinFsObjectInfo read; abstract;
    
    public property InfoSpan: TwinFolderInfoSpan read; abstract;
    {$endregion}
  end;
  
  FolderNode = class(FsNode)
    {$region Fields}
    private _FolderInfo: TwinFolderInfo;
    {$endregion}
    
    {$region Ctors}
    public constructor (name: string);
    begin
      inherited Create('folder', name);
    end;
    {$endregion}
    
    {$region Properties}
    public property FoldersInfo: TwinFolderInfo read _FolderInfo write _FolderInfo;
    
    public property Info: TwinFsObjectInfo read (_FolderInfo as TwinFsObjectInfo); override;
    
    public property InfoSpan: TwinFolderInfoSpan read (-_FolderInfo); override;
    {$endregion}
  end;
  
  FileNode = class(FsNode)
    {$region Fields}
    private _FileInfo: TwinFileInfo;
    {$endregion}
    
    {$region Ctors}
    public constructor (name: string);
    begin
      inherited Create('file', name);
    end;
    {$endregion}
    
    {$region Properties}
    public property FilesInfo: TwinFileInfo read _FileInfo write _FileInfo;
    
    public property Info: TwinFsObjectInfo read (_FileInfo as TwinFsObjectInfo); override;
    
    public property InfoSpan: TwinFolderInfoSpan read (-_FileInfo); override;
    {$endregion}
  end;


end.