using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using NUnit.Framework;
using Newtonsoft.Json.Linq;

namespace LowTide.Core.Tests
{
    public class LogicParityTests
    {
        static string Sha256(string text)
        {
            using (var sha = SHA256.Create())
                return string.Concat(sha.ComputeHash(Encoding.UTF8.GetBytes(text)).Select(b => b.ToString("x2")));
        }

        static JToken StateSpec(string name) =>
            Fx.LoadObj("spec")["states"].First(s => (string)s["name"] == name);

        [Test]
        public void DaysMatch()
        {
            var fx = Fx.LoadObj("days");
            Assert.AreEqual((double)fx["wake_minute"], Days.WakeMinute);
            Assert.AreEqual((int)fx["last_day"], Days.LastDay);
            foreach (var d in (JArray)fx["days"])
            {
                var got = Days.Get((int)d["day"]);
                Assert.AreEqual((string)d["title"], got.Title);
                Assert.AreEqual((string)d["weather"], got.Weather);
                Assert.AreEqual((string)d["barometer"], got.Barometer);
                Assert.AreEqual((double)d["fog_density"], got.FogDensity, 1e-9);
                Assert.AreEqual((string)d["fog_tint"], got.FogTintHex);
                Assert.AreEqual((double)d["light_scale"], got.LightScale, 1e-9);
                Assert.AreEqual((bool)d["rain"], got.Rain);
                Assert.AreEqual((double)d["wave_height"], got.WaveHeight, 1e-9);
                Assert.AreEqual((double)d["wind_db"], got.WindDb, 1e-9);
                Assert.AreEqual((double)d["lamp_after"], got.LampAfter, 1e-9);
                Assert.AreEqual((string)d["morning_conv"], got.MorningConv);
                Assert.AreEqual((string)d["evening_conv"], got.EveningConv);
            }
        }

        [Test]
        public void ConditionsMatchForEveryStateAndCondition()
        {
            var s = Fx.NewSession();
            var results = (JObject)Fx.LoadObj("conditions")["results"];
            int n = 0;
            foreach (var st in (JArray)Fx.LoadObj("spec")["states"])
            {
                Fx.Apply(s, st);
                var row = (JObject)results[(string)st["name"]];
                foreach (var p in row.Properties())
                {
                    Assert.AreEqual((bool)p.Value, Conditions.Check(s, new[] { p.Name }), string.Format("state '{0}' condition '{1}'", st["name"], p.Name));
                    n++;
                }
            }
            Assert.Greater(n, 1500);
        }

        [Test]
        public void ConversationsResolveIdenticallyForEveryState()
        {
            var s = Fx.NewSession();
            var fx = Fx.LoadObj("conversations");
            var ids = ((JArray)fx["ids"]).Select(x => (string)x).ToList();
            var results = (JObject)fx["results"];
            int n = 0;
            foreach (var st in (JArray)Fx.LoadObj("spec")["states"])
            {
                Fx.Apply(s, st);
                var row = (JObject)results[(string)st["name"]];
                foreach (var id in ids)
                {
                    var want = row[id];
                    var got = s.Convs.GetConv(s, id);
                    string where = string.Format("state '{0}' conv '{1}'", st["name"], id);
                    Assert.AreEqual((string)want["hash"], got.IsEmpty ? "" : Sha256(Conversations.Canon(got)), where);
                    if (!got.IsEmpty) Assert.AreEqual((int)want["options"], got.Options.Count, where);
                    n++;
                }
            }
            Assert.Greater(n, 1500);
        }

        [Test]
        public void ReactionScenariosMatch()
        {
            var s = Fx.NewSession();
            var want = Fx.LoadObj("reactions");
            foreach (var sc in (JArray)Fx.LoadObj("spec")["reaction_scenarios"])
            {
                Fx.Apply(s, sc["state"]);
                var got = new List<string>();
                foreach (var step in (JArray)sc["steps"])
                {
                    if ((string)step[0] == "tick")
                    {
                        got.Add(s.Reactions.Tick());
                        s.Radio.ClearQueue();
                        if (s.Radio.Active) s.Radio.Dismiss();
                        s.Radio.ClearQueue();
                    }
                    else s.Clock.Advance((double)step[1]);
                }
                string name = (string)sc["name"];
                CollectionAssert.AreEqual(((JArray)want[name]["ticks"]).Select(x => (string)x).ToList(), got, "reaction scenario " + name);
                Assert.AreEqual((int)want[name]["trust"], s.State.Trust, name + " trust");
                CollectionAssert.AreEqual(((JArray)want[name]["flags"]).Select(x => (string)x).ToList(), s.State.ActiveFlags().ToList(), name + " flags");
            }
        }

