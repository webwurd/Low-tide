using System.Collections.Generic;
using System.Linq;

namespace LowTide.Core
{
    /// <summary>
    /// Plays a whole week through the real radio logic under an answer policy (port of the
    /// simulation in tools/export_fixtures.gd). Used by tests, and as a regression guard for
    /// trust thresholds whenever dialogue changes.
    /// </summary>
    public static class TrustSimulation
    {
        public sealed class Step
        {
            public string Conv = "";
            public Conv Resolved = Core.Conv.Empty;
            public List<int> Chosen = new List<int>();
            public int Trust;
            public List<string> Flags = new List<string>();
        }

        public sealed class Result
        {
            public List<Step> Steps = new List<Step>();
            public int T6, T7;
            public List<string> Offered = new List<string>();
            public string Ending = "";
            public List<string> Items = new List<string>();
            public bool Admitted, Partial, Stonewalled;
        }

        sealed class ScriptStep { public string Give, Flag, Conv; }

        static List<ScriptStep> Script(int day)
        {
            ScriptStep G(string x) => new ScriptStep { Give = x };
            ScriptStep F(string x) => new ScriptStep { Flag = x };
            ScriptStep C(string x) => new ScriptStep { Conv = x };
            switch (day)
            {
                case 1: return new List<ScriptStep> { C("morning_d1"), G("canister"), C("shipwreck"), G("tape_1"), C("seacave"), C("evening_d1") };
                case 2: return new List<ScriptStep> { C("morning_d2"), F("heard_tape_1"), C("evening_d2") };
                case 3: return new List<ScriptStep> { C("morning_d3"), G("cable_tag"), C("cable"), G("tape_3"), F("heard_tape_3"), C("evening_d3") };
                case 4: return new List<ScriptStep> { C("morning_d4"), C("midday_d4"), G("tape_4"), F("heard_tape_4"), C("evening_d4") };
                case 5: return new List<ScriptStep> { C("morning_d5"), G("tape_2"), C("vault"), F("heard_tape_2"), C("evening_d5") };
                case 6: return new List<ScriptStep> { G("tape_5"), F("heard_tape_5"), G("tape_6"), F("heard_tape_6"), C("morning_d6"), C("evening_d6") };
                default: return new List<ScriptStep> { C("morning_d7"), C("evening_d7") };
            }
        }

        static int Pick(IList<ConvOption> opts, string policy, int[] n)
        {
            n[0]++;
            for (int i = 0; i < opts.Count; i++)
            {
                var sets = opts[i].Set;
                if (sets.Contains("ending_a") || sets.Contains("ending_b") || sets.Contains("ending_c"))
                {
                    string want = policy == "honest" ? "ending_b" : (policy == "dishonest" ? "ending_c" : "ending_a");
                    for (int j = 0; j < opts.Count; j++)
                        if (opts[j].Set.Contains(want)) return j;
                    return 0;
                }
            }
            int best = 0, worst = 0;
            for (int i = 0; i < opts.Count; i++)
            {
                if (opts[i].Trust > opts[best].Trust) best = i;
                if (opts[i].Trust < opts[worst].Trust) worst = i;
            }
            switch (policy)
            {
                case "honest": return best;
                case "dishonest": return worst;
                case "mixed3": return n[0] % 3 == 0 ? worst : best;
                default: return n[0] % 2 == 0 ? worst : best;
            }
        }

        static List<int> Say(GameSession s, string id, string policy, int[] n)
        {
            var chosen = new List<int>();
            s.Radio.ClearQueue();
            if (s.Radio.Active) s.Radio.Dismiss();
            s.Radio.ClearQueue();
            var conv = s.Convs.GetConv(s, id);
            if (conv.IsEmpty) return chosen;
            s.Radio.Play(conv);
            for (int guard = 0; guard < 6; guard++)
            {
                if (!s.Radio.Active) break;
                var opts = s.Radio.Current.Options;
                if (opts.Count > 0 && s.Radio.AwaitingChoice)
                {
                    int idx = Pick(opts, policy, n);
                    chosen.Add(idx);
                    s.Radio.Choose(idx);
                }
                s.Radio.Dismiss();
            }
            return chosen;
        }

        public static Result Run(GameSession s, string policy)
        {
            s.State.Reset();
            var res = new Result();
            var counter = new[] { 0 };
            for (int day = 1; day <= 7; day++)
            {
                s.Director.BeginDay(day);
                foreach (var step in Script(day))
                {
                    if (step.Give != null) s.State.GiveItem(step.Give);
                    if (step.Flag != null) s.State.SetFlag(step.Flag);
                    if (step.Conv == null) continue;
                    if (step.Conv == "evening_d6") res.T6 = s.State.Trust;
                    if (step.Conv == "evening_d7")
                        foreach (var o in s.Convs.GetConv(s, "evening_d7").Options)
                            res.Offered.Add(o.Set.Length > 0 ? o.Set[0] : "?");
                    var resolved = s.Convs.GetConv(s, step.Conv);
                    var chosen = Say(s, step.Conv, policy, counter);
                    res.Steps.Add(new Step { Conv = step.Conv, Resolved = resolved, Chosen = chosen, Trust = s.State.Trust, Flags = s.State.ActiveFlags().ToList() });
                }
            }
            res.T7 = s.State.Trust;
            foreach (var k in new[] { "a", "b", "c" })
                if (s.State.HasFlag("ending_" + k)) res.Ending = k;
            res.Items = s.State.ItemList.ToList();
            res.Admitted = s.State.HasFlag("clara_admitted");
            res.Partial = s.State.HasFlag("clara_partial");
            res.Stonewalled = s.State.HasFlag("clara_stonewalled");
            return res;
        }
    }
}
