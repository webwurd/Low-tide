using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json.Linq;

namespace LowTide.Core
{
    public enum Phase { Morning = 0, Expedition = 1, Evening = 2 }

    /// <summary>Runs the daily structure: morning rituals, expedition, evening (port of autoload/day_director.gd).</summary>
    public sealed class DayDirector
    {
        public static readonly string[] FirstFour = { "stove", "weights", "barometer", "tide_table" };
        public static readonly string[] AllRituals = { "stove", "weights", "barometer", "tide_table", "checkin" };
        public const double DuskMinute = 990.0;           // 16:30 Clara nudges
        public const double ForcedHomeMinute = 1260.0;    // 21:00 Arthur heads in on his own

        readonly GameSession s;
        public Phase Phase = Phase.Morning;
        public readonly Dictionary<string, bool> Rituals = new Dictionary<string, bool>();
        public bool WeightsWound, LampLit, LogWritten, EveningCallDone, DuskNudged;

        public event Action<Phase> PhaseChanged;
        public event Action<string> RitualDone;
        public event Action<int> DayStarted;
        public event Action WeekEnded;

        public DayDirector(GameSession session) { s = session; }

        public DayData Data() => Days.Get(s.Clock.Day);

        public void BeginDay(int day)
        {
            s.Clock.SetTime(day, Days.WakeMinute);
            Rituals.Clear();
            WeightsWound = false; LampLit = false; LogWritten = false; EveningCallDone = false; DuskNudged = false;
            SetPhase(Phase.Morning);
            DayStarted?.Invoke(day);
        }

        void SetPhase(Phase p) { Phase = p; PhaseChanged?.Invoke(p); }

        public void CompleteRitual(string id)
        {
            if (Rituals.ContainsKey(id)) return;
            Rituals[id] = true;
            if (id == "weights") WeightsWound = true;
            RitualDone?.Invoke(id);
        }

        public int RitualCount => Rituals.Count;
        public bool CanCheckIn() => FirstFour.All(r => Rituals.ContainsKey(r));
        public bool MorningComplete() => Rituals.Count >= AllRituals.Length;
        public void StepOutside() { if (Phase == Phase.Morning) SetPhase(Phase.Expedition); }
        public bool LampReady() => s.Clock.MinuteOfDay >= Data().LampAfter;
        public void LightLamp() { LampLit = true; SetPhase(Phase.Evening); }
        public void ForceEvening() { if (Phase != Phase.Evening) SetPhase(Phase.Evening); }

        public void WriteLog()
        {
            if (LogWritten) return;
            LogWritten = true;
            s.State.AddLog(s.Clock.Day, LogEntries.Compose(s.State, s.Clock.Day));
        }

        public void StartEveningCall() { EveningCallDone = true; }

        /// <summary>The last evening is not over until Arthur has made his choice.</summary>
        public bool EndingChosen() => s.State.HasFlag("ending_a") || s.State.HasFlag("ending_b") || s.State.HasFlag("ending_c");
        public bool FinalPending() => s.Clock.Day >= Days.LastDay && !EndingChosen();

        public bool CanSleep()
        {
            if (FinalPending()) return false;
            return LampLit && LogWritten && EveningCallDone;
        }

        public string SleepBlockers()
        {
            if (!LampLit) return "The lamp isn't lit yet.";
            if (!LogWritten) return "I haven't written up the log.";
            if (!EveningCallDone) return "I should call Clara before turning in.";
            if (FinalPending()) return "I haven't decided what to do about the tapes.";
            return "";
        }

        /// <summary>Ends the day. Returns false when the final day has been completed.</summary>
        public bool Sleep()
        {
            if (s.Clock.Day >= Days.LastDay)
            {
                WeekEnded?.Invoke();
                return false;
            }
            BeginDay(s.Clock.Day + 1);
            return true;
        }

        public JObject ToJson()
        {
            var o = new JObject();
            o["phase"] = (int)Phase;
            o["rituals"] = new JObject(Rituals.Select(kv => new JProperty(kv.Key, kv.Value)));
            o["weights_wound"] = WeightsWound;
            o["lamp_lit"] = LampLit;
            o["log_written"] = LogWritten;
            o["evening_call_done"] = EveningCallDone;
            o["dusk_nudged"] = DuskNudged;
            return o;
        }

        public void FromJson(JObject d)
        {
            Phase = (Phase)(d["phase"] != null ? (int)d["phase"] : 0);
            Rituals.Clear();
            if (d["rituals"] is JObject r) foreach (var p in r.Properties()) Rituals[p.Name] = (bool)p.Value;
            WeightsWound = d["weights_wound"] != null && (bool)d["weights_wound"];
            LampLit = d["lamp_lit"] != null && (bool)d["lamp_lit"];
            LogWritten = d["log_written"] != null && (bool)d["log_written"];
            EveningCallDone = d["evening_call_done"] != null && (bool)d["evening_call_done"];
            DuskNudged = d["dusk_nudged"] != null && (bool)d["dusk_nudged"];
        }
    }
}
