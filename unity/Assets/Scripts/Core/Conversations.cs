using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json.Linq;

namespace LowTide.Core
{
    public sealed class ConvOption
    {
        public string Text = "";
        public string Reply = "";
        public int Trust;
        public string[] Set = new string[0];
        public string[] Clear = new string[0];
        public string Next = "";
    }

    public sealed class Conv
    {
        public string Id = "";
        public string Speaker = "";
        public int Priority = 2;
        public string Text = "";
        public List<ConvOption> Options = new List<ConvOption>();
        public bool IsEmpty;
        public static readonly Conv Empty = new Conv { IsEmpty = true };
    }

    public sealed class ReactionDef
    {
        public string Id = "";
        public string[] When = new string[0];
        public string Conv = "";
        public bool Once;
        public double Cooldown;
        public bool Anywhere;
    }

    public sealed class TapeLine { public double T; public string Text = ""; }
    public sealed class TapeDef
    {
        public string Id = "";
        public string Title = "";
        public List<TapeLine> Lines = new List<TapeLine>();
    }

    /// <summary>
    /// Loads and resolves conversations from dialogue.json (port of story/conversations.gd).
    /// JSON conversations are lists of variants; the first whose `when` holds wins. Options are
    /// filtered by their own `when` and capped at two (the radio UI shows 1 / 2).
    /// </summary>
    public sealed class Conversations
    {
        public const string ClaraSpeaker = "CH-16 // CLARA (COAST GUARD DISPATCH)";
        readonly JObject convs;
        public readonly List<ReactionDef> Reactions = new List<ReactionDef>();
        readonly Dictionary<string, TapeDef> tapes = new Dictionary<string, TapeDef>();

        public Conversations(string json)
        {
            var root = JObject.Parse(json);
            convs = root["convs"] as JObject ?? new JObject();
            foreach (var r in (root["reactions"] as JArray) ?? new JArray())
            {
                Reactions.Add(new ReactionDef
                {
                    Id = (string)r["id"],
                    When = Strings(r["when"]),
                    Conv = (string)r["conv"],
                    Once = r["once"] != null && (bool)r["once"],
                    Cooldown = r["cooldown"] != null ? (double)r["cooldown"] : 0.0,
                    Anywhere = r["anywhere"] != null && (bool)r["anywhere"],
                });
            }
            if (root["tapes"] is JObject tp)
            {
                foreach (var p in tp.Properties())
                {
                    var t = new TapeDef { Id = p.Name, Title = (string)p.Value["title"] };
                    foreach (var l in (JArray)p.Value["lines"])
                        t.Lines.Add(new TapeLine { T = (double)l["t"], Text = (string)l["text"] });
                    tapes[p.Name] = t;
                }
            }
        }

        public IEnumerable<string> ConvIds => convs.Properties().Select(p => p.Name);
        public IEnumerable<string> TapeIds => tapes.Keys;
        public TapeDef Tape(string id) => tapes.TryGetValue(id, out var t) ? t : null;

        static string[] Strings(JToken t) =>
            t is JArray a ? a.Select(x => (string)x).ToArray() : new string[0];

        public Conv GetConv(GameSession s, string id)
        {
            if (convs[id] is JArray variants)
            {
                foreach (var v in variants)
                    if (Conditions.Check(s, Strings(v["when"]))) return Normalize(s, id, (JObject)v);
                return Conv.Empty;
            }
            if (id == "opening") return GetConv(s, "morning_d1");
            return Conv.Empty;
        }

        Conv Normalize(GameSession s, string id, JObject v)
        {
            var conv = new Conv
            {
                Id = id,
                Speaker = SpeakerName((string)v["speaker"]),
                Priority = v["priority"] != null ? (int)v["priority"] : 2,
                Text = v["text"] != null ? (string)v["text"] : "",
            };
            foreach (var o in (v["options"] as JArray) ?? new JArray())
            {
                if (conv.Options.Count >= 2) break;
                if (!Conditions.Check(s, Strings(o["when"]))) continue;
                conv.Options.Add(new ConvOption
                {
                    Text = (string)o["text"],
                    Reply = o["reply"] != null ? (string)o["reply"] : "",
                    Trust = o["trust"] != null ? (int)o["trust"] : 0,
                    Set = Strings(o["set"]),
                    Clear = Strings(o["clear"]),
                    Next = o["next"] != null ? (string)o["next"] : "",
                });
            }
            return conv;
        }

        static string SpeakerName(string key)
        {
            if (key == "arthur") return "ARTHUR";
            return ClaraSpeaker;
        }

        /// <summary>Canonical string used by the parity fixtures.</summary>
        public static string Canon(Conv c)
        {
            if (c.IsEmpty) return "";
            var parts = new List<string> { c.Speaker, c.Priority.ToString(), c.Text };
            foreach (var o in c.Options)
                parts.Add(string.Format("{0}~{1}~{2}~{3}~{4}~{5}", o.Text, o.Trust, string.Join(",", o.Set), string.Join(",", o.Clear), o.Next, o.Reply));
            return string.Join("|", parts);
        }
    }
}
