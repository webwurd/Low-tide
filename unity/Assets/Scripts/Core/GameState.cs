using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json.Linq;

namespace LowTide.Core
{
    public sealed class LogEntry
    {
        public int Day;
        public string Text = "";
    }

    /// <summary>Story state (port of autoload/game_state.gd): discoveries, flags, trust, satchel, logbook.</summary>
    public sealed class GameState
    {
        readonly GameClock clock;
        public GameState(GameClock clock) { this.clock = clock; }

        public readonly Dictionary<string, bool> Discovered = new Dictionary<string, bool>();
        public readonly Dictionary<string, int> DiscoveredDay = new Dictionary<string, int>();
        public readonly Dictionary<string, bool> Flags = new Dictionary<string, bool>();
        public readonly Dictionary<string, int> FlagDay = new Dictionary<string, int>();
        public readonly List<string> ItemList = new List<string>();
        public readonly Dictionary<string, double> ReactionLast = new Dictionary<string, double>();
        public readonly List<LogEntry> Logbook = new List<LogEntry>();
        public int Trust;
        public string Zone = "cottage";
        public string Location = "cottage";
        public string Ending = "";

        public event Action<string> DiscoveredChanged;
        public event Action<string> NotePosted;

        public void Reset()
        {
            Discovered.Clear(); DiscoveredDay.Clear(); Flags.Clear(); Logbook.Clear();
            ItemList.Clear(); FlagDay.Clear(); ReactionLast.Clear();
            Ending = "";
            Trust = 0;
        }

        public bool Discover(string id)
        {
            if (string.IsNullOrEmpty(id) || Discovered.ContainsKey(id)) return false;
            Discovered[id] = true;
            DiscoveredDay[id] = clock.Day;
            DiscoveredChanged?.Invoke(id);
            return true;
        }

        public void SetFlag(string name, bool value = true)
        {
            Flags[name] = value;
            FlagDay[name] = clock.Day;
        }

        public void ClearFlag(string name)
        {
            Flags.Remove(name);
            FlagDay.Remove(name);
        }

        public bool HasFlag(string name) => Flags.TryGetValue(name, out var v) && v;
        public bool HasItem(string id) => ItemList.Contains(id);

        public void GiveItem(string id)
        {
            if (ItemList.Contains(id)) return;
            ItemList.Add(id);
            Note("Added to satchel: " + Items.Title(id));
        }

        public void Note(string text) => NotePosted?.Invoke(text);
        public void AddLog(int day, string text) => Logbook.Add(new LogEntry { Day = day, Text = text });

        public IEnumerable<string> ActiveFlags() => Flags.Where(kv => kv.Value).Select(kv => kv.Key).OrderBy(k => k, StringComparer.Ordinal);

        public JObject ToJson()
        {
            var o = new JObject();
            o["discovered"] = new JObject(Discovered.Select(kv => new JProperty(kv.Key, kv.Value)));
            o["discovered_day"] = new JObject(DiscoveredDay.Select(kv => new JProperty(kv.Key, kv.Value)));
            o["flags"] = new JObject(Flags.Select(kv => new JProperty(kv.Key, kv.Value)));
            o["trust"] = Trust;
            o["logbook"] = new JArray(Logbook.Select(e => new JObject { ["day"] = e.Day, ["text"] = e.Text }));
            o["items"] = new JArray(ItemList);
            o["flag_day"] = new JObject(FlagDay.Select(kv => new JProperty(kv.Key, kv.Value)));
            o["reaction_last"] = new JObject(ReactionLast.Select(kv => new JProperty(kv.Key, kv.Value)));
            return o;
        }

        public void FromJson(JObject d)
        {
            Reset();
            if (d["discovered"] is JObject dis) foreach (var p in dis.Properties()) Discovered[p.Name] = (bool)p.Value;
            if (d["discovered_day"] is JObject dd) foreach (var p in dd.Properties()) DiscoveredDay[p.Name] = (int)p.Value;
            if (d["flags"] is JObject fl) foreach (var p in fl.Properties()) Flags[p.Name] = (bool)p.Value;
            Trust = d["trust"] != null ? (int)d["trust"] : 0;
            if (d["items"] is JArray its) foreach (var t in its) ItemList.Add((string)t);
            if (d["flag_day"] is JObject fd) foreach (var p in fd.Properties()) FlagDay[p.Name] = (int)p.Value;
            if (d["reaction_last"] is JObject rl) foreach (var p in rl.Properties()) ReactionLast[p.Name] = (double)p.Value;
            if (d["logbook"] is JArray lb)
                foreach (var e in lb) Logbook.Add(new LogEntry { Day = (int)e["day"], Text = (string)e["text"] });
        }
    }
}
