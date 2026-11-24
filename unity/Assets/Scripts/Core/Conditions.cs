using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;

namespace LowTide.Core
{
    /// <summary>
    /// Tiny condition language used by dialogue and reactive lines (port of story/conditions.gd).
    /// Every entry in a `when` list must hold (AND). Prefix "!" negates.
    ///   flag:name  has:item  found:landmark  zone:a,b  loc:cottage  phase:morning|expedition|evening
    ///   tide:rising|falling   trust>=2  day==3  time>=900  tide>=1.5   (ops: >= &lt;= == &gt; &lt;)
    /// </summary>
    public static class Conditions
    {
        static readonly string[] Ops = { ">=", "<=", "==", ">", "<" };
        static readonly string[] PhaseNames = { "morning", "expedition", "evening" };
        static readonly Regex LeadingNumber = new Regex(@"^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?", RegexOptions.Compiled);

        public static bool Check(GameSession s, IEnumerable<string> conds)
        {
            if (conds == null) return true;
            foreach (var c in conds)
                if (!One(s, c)) return false;
            return true;
        }

        static bool One(GameSession s, string c)
        {
            c = c.Trim();
            if (c.StartsWith("!", StringComparison.Ordinal)) return !One(s, c.Substring(1));
            foreach (var op in Ops)
            {
                int i = c.IndexOf(op, StringComparison.Ordinal);
                if (i > 0) return Cmp(Num(s, c.Substring(0, i)), op, ToFloat(c.Substring(i + op.Length)));
            }
            int colon = c.IndexOf(':');
            if (colon < 0) return false;
            string kind = c.Substring(0, colon);
            string arg = c.Substring(colon + 1);
            switch (kind)
            {
                case "flag": return s.State.HasFlag(arg);
                case "has": return s.State.HasItem(arg);
                case "found": return s.State.Discovered.ContainsKey(arg);
                case "zone": return Array.IndexOf(arg.Split(','), s.State.Zone) >= 0;
                case "loc": return Array.IndexOf(arg.Split(','), s.State.Location) >= 0;
                case "phase": return PhaseNames[(int)s.Director.Phase] == arg;
                case "tide":
                    double now = s.TideHeight;
                    double later = TideModel.WaterHeightAbs(s.Clock.AbsMinute + 5.0);
                    return (later > now) == (arg == "rising");
            }
            return false;
        }

        static double Num(GameSession s, string key)
        {
            switch (key.Trim())
            {
                case "trust": return s.State.Trust;
                case "day": return s.Clock.Day;
                case "time": return s.Clock.MinuteOfDay;
                case "tide": return s.TideHeight;
            }
            return 0.0;
        }

        // Godot's float(): parse the leading number, 0 if none.
        static double ToFloat(string text)
        {
            var m = LeadingNumber.Match(text);
            return m.Success && double.TryParse(m.Value, NumberStyles.Float, CultureInfo.InvariantCulture, out var v) ? v : 0.0;
        }

        // Godot's is_equal_approx
        static bool ApproxEqual(double a, double b)
        {
            if (a == b) return true;
            double tol = 0.00001 * Math.Abs(a);
            if (tol < 0.00001) tol = 0.00001;
            return Math.Abs(a - b) < tol;
        }

        static bool Cmp(double a, string op, double b)
        {
            switch (op)
            {
                case ">=": return a >= b;
                case "<=": return a <= b;
                case "==": return ApproxEqual(a, b);
                case ">": return a > b;
                default: return a < b;
            }
        }
    }
}
