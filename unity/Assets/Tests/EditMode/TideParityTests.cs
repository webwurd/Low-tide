using NUnit.Framework;
using Newtonsoft.Json.Linq;

namespace LowTide.Core.Tests
{
    public class TideParityTests
    {
        const double Tol = 1e-9;

        [Test]
        public void WaterHeightMatchesGodotAtEverySample()
        {
            var fx = Fx.LoadObj("tide");
            int n = 0;
            foreach (var s in (JArray)fx["samples"])
            {
                double abs = (double)s[0], want = (double)s[1];
                Assert.AreEqual(want, TideModel.WaterHeightAbs(abs), Tol, "abs minute " + abs);
                n++;
            }
            Assert.Greater(n, 900);
        }

        [Test]
        public void StormWeightMatches()
        {
            foreach (var s in (JArray)Fx.LoadObj("tide")["storm"])
                Assert.AreEqual((double)s[1], TideModel.StormWeight((double)s[0]), Tol, "abs " + s[0]);
        }

        [Test]
        public void ExtremesTablesMatch()
        {
            var ext = (JObject)Fx.LoadObj("tide")["extremes"];
            foreach (var p in ext.Properties())
            {
                var got = TideModel.ExtremesForDay(int.Parse(p.Name));
                var want = (JArray)p.Value;
                Assert.AreEqual(want.Count, got.Count, "extreme count day " + p.Name);
                for (int i = 0; i < got.Count; i++)
                {
                    Assert.AreEqual((double)want[i]["minute"], got[i].Minute, Tol);
                    Assert.AreEqual((double)want[i]["height"], got[i].Height, Tol);
                    Assert.AreEqual((bool)want[i]["high"], got[i].High);
                }
            }
        }

        [Test]
        public void LowMinuteOfDayMatches()
        {
            foreach (var p in ((JObject)Fx.LoadObj("tide")["low_minute_of_day"]).Properties())
                Assert.AreEqual((double)p.Value, TideModel.LowMinuteOfDay(int.Parse(p.Name)), Tol, "day " + p.Name);
        }

        [Test]
        public void DepthBandsAndSpeedMultipliersMatch()
        {
            foreach (var b in (JArray)Fx.LoadObj("tide")["bands"])
            {
                double depth = (double)b[0];
                Assert.AreEqual((string)b[1], TideModel.DepthBand(depth), "band at " + depth);
                Assert.AreEqual((double)b[2], TideModel.SpeedMultiplier(depth), Tol, "speed at " + depth);
            }
        }

        [Test]
        public void SandbarGateAndNamedHeightsMatch()
        {
            var fx = Fx.LoadObj("tide");
            foreach (var g in (JArray)fx["gates"])
                Assert.AreEqual((bool)g[1], TideModel.SandbarsOpen((double)g[0]), "gate at " + g[0]);
            foreach (var w in (JArray)fx["water_height"])
                Assert.AreEqual((double)w[2], TideModel.WaterHeight((int)w[0], (double)w[1]), Tol);
        }

        [Test]
        public void TideIsContinuousAcrossTheWholeWeek()
        {
            double maxStep = 0;
            for (int m = 0; m < 1440 * 7; m++)
                maxStep = System.Math.Max(maxStep, System.Math.Abs(TideModel.WaterHeightAbs(m + 1.0) - TideModel.WaterHeightAbs(m)));
            Assert.Less(maxStep, 0.05);
        }
    }
}