        [Test]
        public void RadioScenariosMatchStepByStep()
        {
            var s = Fx.NewSession();
            int hidden = 0;
            s.Radio.Hidden += () => hidden++;
            var want = Fx.LoadObj("radio");
            foreach (var sc in (JArray)Fx.LoadObj("spec")["radio_scenarios"])
            {
                Fx.Apply(s, sc["state"]);
                hidden = 0;
                var snaps = (JArray)want[(string)sc["name"]];
                int i = 0;
                foreach (var op in (JArray)sc["ops"])
                {
                    switch ((string)op[0])
                    {
                        case "play": s.Radio.Play(s.Convs.GetConv(s, (string)op[1])); break;
                        case "choose": s.Radio.Choose((int)op[1]); break;
                        case "dismiss": s.Radio.Dismiss(); break;
                    }
                    var w = snaps[i++];
                    string where = string.Format("radio scenario '{0}' after op {1}", sc["name"], i);
                    Assert.AreEqual((bool)w["active"], s.Radio.Active, where + " active");
                    Assert.AreEqual((string)w["current"], s.Radio.Current.IsEmpty ? "" : s.Radio.Current.Id, where + " current");
                    Assert.AreEqual((bool)w["awaiting"], s.Radio.AwaitingChoice, where + " awaiting");
                    CollectionAssert.AreEqual(((JArray)w["queue"]).Select(x => (string)x).ToList(), s.Radio.QueueIds.ToList(), where + " queue");
                    Assert.AreEqual((int)w["hidden"], hidden, where + " hidden");
                    Assert.AreEqual((int)w["trust"], s.State.Trust, where + " trust");
                    CollectionAssert.AreEqual(((JArray)w["flags"]).Select(x => (string)x).ToList(), s.State.ActiveFlags().ToList(), where + " flags");
                }
            }
        }

        [Test]
        public void TrustSimulationMatchesForEveryPolicy()
        {
            var s = Fx.NewSession();
            foreach (var pol in (JArray)Fx.LoadObj("spec")["trust_policies"])
            {
                string policy = (string)pol;
                var want = Fx.LoadObj("trust_sim")[policy];
                var got = TrustSimulation.Run(s, policy);
                var steps = (JArray)want["steps"];
                Assert.AreEqual(steps.Count, got.Steps.Count, policy + " step count");
                for (int i = 0; i < steps.Count; i++)
                {
                    string where = string.Format("{0} step {1} ({2})", policy, i, steps[i]["conv"]);
                    Assert.AreEqual((string)steps[i]["conv"], got.Steps[i].Conv, where);
                    Assert.AreEqual((string)steps[i]["sig"]["hash"], got.Steps[i].Resolved.IsEmpty ? "" : Sha256(Conversations.Canon(got.Steps[i].Resolved)), where + " resolved conv");
                    CollectionAssert.AreEqual(((JArray)steps[i]["chosen"]).Select(x => (int)x).ToList(), got.Steps[i].Chosen, where + " choices");
                    Assert.AreEqual((int)steps[i]["trust"], got.Steps[i].Trust, where + " trust");
                    CollectionAssert.AreEqual(((JArray)steps[i]["flags"]).Select(x => (string)x).ToList(), got.Steps[i].Flags, where + " flags");
                }
                Assert.AreEqual((int)want["t6"], got.T6, policy + " t6");
                Assert.AreEqual((int)want["t7"], got.T7, policy + " t7");
                Assert.AreEqual((string)want["ending"], got.Ending, policy + " ending");
                CollectionAssert.AreEqual(((JArray)want["offered"]).Select(x => (string)x).ToList(), got.Offered, policy + " offered");
                CollectionAssert.AreEqual(((JArray)want["items"]).Select(x => (string)x).ToList(), got.Items, policy + " items");
                Assert.AreEqual((bool)want["admitted"], got.Admitted);
                Assert.AreEqual((bool)want["partial"], got.Partial);
                Assert.AreEqual((bool)want["stonewalled"], got.Stonewalled);
            }
        }

