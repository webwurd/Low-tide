namespace LowTide.Core
{
    /// <summary>The three endings: names, epilogue text and the flag-dependent coda (port of story/endings.gd).</summary>
    public static class Endings
    {
        public static string Name(string kind)
        {
            switch (kind)
            {
                case "a": return "The Right Address";
                case "b": return "Left Quiet";
                default: return "On the Record";
            }
        }

        static string BaseBody(string kind)
        {
            switch (kind)
            {
                case "a": return "Ruth Whitcomb answered in eleven days. She asked first for June's recorder, and then, quietly, for the tapes. They were played at her kitchen table in Providence, and later at a small hearing nobody expected anyone to attend. The Navy's schedule for the fourth of November, 1974, was never entered in any record. Now it is. So is the name of the Coast Guard boatswain who said one hour.";
                case "b": return "By dawn the buoy's battery had gone flat, and the ping on the south reef stopped for the first time in twenty-four years. The tapes went back into the lamp-room locker, where Walt had left them for whoever came next. Arthur took the relief boat home to a house he could finally walk through. On sixteen, in the mornings, Clara still says good morning to the rock.";
                default: return "The report went to the Coast Guard with Arthur's signature on it: thorough, accurate, and dated the seventh. It reopened nothing for June, and it ended Clara's career at Station Penobscot. She did not answer on sixteen again. The beam turned all that winter for no one, and the relief boat, when it came, found the radio switched off.";
            }
        }

        public static string Body(GameState state, string kind)
        {
            string text = BaseBody(kind);
            if (kind == "a")
            {
                if (state.HasFlag("clara_admitted")) text += " Clara's statement sits beside Arthur's. She signed it Dunmore.";
                else if (state.HasFlag("clara_partial")) text += " Clara never wrote back, but her father's log was in the envelope.";
                else text += " Clara's name is nowhere in the file. Neither of you mentions it.";
            }
            return text;
        }
    }
}
