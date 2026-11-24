using System;
using System.Collections.Generic;

namespace LowTide.Core
{
    /// <summary>Static description of one day on Gannet Rock (port of story/day_data.gd + days.gd).</summary>
    public sealed class DayData
    {
        public int Day;
        public string Title = "";
        public string Weather = "";
        public string Barometer = "";
        public double FogDensity = 0.011;
        public string FogTintHex = "526373";
        public double LightScale = 1.0;
        public bool Rain;
        public double WaveHeight = 0.14;
        public double WindDb;
        public double LampAfter = 900.0;
        public string MorningConv = "";
        public string EveningConv = "";
    }

    public static class Days
    {
        public const double WakeMinute = 390.0;   // 06:30
        public const int LastDay = 7;
        static readonly Dictionary<int, DayData> Cache = new Dictionary<int, DayData>();

        public static DayData Get(int n)
        {
            n = Math.Max(1, Math.Min(LastDay, n));
            if (!Cache.TryGetValue(n, out var d))
            {
                d = Build(n);
                Cache[n] = d;
            }
            return d;
        }

        static DayData Mk(int n, string title, string weather, string baro, double fog, string tint,
            double light = 1.0, bool rain = false, double wave = 0.14, double wind = 0.0, double lampAfter = 900.0)
        {
            return new DayData
            {
                Day = n, Title = title, Weather = weather, Barometer = baro, FogDensity = fog, FogTintHex = tint,
                LightScale = light, Rain = rain, WaveHeight = wave, WindDb = wind, LampAfter = lampAfter,
                MorningConv = "morning_d" + n, EveningConv = "evening_d" + n,
            };
        }

        static DayData Build(int n)
        {
            switch (n)
            {
                case 1: return Mk(1, "First Watch", "Fog", "Barometer: 30.1 and steady. Fog, then.", 0.011, "526373");
                case 2: return Mk(2, "Grey Water", "Overcast", "Barometer: 29.9, easing down. Grey all day.", 0.008, "5a6670", 0.9);
                case 3: return Mk(3, "Wool", "Dense fog", "Barometer: 30.0. The glass is calm; the fog is thick as wool.", 0.040, "6a7882", 0.75);
                case 4: return Mk(4, "The Blow", "Storm", "Barometer: 28.7 and falling. The needle's nearly off the dial.", 0.017, "3d4852", 0.5, true, 0.45, 8.0, 600.0);
                case 5: return Mk(5, "Spring Low", "Clear", "Barometer: 30.5, high and clean. A cold, clear one.", 0.003, "6f8ba3", 1.0, false, 0.1);
                case 6: return Mk(6, "Frost", "Cold, clear", "Barometer: 30.4. Frost on the inside of the window.", 0.004, "7894a8", 1.0, false, 0.1);
                default: return Mk(7, "Last Light", "Still, dawn haze", "Barometer: 30.2. Not a breath of wind.", 0.006, "8a8f94", 1.0, false, 0.06);
            }
        }
    }
}
