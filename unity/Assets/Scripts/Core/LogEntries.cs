using System.Collections.Generic;

namespace LowTide.Core
{
    /// <summary>Auto-written logbook lines (port of story/log_entries.gd). Order matters: it is output order.</summary>
    public static class LogEntries
    {
        public static readonly KeyValuePair<string, string>[] Lines =
        {
            P("lighthouse", "Climbed the tower. Lens turns smooth on its weights."),
            P("cottage", "Stove draws well. Found 1970s oceanography logs on the shelf."),
            P("shipwreck", "East stack: old trawler wreck. Canister stamped PROJECT PELAGIC 1974 wedged in the hull."),
            P("cable", "North cove: an armored cable runs from a stone hut out under the sea. Brass tag: PELAGIC ARRAY 2."),
            P("vault", "South reef at the spring low: a flooded cable vault. A field recorder wedged behind the ladder, initials J.H."),
            P("floorboard", "Under the bed, a loose floorboard and a cassette in Walt's handwriting."),
            P("locker", "Lantern-room locker: Walt's last tape, left for whoever's next."),
            P("tin", "North cove hut: a biscuit tin with a Coast Guard boat log on cassette."),
            P("buoy_service", "West buoy: fresh service marks, a Coast Guard-issue battery, and a cassette taped under the hatch."),
            P("seacave", "West echo cave: red acoustic buoy in the arch. Battery pack still warm. Shouldn't be."),
        };

        public static readonly KeyValuePair<string, string>[] FlagLines =
        {
            P("reported_canister", "Told Clara about the canister."),
            P("withheld_canister", "Said nothing to Clara about the canister. Not sure why."),
            P("reported_buoy", "Told Clara the buoy was warm."),
            P("withheld_buoy", "Kept the buoy to myself."),
            P("heard_tape_1", "Played the cassette from the buoy: Walt, talking to his wife June, a year after she was lost."),
            P("reported_cable", "Told Clara about the cable and its tag."),
            P("withheld_cable", "Kept the cable to myself."),
            P("reported_vault", "Told Clara about the vault and the recorder."),
            P("withheld_vault", "Told Clara there was nothing in the vault."),
            P("heard_tape_2", "Played the field recorder from the vault: June, her last recording."),
            P("heard_tape_3", "Played Walt's 1977 tape: the Navy's settlement offer, and June's sister, Ruth."),
            P("heard_tape_4", "Played Walt's last tape. He wanted the tapes to reach Ruth Whitcomb in Providence."),
            P("heard_tape_5", "Played Tom Dunmore's boat log: he said one hour; they said two."),
            P("heard_tape_6", "Played Clara's own tape from the buoy."),
            P("clara_shared_father", "Clara told me her father worked the Pelagic boats."),
            P("told_clara_wife", "Told Clara about Maren."),
            P("clara_admitted", "Clara told me everything."),
            P("clara_partial", "Clara told me some of it."),
            P("clara_stonewalled", "Clara would not talk."),
            P("told_clara_june", "Told Clara what Walt said about June."),
            P("lied_about_tape", "Lied to Clara about the tape."),
        };

        static KeyValuePair<string, string> P(string k, string v) => new KeyValuePair<string, string>(k, v);

        public static string Compose(GameState state, int day)
        {
            var parts = new List<string> { Days.Get(day).Barometer.Replace("Barometer: ", "Glass ") };
            foreach (var kv in Lines)
                if (state.DiscoveredDay.TryGetValue(kv.Key, out int d) && d == day) parts.Add(kv.Value);
            foreach (var kv in FlagLines)
                if (state.FlagDay.TryGetValue(kv.Key, out int d) && d == day && state.HasFlag(kv.Key)) parts.Add(kv.Value);
            if (parts.Count == 1) parts.Add("Quiet day. Nothing new to record.");
            return string.Join(" ", parts);
        }
    }
}
