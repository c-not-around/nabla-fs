namespace NablaFs
{
    partial class NodeInfoForm
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(NodeInfoForm));
            
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle1 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
            _NodeInfoView = new System.Windows.Forms.DataGridView();
            _InfoViewParams = new System.Windows.Forms.DataGridViewTextBoxColumn();
            _InfoViewSrc = new System.Windows.Forms.DataGridViewTextBoxColumn();
            _InfoViewDst = new System.Windows.Forms.DataGridViewTextBoxColumn();
            ((System.ComponentModel.ISupportInitialize)_NodeInfoView).BeginInit();
            _NodeInfoView.SuspendLayout();
            SuspendLayout();
            // 
            // _NodeInfoView
            // 
            _NodeInfoView.AllowUserToAddRows = false;
            _NodeInfoView.AllowUserToDeleteRows = false;
            _NodeInfoView.AllowUserToResizeColumns = false;
            _NodeInfoView.AllowUserToResizeRows = false;
            _NodeInfoView.AutoSizeRowsMode = System.Windows.Forms.DataGridViewAutoSizeRowsMode.DisplayedCellsExceptHeaders;
            _NodeInfoView.BorderStyle = System.Windows.Forms.BorderStyle.None;
            _NodeInfoView.CellBorderStyle = System.Windows.Forms.DataGridViewCellBorderStyle.RaisedVertical;
            _NodeInfoView.ClipboardCopyMode = System.Windows.Forms.DataGridViewClipboardCopyMode.Disable;
            dataGridViewCellStyle1.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle1.BackColor = System.Drawing.Color.Silver;
            dataGridViewCellStyle1.Font = new System.Drawing.Font("Segoe UI", 9F);
            dataGridViewCellStyle1.ForeColor = System.Drawing.SystemColors.WindowText;
            dataGridViewCellStyle1.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle1.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle1.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            _NodeInfoView.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle1;
            _NodeInfoView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            _NodeInfoView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] { _InfoViewParams, _InfoViewSrc, _InfoViewDst });
            _NodeInfoView.GridColor = System.Drawing.Color.White;
            _NodeInfoView.Location = new System.Drawing.Point(0, 0);
            _NodeInfoView.Name = "_NodeInfoView";
            _NodeInfoView.ReadOnly = true;
            _NodeInfoView.RowHeadersVisible = false;
            _NodeInfoView.ScrollBars = System.Windows.Forms.ScrollBars.None;
            _NodeInfoView.Size = new System.Drawing.Size(325, 138);
            _NodeInfoView.TabIndex = 0;
            // 
            // _InfoViewParams
            // 
            dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            _InfoViewParams.DefaultCellStyle = dataGridViewCellStyle2;
            _InfoViewParams.Frozen = true;
            _InfoViewParams.HeaderText = "Property";
            _InfoViewParams.Name = "_InfoViewParams";
            _InfoViewParams.ReadOnly = true;
            _InfoViewParams.Resizable = System.Windows.Forms.DataGridViewTriState.False;
            _InfoViewParams.Width = 65;
            // 
            // _InfoViewSrc
            // 
            dataGridViewCellStyle3.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleRight;
            _InfoViewSrc.DefaultCellStyle = dataGridViewCellStyle3;
            _InfoViewSrc.HeaderText = "Source";
            _InfoViewSrc.Name = "_InfoViewSrc";
            _InfoViewSrc.ReadOnly = true;
            _InfoViewSrc.Resizable = System.Windows.Forms.DataGridViewTriState.False;
            _InfoViewSrc.Width = 128;
            // 
            // _InfoViewDst
            // 
            _InfoViewDst.HeaderText = "Destination";
            _InfoViewDst.Name = "_InfoViewDst";
            _InfoViewDst.ReadOnly = true;
            _InfoViewDst.Resizable = System.Windows.Forms.DataGridViewTriState.False;
            _InfoViewDst.Width = 128;
            // 
            // NodeInfoForm
            // 
            ClientSize = new System.Drawing.Size(327, 140);
            ControlBox = false;
            Controls.Add(_NodeInfoView);
            FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            MaximizeBox = false;
            MinimizeBox = false;
            Name = "NodeInfoForm";
            Opacity = 0.75D;
            ShowIcon = false;
            ShowInTaskbar = false;
            StartPosition = System.Windows.Forms.FormStartPosition.Manual;
            _NodeInfoView.ResumeLayout(false);
            _NodeInfoView.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)_NodeInfoView).EndInit();
            ResumeLayout(false);
            PerformLayout();
            
        }
        
        #endregion
        
        private System.Windows.Forms.DataGridViewTextBoxColumn _InfoViewParams;
        private System.Windows.Forms.DataGridViewTextBoxColumn _InfoViewSrc;
        private System.Windows.Forms.DataGridViewTextBoxColumn _InfoViewDst;
        private System.Windows.Forms.DataGridView              _NodeInfoView;
    }
}