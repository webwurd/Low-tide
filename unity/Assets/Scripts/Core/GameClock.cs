using System;

namespace LowTide.Core
{
    /// <summary>Port of autoload/game_clock.gd. The day only ends when Arthur sleeps (DayLocked).</summary>
    public sealed class GameClock
    {
        public const double LastMinute = 1439.0;
        public double TimeScale = 1.0;
        public int Day = 1;
        public double MinuteOfDay = 375.0;
        public bool Paused = true;
        public bool DayLocked = true;
        public event Action<int> DayChanged;

        public double AbsMinute => (Day - 1) * 1440.0 + MinuteOfDay;

        /// <summary>Call every frame with real seconds; advances game minutes unless paused.</summary>
        public void Tick(double deltaSeconds)
        {
            if (!Paused) Advance(deltaSeconds * TimeScale);
        }

        public void Advance(double minutes)
        {
            MinuteOfDay += minutes;
            if (DayLocked)
            {
                MinuteOfDay = Math.Min(MinuteOfDay, LastMinute);
                return;
            }
            while (MinuteOfDay >= 1440.0)
            {
                MinuteOfDay -= 1440.0;
                Day++;
                DayChanged?.Invoke(Day);
            }
        }

        public void SetTime(int day, double minute)
        {
            Day = day;
            MinuteOfDay = minute;
        }

        public string Hhmm()
        {
            int m = (int)MinuteOfDay;
            int h24 = m / 60;
            int h12 = h24 % 12;
            if (h12 == 0) h12 = 12;
            return string.Format("{0:00}:{1:00} {2}", h12, m % 60, h24 >= 12 ? "PM" : "AM");
        }
    }
}
