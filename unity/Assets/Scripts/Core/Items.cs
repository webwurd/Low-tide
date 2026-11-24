using System.Collections.Generic;

namespace LowTide.Core
{
    /// <summary>Satchel items: story objects only. No combining, crafting or weight.</summary>
    public static class Items
    {
        public struct Item { public string Name; public string Desc; }

        public static readonly Dictionary<string, Item> Data = new Dictionary<string, Item>
        {
            { "canister", new Item { Name = "Pelagic canister", Desc = "Orange waterproof canister stamped PROJECT PELAGIC 1974. Sealed. Heavy for its size." } },
            { "tape_1", new Item { Name = "Cassette: \"Walt, Jan 1976\"", Desc = "Taped inside the buoy hatch. Pencil label. Plays in the cottage cassette player." } },
            { "cable_tag", new Item { Name = "Brass cable tag", Desc = "From the north cove cable hut. Stamped PELAGIC / ARRAY 2 / USN / DO NOT DISTURB. Salt-green." } },
            { "tape_2", new Item { Name = "Cassette: \"J.H., Nov 1974\"", Desc = "Cassette from a field recorder wedged behind the vault ladder. Plays in the cottage cassette player." } },
            { "tape_3", new Item { Name = "Cassette: \"Walt, Oct 1977\"", Desc = "Found under a loose floorboard beneath the cottage bed. Label in Walt's hand." } },
            { "tape_4", new Item { Name = "Cassette: \"Walt, last\"", Desc = "Kept in the lantern-room locker. The label just says: For whoever's next." } },
            { "tape_5", new Item { Name = "Cassette: \"T. Dunmore, boat log\"", Desc = "From a biscuit tin in the north cove hut. A Coast Guard boatswain's dictated log." } },
            { "tape_6", new Item { Name = "Cassette: \"C.D., Oct 1997\"", Desc = "Taped under the west buoy's service hatch, beside a fresh Coast Guard-issue battery." } },
            { "uni_logs", new Item { Name = "University logbooks", Desc = "1970s oceanography logs from the cottage shelf: hydrophone readings, tide corrections, and a name: J. Haskell." } },
        };

        public static string Title(string id) => Data.TryGetValue(id, out var it) ? it.Name : id;
        public static string Desc(string id) => Data.TryGetValue(id, out var it) ? it.Desc : "";
    }
}
