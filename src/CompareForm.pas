unit CompareForm;


{$reference System.Drawing.dll}
{$reference System.Windows.Forms.dll}


uses
  System,
  System.Diagnostics,
  System.Threading.Tasks,
  System.Drawing,
  System.Windows.Forms,
  CustomProgressBar;


type
  FileCompareForm = class(Form)
  protected
    procedure OnFormClosing(e: System.Windows.Forms.FormClosingEventArgs); override;
    begin
      e.Cancel := CompareInProgress;
      inherited OnFormClosing(e);
    end;
  private
    {$region Fields}
    CompareLog       : TextBox;
    CompareProgress  : ColorProgressBar;
    CompareClose     : Button;
    CompareCancel    : Button;
    ProgressInfo     : &Label;
    ElapsedInfo      : &Label;
    RemainingInfo    : &Label;
    ProgressTimer    : System.Timers.Timer;
    StartTime        : DateTime;
    CurrentProgress  : integer;
    CompareInProgress: boolean;
    CompareCanceling : boolean;
    {$endregion}
    
    {$region Routines}
    procedure ProgressTimerElapsed(sender: object; e: System.Timers.ElapsedEventArgs);
    begin
      var dt := DateTime.Now - StartTime;
      
      var v := CurrentProgress / dt.Ticks;
      var t := new TimeSpan(Convert.ToInt64((100 - CurrentProgress) / v));
      if t.TotalSeconds <= 0 then
        t := new TimeSpan(0, 0, 5);
      
      ElapsedInfo.Text   := $'Elapsed: {dt.Hours}:{dt.Minutes:d2}:{dt.Seconds:d2}';
      RemainingInfo.Text := $'Remaining: {t.Hours}:{t.Minutes:d2}:{t.Seconds:d2}';
    end;
    
    procedure CompareTask(file1, file2: string);
    begin
      var ProcInfo                    := new ProcessStartInfo('fcmp.exe', $'"{file1}" "{file2}"');
      ProcInfo.CreateNoWindow         := true;
      ProcInfo.UseShellExecute        := false;
      ProcInfo.RedirectStandardOutput := true;
      var proc := Process.Start(ProcInfo);
      
      StartTime := DateTime.Now;
      ProgressTimer.Start();
      
      var ProgressColor := Color.DarkRed;
      
      var b := '';
      CurrentProgress := 0;
      while not proc.StandardOutput.EndOfStream do
        begin
          var c := Convert.ToChar(proc.StandardOutput.Read());
          
          if c = '#' then
            begin
              CurrentProgress += 2;
              Invoke(() -> 
                begin 
                  CompareProgress.Value := CurrentProgress;
                  ProgressInfo.Text     := CurrentProgress.ToString() + '%';
                end
              );
            end;
          
          if (c = #13) or (c = #10) then
            begin
              if b <> '' then
                begin
                  Invoke(() -> begin CompareLog.Text += b + #13#10; end);
                  
                  if b = 'matched!' then
                    ProgressColor := Color.Green;
                  
                  b := '';
                end;
            end
          else
            b += c;
          
          if CompareCanceling then
            begin
              proc.Kill();
              CompareCanceling := false;
            end;
        end;
      proc.Close();
      proc.Dispose();
      
      ProgressTimer.Stop();
      ProgressTimer.Enabled := false;
      
      Invoke(() -> 
        begin
          RemainingInfo.Text        := $'Remaining: 0:00:00';
          CompareProgress.ForeColor := ProgressColor;
          CompareCancel.Enabled     := false;
          CompareClose.Enabled      := true;
        end
      );
      
      CompareInProgress := false;
    end;
    {$endregion}
  public
    {$region Ctors}
    constructor ();
    begin
      {$region Form}
      FormBorderStyle := System.Windows.Forms.FormBorderStyle.Sizable;
      StartPosition   := System.Windows.Forms.FormStartPosition.CenterParent;
      ClientSize      := new System.Drawing.Size(420, 230);
      MinimumSize     := Size;
      Icon            := new System.Drawing.Icon(System.Reflection.Assembly.GetEntryAssembly().GetManifestResourceStream('icon.ico'));
      SizeGripStyle   := System.Windows.Forms.SizeGripStyle.Hide;
      MinimizeBox     := false;
      MaximizeBox     := false;
      ControlBox      := false;
      Text            := 'Bytewise compare files';
      {$endregion}
      
      {$region CompareLog}
      CompareLog            := new System.Windows.Forms.TextBox();
      CompareLog.Size       := new System.Drawing.Size(ClientSize.Width-2*5, 150);
      CompareLog.Location   := new System.Drawing.Point(5, 5);
      CompareLog.Anchor     := AnchorStyles.Left or AnchorStyles.Top or AnchorStyles.Right or AnchorStyles.Bottom;
      CompareLog.Multiline  := true;
      CompareLog.ReadOnly   := true;
      CompareLog.BackColor  := Color.White;
      CompareLog.WordWrap   := false;
      CompareLog.ScrollBars := System.Windows.Forms.ScrollBars.Vertical;
      CompareLog.Font       := new System.Drawing.Font('Consolas', 10, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point);
      Controls.Add(CompareLog);
      {$endregion}
      
      {$region CompareProgress}
      CompareProgress           := new ColorProgressBar();
      CompareProgress.Size      := new System.Drawing.Size(CompareLog.Width, 20);
      CompareProgress.Location  := new System.Drawing.Point(CompareLog.Left, CompareLog.Top+CompareLog.Height+5);
      CompareProgress.Anchor    := AnchorStyles.Left or AnchorStyles.Right or AnchorStyles.Bottom;
      CompareProgress.ForeColor := Color.Blue;
      Controls.Add(CompareProgress);
      {$endregion}
      
      {$region ProgressInfo}
      ProgressInfo           := new System.Windows.Forms.Label();
      ProgressInfo.Size      := new System.Drawing.Size(50, 40);
      ProgressInfo.Location  := new System.Drawing.Point(CompareProgress.Left, CompareProgress.Top+CompareProgress.Height+5);
      ProgressInfo.Anchor    := AnchorStyles.Left or AnchorStyles.Bottom;
      ProgressInfo.Font      := new System.Drawing.Font('Segoe UI', 10, FontStyle.Bold, GraphicsUnit.Point);
      ProgressInfo.TextAlign := System.Drawing.ContentAlignment.MiddleCenter;
      ProgressInfo.Text      := '0%';
      Controls.Add(ProgressInfo);
      
      ElapsedInfo           := new System.Windows.Forms.Label();
      ElapsedInfo.Size      := new System.Drawing.Size(140, ProgressInfo.Height div 2);
      ElapsedInfo.Location  := new System.Drawing.Point(ProgressInfo.Left+ProgressInfo.Width+5, ProgressInfo.Top);
      ElapsedInfo.Anchor    := AnchorStyles.Left or AnchorStyles.Bottom;
      ElapsedInfo.Font      := new System.Drawing.Font('Segoe UI', 10, FontStyle.Regular, GraphicsUnit.Point);
      ElapsedInfo.TextAlign := System.Drawing.ContentAlignment.MiddleRight;
      ElapsedInfo.Text      := 'Elapsed: 0:00:00';
      Controls.Add(ElapsedInfo);
      
      RemainingInfo           := new System.Windows.Forms.Label();
      RemainingInfo.Size      := new System.Drawing.Size(ElapsedInfo.Width, ElapsedInfo.Height);
      RemainingInfo.Location  := new System.Drawing.Point(ElapsedInfo.Left, ElapsedInfo.Top+ElapsedInfo.Height);
      RemainingInfo.Anchor    := AnchorStyles.Left or AnchorStyles.Bottom;
      RemainingInfo.Font      := new System.Drawing.Font('Segoe UI', 10, FontStyle.Regular, GraphicsUnit.Point);
      RemainingInfo.TextAlign := System.Drawing.ContentAlignment.MiddleRight;
      RemainingInfo.Text      := 'Remaining: -:--:--';
      Controls.Add(RemainingInfo);
      {$endregion}
      
      {$region Buttons}
      CompareClose          := new System.Windows.Forms.Button();
      CompareClose.Size     := new System.Drawing.Size(75, 23);
      CompareClose.Location := new System.Drawing.Point(CompareProgress.Left+CompareProgress.Width-75+1, ProgressInfo.Top+(ProgressInfo.Height-CompareClose.Height) div 2);
      CompareClose.Anchor   := AnchorStyles.Right or AnchorStyles.Bottom;
      CompareClose.Text     := 'Close';
      CompareClose.Click    += (sender, e) -> Close();
      Controls.Add(CompareClose);
      
      CompareCancel          := new System.Windows.Forms.Button();
      CompareCancel.Size     := new System.Drawing.Size(CompareClose.Width, CompareClose.Height);
      CompareCancel.Location := new System.Drawing.Point(CompareClose.Left-(75+5), CompareClose.Top);
      CompareCancel.Anchor   := AnchorStyles.Right or AnchorStyles.Bottom;
      CompareCancel.Text     := 'Cancel';
      CompareCancel.Click    += (sender, e) ->
        begin
          CompareCancel.Enabled := false;
          CompareCanceling      := true;
        end;
      Controls.Add(CompareCancel);
      {$endregion}
    end;
    {$endregion}
    
    {$region Methods}
    function ShowDialog(path1, path2: string): System.Windows.Forms.DialogResult;
    begin
      CompareClose.Enabled  := false;
      CompareProgress.Value := 0;
      CompareInProgress     := true;
      CompareCanceling      := false;
      
      ProgressTimer          := new System.Timers.Timer();
      ProgressTimer.Elapsed  += ProgressTimerElapsed;
      ProgressTimer.Interval := 1000.0;
      ProgressTimer.Enabled  := true;
      
      Task.Factory.StartNew(() -> begin CompareTask(path1, path2); end);
      
      result := inherited ShowDialog();
    end;
    {$endregion}
  end;


end.