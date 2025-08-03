using System;
using System.IO;
using System.Text.RegularExpressions;
using Newtonsoft.Json;


namespace NablaFs
{
    internal class Settings
    {
        #region Ctors
        private Settings()
        {
            Terminal     = "cmd.exe";
            Notepad      = "notepad.exe";
            HexEditor    = "";
            ThreadsCount = Environment.ProcessorCount / 2;
            ChunkSize    = 32 * 1024 * 1024;
        }
        #endregion

        #region Properties
        public string Terminal { get; set; }

        public string HexEditor { get; set; }

        public string Notepad { get; set; }

        [JsonIgnore]
        public int ThreadsCount { get; private set; }

        [JsonIgnore]
        public int ChunkSize { get; private set; }

        [JsonProperty(PropertyName = "ThreadsCount")]
        private string? Threads { get; set; }

        [JsonProperty(PropertyName = "ChunkSize")]
        private string? Chunk { get; set; }
        #endregion

        #region Static
        public static Settings Load(string fname)
        {
            Settings? settings = null;

            try
            {
                settings = JsonConvert.DeserializeObject<Settings>(File.ReadAllText(fname));
            }
            catch (Exception ex)
            {
                Utils.Warning($"Settings load from file \"{fname}\" erorr: {ex.Message}. Using default settings.");
            }

            if (settings != null)
            {
                if (settings.Chunk != null)
                {
                    string image = settings.Chunk.ToLower();

                    if (Regex.IsMatch(image, @"^\d{1,4}(k|m)b$"))
                    {
                        int v = Convert.ToInt32(image[..^2]);

                        if (image[^2] == 'k')
                        {
                            v *= 1024;
                        }
                        else if (image[^2] == 'm')
                        {
                            v *= 1024 * 1024;
                        }

                        if (v > 0 && v < 1024 * 1024 * 1024)
                        {
                            settings.ChunkSize = v;
                        }
                    }
                }

                if (settings.Threads != null)
                {
                    string image = settings.Threads;

                    if (image.Equals("min", StringComparison.CurrentCultureIgnoreCase))
                    {
                        settings.ThreadsCount = 1;
                    }

                    if (Regex.IsMatch(image, @"^/\d{1,2}$"))
                    {
                        settings.ThreadsCount = Math.Max(1, Environment.ProcessorCount / Convert.ToInt32(image[1..]));
                    }

                    if (Regex.IsMatch(image, @"^\d{1,2}$"))
                    {
                        settings.ThreadsCount = Math.Min(Environment.ProcessorCount, Convert.ToInt32(image));
                    }
                }

                return settings;
            }

            return new();
        }
        #endregion
    }
}