        [Test]
        public void TrustOutcomesHoldTheDesignGuarantees()
        {
            var s = Fx.NewSession();
            var honest = TrustSimulation.Run(s, "honest");
            var bad = TrustSimulation.Run(s, "dishonest");
            Assert.AreEqual("b", honest.Ending);
            Assert.AreEqual("c", bad.Ending);
            Assert.GreaterOrEqual(honest.T6 - 12, 4, "honest play clears the high-trust threshold with margin");
            foreach (var p in new[] { "honest", "dishonest", "mixed3", "mixed2" })
                Assert.AreNotEqual("", TrustSimulation.Run(s, p).Ending, "no dead ends: " + p);
        }

        [Test]
        public void LogEntriesMatch()
        {
            var s = Fx.NewSession();
            var want = Fx.LoadObj("log_entries");
            foreach (var sc in (JArray)Fx.LoadObj("spec")["log_scenarios"])
            {
                Fx.Apply(s, sc["state"]);
                Assert.AreEqual((string)want[(string)sc["name"]], LogEntries.Compose(s.State, (int)sc["compose_day"]), (string)sc["name"]);
            }
        }

        [Test]
        public void EndingsMatch()
        {
            var s = Fx.NewSession();
            foreach (var p in Fx.LoadObj("endings").Properties())
            {
                var parts = p.Name.Split('|');
                s.State.Reset();
                foreach (var f in parts[1].Split(',').Where(x => x != "")) s.State.SetFlag(f);
                Assert.AreEqual((string)p.Value["name"], Endings.Name(parts[0]), p.Name);
                Assert.AreEqual((string)p.Value["body"], Endings.Body(s.State, parts[0]), p.Name);
            }
        }

        [Test]
        public void SaveFormatRoundTripsAndMatchesGodot()
        {
            var fx = Fx.LoadObj("save");
            var raw = (JObject)fx["raw"];
            var s = Fx.NewSession();
            string loc = SaveData.Load(s, raw.ToString());
            var ex = fx["expect"];
            Assert.AreEqual((string)ex["location"], loc);
            Assert.AreEqual((int)ex["day"], s.Clock.Day);
            Assert.AreEqual((double)ex["minute"], s.Clock.MinuteOfDay, 1e-9);
            Assert.AreEqual((int)ex["trust"], s.State.Trust);
            CollectionAssert.AreEqual(((JArray)ex["flags"]).Select(x => (string)x).ToList(), s.State.ActiveFlags().ToList());
            CollectionAssert.AreEqual(((JArray)ex["items"]).Select(x => (string)x).ToList(), s.State.ItemList);
            CollectionAssert.AreEquivalent(((JArray)ex["discovered"]).Select(x => (string)x).ToList(), s.State.Discovered.Keys.ToList());
            Assert.AreEqual((int)ex["logbook_count"], s.State.Logbook.Count);
            Assert.AreEqual((int)ex["phase"], (int)s.Director.Phase);
            CollectionAssert.AreEquivalent(((JArray)ex["rituals"]).Select(x => (string)x).ToList(), s.Director.Rituals.Keys.ToList());
            Assert.AreEqual((bool)ex["weights_wound"], s.Director.WeightsWound);
            Assert.AreEqual((bool)ex["lamp_lit"], s.Director.LampLit);
            Assert.AreEqual((bool)ex["dusk_nudged"], s.Director.DuskNudged);
            Assert.AreEqual(2, s.State.FlagDay["heard_tape_1"], "flag day survives");
            Assert.AreEqual(596.0, s.State.ReactionLast["r_east_bar_first"], 1e-9);

            // Re-serialise: structurally the same document Godot wrote.
            var again = SaveData.ToJson(s, loc);
            Assert.IsTrue(JToken.DeepEquals(Normalise(raw), Normalise(again)), "re-saved JSON differs from Godot's:\n" + again + "\n" + raw);
        }

        // Godot writes whole floats as 5.0 and ints as 5; treat numerically equal values as equal.
        static JToken Normalise(JToken t)
        {
            switch (t)
            {
                case JObject o:
                    var n = new JObject();
                    foreach (var p in o.Properties().OrderBy(p => p.Name, System.StringComparer.Ordinal)) n[p.Name] = Normalise(p.Value);
                    return n;
                case JArray a: return new JArray(a.Select(Normalise));
                case JValue v when v.Type == JTokenType.Integer || v.Type == JTokenType.Float: return new JValue(System.Convert.ToDouble(v.Value));
                default: return t.DeepClone();
            }
        }

        [Test]
        public void BadSavesAreRejected()
        {
            var s = Fx.NewSession();
            Assert.AreEqual("", SaveData.Load(s, "not json"));
            Assert.AreEqual("", SaveData.Load(s, "{\"version\": 99}"));
        }
    }
}
