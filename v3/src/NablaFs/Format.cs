using System.Globalization;


namespace NablaFs
{
    internal static class Format
    {
        public static NumberFormatInfo FormatInfo { get; } = (new CultureInfo("en-US")).NumberFormat;

        public static string BytesPrefix(double s)
        {
            int p = 0;
            while (s >= 1024.0)
            {
                s /= 1024.0;
                p += 1;
            }

            string f = "f";
            if (s < 10.0)
            {
                f += "2";
            }
            else if (s < 100.0)
            {
                f += "1";
            }
            else
            {
                f += "0";
            }

            string result = s.ToString(f, FormatInfo);

            if (p > 0)
            {
                result += " kMGTP"[p];
            }

            return result + "b";
        }
    }
}