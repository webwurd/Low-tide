using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace LowTide.Core
{
    /// <summary>JSON save format (port of autoload/save_system.gd; same schema, version 1).</summary>
    public static class SaveData
    {
        public const int Version = 1;

        public static JObject ToJson(GameSession s, string location)
        {
            return new JObject
            {
                ["version"] = Version,
                ["location"] = location,
                ["clock"] = new JObject { ["day"] = s.Clock.Day, ["minute"] = s.Clock.MinuteOfDay },
                ["state"] = s.State.ToJson(),
                ["director"] = s.Director.ToJson(),
            };
        }

        public static string Save(GameSession s, string location) => ToJson(s, location).ToString(Formatting.None);

        /// <summary>Applies a save to the session; returns the saved location, or "" if the save is unusable.</summary>
        public static string Load(GameSession s, string json)
        {
            JObject root;
            try { root = JObject.Parse(json); }
            catch (JsonException) { return ""; }
            if (root["version"] == null || (int)root["version"] != Version) return "";
            s.Clock.SetTime((int)root["clock"]["day"], (double)root["clock"]["minute"]);
            s.State.FromJson((JObject)root["state"]);
            s.Director.FromJson((JObject)root["director"]);
            return (string)root["location"];
        }
    }
}
