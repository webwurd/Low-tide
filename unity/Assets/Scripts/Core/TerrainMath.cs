using System;

namespace LowTide.Core
{
    /// <summary>
    /// 32-bit vector, deliberately like Godot's Vector2 (float components) so zone/surface
    /// boundaries behave identically to the reference build.
    /// </summary>
    public readonly struct Vec2
    {
        public readonly float X;
        public readonly float Y;
        public Vec2(double x, double y) { X = (float)x; Y = (float)y; }
        public float Length() => (float)Math.Sqrt(X * X + Y * Y);
        public float DistanceTo(Vec2 o) { float dx = o.X - X; float dy = o.Y - Y; return (float)Math.Sqrt(dx * dx + dy * dy); }
    }

    /// <summary>Port of world/terrain.gd: deterministic height field, zones and footstep surfaces.</summary>
    public static class TerrainMath
    {
        public const double PierX = 1.85;
        public const double PierZ0 = 12.5;
        public const double PierZ1 = 37.0;
        public const double PierTop = 4.7;
        public static readonly Vec2 CottagePos = new Vec2(-8.5, 1.5);
        public const double CottageY = 8.0;
        public const double CottageYaw = 0.45;
        public static readonly Vec2 NorthA = new Vec2(-5.0, -22.0);
        public static readonly Vec2 NorthB = new Vec2(-15.0, -46.0);
        public static readonly Vec2 CoveC = new Vec2(-17.0, -52.0);
        public static readonly Vec2 SouthA = new Vec2(12.0, 20.0);
        public static readonly Vec2 SouthB = new Vec2(18.0, 56.0);
        public static readonly Vec2 VaultC = new Vec2(18.0, 62.0);
        public const double LaneHalfWidth = 2.0;

        static double Clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
        static double Lerp(double a, double b, double t) => a + (b - a) * t;
        static double SmoothStep(double from, double to, double x) => TideModel.SmoothStep(from, to, x);

        /// <summary>Distance from point p to segment a-b, with Godot's float32 vector arithmetic.</summary>
        public static double SegDist(Vec2 p, Vec2 a, Vec2 b)
        {
            float abx = b.X - a.X, aby = b.Y - a.Y;
            float dot = (p.X - a.X) * abx + (p.Y - a.Y) * aby;
            float lenSq = abx * abx + aby * aby;
            double t = Clamp((double)dot / (double)lenSq, 0.0, 1.0);
            float tf = (float)t;
            float qx = a.X + abx * tf, qy = a.Y + aby * tf;
            return p.DistanceTo(new Vec2(qx, qy));
        }

        static double Dist(double x, double z, Vec2 c) => new Vec2(x, z).DistanceTo(c);

