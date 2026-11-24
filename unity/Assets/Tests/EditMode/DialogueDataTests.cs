using System.IO;
using System.Linq;
using NUnit.Framework;
using Newtonsoft.Json.Linq;

namespace LowTide.Core.Tests
{
    /// <summary>Integrity checks on the shared dialogue data, independent of the Godot fixtures.</summary>
    public class DialogueDataTests
    {
        [Test]
        public void UnityCopyOfDialogueIsIdenticalToTheRepoSourceOfTruth()
        {
            string root = File.ReadAllText(Path.Combine(Fx.RepoRoot, "dialogue", "dialogue.json"));
            Assert.AreEqual(root, Fx.DialogueJson, "run tools/sync_unity_data.sh");
        }

        [Test]
        public void EveryChainedNextAndReactionTargetExists()
        {
            var s = Fx.NewSession();
            var ids = new System.Collections.Generic.HashSet<string>(s.Convs.ConvIds);
            var root = JObject.Parse(Fx.DialogueJson);
            foreach (var c in ((JObject)root["convs"]).Properties())
                foreach (var v in (JArray)c.Value)
                    foreach (var o in (JArray)v["options"] ?? new JArray())
                        if (o["next"] != null) Assert.IsTrue(ids.Contains((string)o["next"]), c.Name + " -> next " + o["next"]);
            foreach (var r in s.Convs.Reactions) Assert.IsTrue(ids.Contains(r.Conv), "reaction " + r.Id + " -> " + r.Conv);
        }

        [Test]
        public void EveryTapeItemHasATapeAndEveryDayHasConversations()
        {
            var s = Fx.NewSession();
            foreach (var id in Items.Data.Keys.Where(k => k.StartsWith("tape_")))
                Assert.IsNotNull(s.Convs.Tape(id), id);
            for (int d = 1; d <= Days.LastDay; d++)
            {
                s.State.Reset();
                s.Director.BeginDay(d);
                Assert.IsTrue(s.Convs.ConvIds.Contains(Days.Get(d).MorningConv), "morning " + d);
                Assert.IsTrue(s.Convs.ConvIds.Contains(Days.Get(d).EveningConv), "evening " + d);
            }
        }

        [Test]
        public void NoRealStationNameLeaks()
        {
            StringAssert.DoesNotContain("Rockland", Fx.DialogueJson);
            StringAssert.Contains("Station Penobscot", Fx.DialogueJson);
        }

        [Test]
        public void ResolvedConversationsNeverShowMoreThanTwoOptions()
        {
            var s = Fx.NewSession();
            foreach (var st in (JArray)Fx.LoadObj("spec")["states"])
            {
                Fx.Apply(s, st);
                foreach (var id in s.Convs.ConvIds)
                    Assert.LessOrEqual(s.Convs.GetConv(s, id).Options.Count, 2, id);
            }
        }
    }
}
