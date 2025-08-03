using System;
using System.Globalization;
using System.Windows.Forms;


namespace NablaFs
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            InputLanguage? lang = InputLanguage.FromCulture(new CultureInfo("en-US"));
            if (lang != null)
            {
                Application.CurrentInputLanguage = lang;
            }
            
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}