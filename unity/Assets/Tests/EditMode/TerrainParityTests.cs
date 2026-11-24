using NUnit.Framework;
using Newtonsoft.Json.Linq;

namespace LowTide.Core.Tests
{
    public class TerrainParityTests
    {
        const double Tol = 1e-6;

        [Test]
        public void HeightsZonesAndSurfacesMatchOnTheWholeGrid()
        {
            var fx = Fx.LoadObj("terrain");
            double min = (double)fx["min"], step = (double)fx["step"];
            int count = (int)fx["count"];
            var heights = (JArray)fx["heights"];
            var zones = (JArray)fx["zones"];
            var surfaces = (JArray)fx["surfaces"];
            int i = 0, zoneMismatch = 0, surfMismatch = 0;
            for (int zi = 0; zi < count; zi++)
                for (int xi = 0; xi < count; xi++, i++)
                {
                    double x = min + xi * step, z = min + zi * step;
                    double want = (double)heights[i];
                    double got = TerrainMath.Height(x, z);
                    Assert.AreEqual(want, got, Tol, string.Format("height at ({0},{1})", x, z));
                    if (TerrainMath.ZoneAt(x, z, want) != (string)zones[i]) zoneMismatch++;
                    if (TerrainMath.SurfaceAt(x, z, want) != (string)surfaces[i]) surfMismatch++;
                }
            Assert.AreEqual(0, zoneMismatch, "zone mismatches");
            Assert.AreEqual(0, surfMismatch, "surface mismatches");
        }

        [Test]
        public void NamedPointsMatch()
        {
            foreach (var p in (JArray)Fx.LoadObj("terrain")["points"])
            {
                double x = (double)p["x"], z = (double)p["z"], h = (double)p["height"];
                string name = (string)p["name"];
                Assert.AreEqual(h, TerrainMath.Height(x, z), Tol, name);
                Assert.AreEqual((string)p["zone"], TerrainMath.ZoneAt(x, z, h), name + " zone");
                Assert.AreEqual((string)p["surface"], TerrainMath.SurfaceAt(x, z, h), name + " surface");
            }
        }

        [Test]
        public void CausewayLaneProfileMatchesAndIsExactlyTwoMetres()
        {
            var fx = Fx.LoadObj("terrain");
            var mid = (JArray)fx["lane_mid"];
            double mx = (double)mid[0], mz = (double)mid[1];
            var a = TerrainMath.SouthA; var b = TerrainMath.SouthB;
            double dx = b.X - a.X, dz = b.Y - a.Y, len = System.Math.Sqrt(dx * dx + dz * dz);
            double nx = dz / len, nz = -dx / len;
            foreach (var l in (JArray)fx["lane"])
            {
                double off = (double)l[0];
                double got = TerrainMath.Height(mx + nx * off, mz + nz * off);
                Assert.AreEqual((double)l[1], got, 1e-4, "lane offset " + off);
                if (off <= 2.0) Assert.AreEqual(-1.0, got, 1e-4, "lane is level to 2 m (offset " + off + ")");
            }
            // At the spring low (-0.4 m) the lane is wadeable at 2 m and Arthur is swept past ~2.4 m.
            Assert.Less(-0.4 - TerrainMath.Height(mx + nx * 2.0, mz + nz * 2.0), TideModel.SweptDepth);
            Assert.Greater(-0.4 - TerrainMath.Height(mx + nx * 2.45, mz + nz * 2.45), TideModel.SweptDepth);
        }

        [Test]
        public void PierBounds()
        {
            var want = (JArray)Fx.LoadObj("terrain")["pier"]["on_pier"];
            Assert.AreEqual((bool)want[0], TerrainMath.OnPier(0, 20));
            Assert.AreEqual((bool)want[1], TerrainMath.OnPier(5, 20));
            Assert.AreEqual((bool)want[2], TerrainMath.OnPier(0, 5));
            Assert.AreEqual((bool)want[3], TerrainMath.OnPier(1.85, 12.5));
            Assert.AreEqual((bool)want[4], TerrainMath.OnPier(1.86, 12.5));
            Assert.AreEqual((double)Fx.LoadObj("terrain")["pier"]["top"], TerrainMath.PierTop);
        }
    }
}
