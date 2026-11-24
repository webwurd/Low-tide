using System;
using System.Collections.Generic;

namespace LowTide.Core
{
    /// <summary>
    /// Tide model (port of autoload/tide_system.gd). Extremes alternate low/high every HalfCycle
    /// minutes on one continuous absolute timeline (minutes since 00:00 of day 1), cosine
    /// interpolated; lows drift ~50 min later per day; day 5 has a spring low; day 4 is squashed
    /// upward by the storm.
    /// </summary>
    public static class TideModel
    {
        public const double HalfCycle = 372.5;
        public const double DayMinutes = 1440.0;
        public const double FirstLowMinute = 450.0;      // day 1 low water at 07:30
        public const double LowHeight = 0.2;
        public const double HighHeight = 4.2;
        public const double SandbarClosedAt = 2.1;
        public const double SweptDepth = 0.95;
        public const double StormRamp = 240.0;
        public const double StormFloor = 2.5;
        public const int StormDay = 4;
        public const int SpringLowDay = 5;
        public const double SpringLowHeight = -0.4;

        public struct Extreme
        {
            public double Minute;
            public double Height;
            public bool High;
        }

        static double Clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
        public static double Lerp(double a, double b, double t) => a + (b - a) * t;
        public static double SmoothStep(double from, double to, double x)
        {
            double t = Clamp01((x - from) / (to - from));
            return t * t * (3.0 - 2.0 * t);
        }

        static double ExtremeHeight(int k)
        {
            if (k % 2 != 0) return HighHeight;
            double t = FirstLowMinute + HalfCycle * k;
            int day = (int)Math.Floor(t / DayMinutes) + 1;
            return day == SpringLowDay ? SpringLowHeight : LowHeight;
        }

        public static double StormWeight(double absMinute)
        {
            double start = DayMinutes * (StormDay - 1);
            double up = Clamp01((absMinute - (start - StormRamp)) / StormRamp);
            double down = Clamp01(1.0 - (absMinute - (start + DayMinutes)) / StormRamp);
            double w = SmoothStep(0.0, 1.0, Math.Min(up, down)) * 1.0;
            return Math.Max(0.0, w);
        }

        public static double WaterHeightAbs(double absMinute)
        {
            int k = (int)Math.Floor((absMinute - FirstLowMinute) / HalfCycle);
            double t0 = FirstLowMinute + HalfCycle * k;
            double f = (absMinute - t0) / HalfCycle;
            double s = (1.0 - Math.Cos(f * Math.PI)) / 2.0;
            double h = Lerp(ExtremeHeight(k), ExtremeHeight(k + 1), s);
            return Lerp(h, StormFloor + 0.4 * h, StormWeight(absMinute));
        }

        public static double WaterHeight(int day, double minuteOfDay) =>
            WaterHeightAbs(DayMinutes * (day - 1) + minuteOfDay);

        public static List<Extreme> ExtremesForDay(int day)
        {
            var list = new List<Extreme>();
            double start = DayMinutes * (day - 1);
            int k = (int)Math.Ceiling((start - FirstLowMinute) / HalfCycle);
            while (true)
            {
                double t = FirstLowMinute + HalfCycle * k;
                if (t >= start + DayMinutes) break;
                list.Add(new Extreme { Minute = t - start, Height = WaterHeightAbs(t), High = k % 2 != 0 });
                k++;
            }
            return list;
        }

        /// <summary>First low-water time (minute of day) on a calendar day.</summary>
        public static double LowMinuteOfDay(int day)
        {
            double dayStart = DayMinutes * (day - 1);
            int k = (int)Math.Ceiling((dayStart - FirstLowMinute) / HalfCycle);
            if (k % 2 != 0) k += 1;
            return FirstLowMinute + HalfCycle * k - dayStart;
        }

        public static bool SandbarsOpen(double height) => height <= SandbarClosedAt;

        public static string DepthBand(double depth)
        {
            if (depth <= 0.0) return "dry";
            if (depth <= 0.3) return "splash";
            if (depth <= 0.7) return "knee";
            if (depth <= SweptDepth) return "thigh";
            return "swept";
        }

        public static double SpeedMultiplier(double depth)
        {
            switch (DepthBand(depth))
            {
                case "knee": return 0.6;
                case "thigh": return 0.35;
                case "swept": return 0.0;
                default: return 1.0;
            }
        }

        public static string TideLabel(double height, double ahead)
        {
            if (height <= 0.9) return "LOW TIDE";
            if (height >= 3.5) return "HIGH TIDE";
            return ahead > height ? "RISING" : "FALLING";
        }
    }
}
