namespace LowTide.Core
{
    /// <summary>
    /// Clara reacts to where Arthur is, the tide, and what he carries (port of autoload/reactive_director.gd).
    /// The host calls Tick() about once a second.
    /// </summary>
    public sealed class ReactiveDirector
    {
        readonly GameSession s;
        public bool Enabled = true;
        public ReactiveDirector(GameSession session) { s = session; }

        /// <summary>Returns the id of the reaction played, or "".</summary>
        public string Tick()
        {
            if (!Enabled || s.Radio.Active) return "";
            foreach (var r in s.Convs.Reactions)
            {
                if (s.State.Location != "outdoors" && !r.Anywhere) continue;
                if (r.Once && s.State.HasFlag("seen_" + r.Id)) continue;
                double last = s.State.ReactionLast.TryGetValue(r.Id, out var l) ? l : -1e9;
                if (s.Clock.AbsMinute - last < r.Cooldown) continue;
                if (!Conditions.Check(s, r.When)) continue;
                var conv = s.Convs.GetConv(s, r.Conv);
                if (conv.IsEmpty) continue;
                s.State.ReactionLast[r.Id] = s.Clock.AbsMinute;
                if (r.Once) s.State.SetFlag("seen_" + r.Id);
                s.Radio.Play(conv);
                return r.Id;
            }
            return "";
        }
    }
}
