using System;
using System.IO;
using Newtonsoft.Json.Linq;

namespace LowTide.Core.Tests
{
    /// <summary>Locates and loads the golden fixtures exported by the Godot build (tools/export_fixtures.gd).</summary>
    public static class Fx
    {
        static string dir;

        public static string Dir
        {
            get
            {
                if (dir != null) return dir;
                string env = Environment.GetEnvironmentVariable("LOWTIDE_FIXTURES");
                if (!string.IsNullOrEmpty(env) && File.Exists(Path.Combine(env, "spec.json"))) return dir = env;
                foreach (var start in new[] { AppContext.BaseDirectory, Directory.GetCurrentDirectory() })
                {
                    var d = new DirectoryInfo(start);
                    while (d != null)
                    {
                        string cand = Path.Combine(d.FullName, "Fixtures");
                        if (File.Exists(Path.Combine(cand, "spec.json"))) return dir = cand;
                        cand = Path.Combine(d.FullName, "unity", "Fixtures");
                        if (File.Exists(Path.Combine(cand, "spec.json"))) return dir = cand;
                        d = d.Parent;
                    }
                }
                throw new DirectoryNotFoundException("Fixtures/spec.json not found; set LOWTIDE_FIXTURES.");
            }
        }

        public static string UnityRoot => Directory.GetParent(Dir).FullName;
        public static string RepoRoot => Directory.GetParent(UnityRoot).FullName;

        public static JToken Load(string name) => JToken.Parse(File.ReadAllText(Path.Combine(Dir, name + ".json")));
        public static JObject LoadObj(string name) => (JObject)Load(name);
        public static string DialogueJson => File.ReadAllText(Path.Combine(UnityRoot, "Assets", "StreamingAssets", "dialogue.json"));

        public static GameSession NewSession() => new GameSession(new Conversations(DialogueJson));

        /// <summary>Applies a spec state exactly like tools/export_fixtures.gd's _apply().</summary>
        public static void Apply(GameSession s, JToken spec)
        {
            s.Radio.ClearQueue();
            if (s.Radio.Active) s.Radio.Dismiss();
            s.Radio.ClearQueue();
            s.State.Reset();
            int day = (int)spec["day"];
            s.Director.BeginDay(day);
            s.Clock.SetTime(day, (double)spec["minute"]);
            s.State.Trust = (int)spec["trust"];
            var fdays = spec["flag_days"] as JObject;
            foreach (var f in (JArray)spec["flags"])
            {
                string name = (string)f;
                s.State.SetFlag(name);
                if (fdays != null && fdays[name] != null) s.State.FlagDay[name] = (int)fdays[name];
            }
            foreach (var it in (JArray)spec["items"]) s.State.ItemList.Add((string)it);
            if (spec["discovered"] is JObject disc)
                foreach (var p in disc.Properties())
                {
                    s.State.Discovered[p.Name] = true;
                    s.State.DiscoveredDay[p.Name] = (int)p.Value;
                }
            s.State.Zone = (string)spec["zone"];
            s.State.Location = (string)spec["location"];
            s.Director.Phase = (Phase)(int)spec["phase"];
        }
    }
}