        public static double Height(double x, double z)
        {
            double distMain = new Vec2(x, z).Length();
            double hMain = -4.0;
            if (distMain < 42.0)
            {
                double t = Math.Max(0.0, 1.0 - distMain / 36.0);
                hMain = -3.5 + Math.Pow(t, 1.35) * 14.5;
                hMain += Math.Sin(x * 0.18) * Math.Cos(z * 0.18) * 0.55 * t;
            }

            double distSummit = new Vec2(x, z + 4.0).Length();
            if (distSummit < 11.0)
            {
                double blend = Math.Max(0.0, 1.0 - distSummit / 11.0);
                hMain = hMain * (1.0 - blend) + 10.2 * blend;
            }

            double dPad = Dist(x, z, CottagePos);
            if (dPad < 9.0)
            {
                double padBlend = SmoothStep(0.0, 1.0, Clamp((9.0 - dPad) / 4.8, 0.0, 1.0));
                hMain = Lerp(hMain, CottageY, padBlend);
            }

            double hEastBar = -4.0;
            if (x > 20.0 && x < 74.0)
            {
                double zOff = Math.Sin((x - 25.0) * 0.07) * 3.5;
                double d = Math.Abs(z - (4.0 + zOff));
                if (d < 9.5) hEastBar = -2.0 + Math.Cos((d / 9.5) * (Math.PI / 2.0)) * 3.65;
            }

            double dEast = new Vec2(x - 76.0, z - 6.0).Length();
            double hEastStack = -4.0;
            if (dEast < 19.0)
            {
                double t2 = Math.Max(0.0, 1.0 - dEast / 17.0);
                hEastStack = -2.5 + Math.Pow(t2, 1.2) * 8.2;
            }

            double hWestBar = -4.0;
            if (x < -20.0 && x > -72.0)
            {
                double zOff2 = Math.Cos((x + 25.0) * 0.08) * 3.0;
                double d2 = Math.Abs(z - (-6.0 + zOff2));
                if (d2 < 9.0) hWestBar = -2.0 + Math.Cos((d2 / 9.0) * (Math.PI / 2.0)) * 3.70;
            }

            double dWest = new Vec2(x + 74.0, z + 8.0).Length();
            double hWestStack = -4.0;
            if (dWest < 20.0)
            {
                double t3 = Math.Max(0.0, 1.0 - dWest / 18.0);
                hWestStack = -2.5 + Math.Pow(t3, 1.25) * 9.5;
            }

            var p = new Vec2(x, z);
            double hNorth = -4.0;
            double dn = SegDist(p, NorthA, NorthB);
            if (dn < 5.0) hNorth = -2.0 + Math.Cos(dn / 5.0 * (Math.PI / 2.0)) * 3.05;
            double dc = p.DistanceTo(CoveC);
            if (dc < 9.0) hNorth = Math.Max(hNorth, Lerp(1.25, -2.0, SmoothStep(5.5, 9.0, dc)));
            double dBack = p.DistanceTo(new Vec2(-20.0, -60.0));
            if (dBack < 8.0) hNorth = Math.Max(hNorth, -2.5 + Math.Pow(1.0 - dBack / 8.0, 1.2) * 8.0);

            double hSouth = -4.0;
            double dr = SegDist(p, SouthA, SouthB);
            if (dr < LaneHalfWidth + 2.0)
                hSouth = -1.0 - 2.0 * Clamp((dr - LaneHalfWidth) / 2.0, 0.0, 1.0);
            double dv = p.DistanceTo(VaultC);
            if (dv < 10.0)
                hSouth = Math.Max(hSouth, Lerp(0.5, -3.0, Clamp((dv - 4.0) / 6.0, 0.0, 1.0)));

            double best = Math.Max(Math.Max(Math.Max(hMain, hEastBar), Math.Max(hEastStack, hWestBar)), hWestStack);
            return Math.Max(best, Math.Max(hNorth, hSouth));
        }

        public static bool OnPier(double x, double z) =>
            Math.Abs(x) <= PierX && z >= PierZ0 && z <= PierZ1;

        /// <summary>Footstep surface: wood, concrete, gravel, sand, wet, rock.</summary>
        public static string SurfaceAt(double x, double z, double y)
        {
            if (OnPier(x, z) && y >= PierTop - 0.3) return "wood";
            var p = new Vec2(x, z);
            if (p.DistanceTo(VaultC) < 7.0) return "concrete";
            if (p.DistanceTo(CoveC) < 9.5 || (SegDist(p, NorthA, NorthB) < 5.0 && z < -26.0)) return "gravel";
            if (SegDist(p, SouthA, SouthB) < 5.0 && z > 24.0) return "sand";
            if (Math.Abs(x) > 20.0 && y < 2.2) return "sand";
            if (y > 0.4 && y < 2.8 && p.Length() < 32.0) return "wet";
            return "rock";
        }

        /// <summary>Coarse named zone for location-aware radio reactions.</summary>
        public static string ZoneAt(double x, double z, double y)
        {
            if (OnPier(x, z) && y >= PierTop - 0.3) return "pier";
            if (new Vec2(x - 76.0, z - 6.0).Length() < 17.0 && y > 3.0) return "east_stack";
            if (new Vec2(x + 74.0, z + 8.0).Length() < 18.0 && y > 3.0) return "west_stack";
            var p = new Vec2(x, z);
            if (p.DistanceTo(VaultC) < 8.5 && y > -0.5) return "south_reef";
            if (SegDist(p, SouthA, SouthB) < 5.0 && z > 24.0) return "south_bar";
            if (p.DistanceTo(CoveC) < 9.0 && y > 0.0) return "north_cove";
            if (SegDist(p, NorthA, NorthB) < 5.5 && z < -26.0) return "north_bar";
            if (new Vec2(x, z + 4.0).Length() < 12.0 || y > 7.0) return "summit";
            if (x > 20.0 && y < 3.0) return "east_bar";
            if (x < -20.0 && y < 3.0) return "west_bar";
            return "shore";
        }
    }
}
