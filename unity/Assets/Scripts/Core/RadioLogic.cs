using System;
using System.Collections.Generic;

namespace LowTide.Core
{
    /// <summary>
    /// Non-blocking VHF radio logic (port of autoload/radio_system.gd). Higher-priority conversations
    /// preempt lower ones; the rest queue. Timers belong to the host: call Timeout() when the
    /// panel's reading timer expires (see NextTimerSeconds).
    /// </summary>
    public sealed class RadioLogic
    {
        readonly GameSession session;
        readonly List<Conv> queue = new List<Conv>();
        string pendingNext = "";

        public bool Active;
        public Conv Current = Conv.Empty;
        public bool AwaitingChoice;
        public double NextTimerSeconds;   // how long the host should wait before calling Timeout()

        public event Action<string, string, IList<ConvOption>> LineShown;   // speaker, text, options
        public event Action<string, string> ReplyShown;                     // speaker, text
        public event Action Hidden;
        public event Action<string> Sfx;                                    // e.g. "squelch"

        public RadioLogic(GameSession session) { this.session = session; }

        public IEnumerable<string> QueueIds { get { foreach (var c in queue) yield return c.Id; } }
        public int QueueCount => queue.Count;

        public static double ReadingTime(string text) => 2.5 + text.Length * 0.05;

        public void ClearQueue() { queue.Clear(); pendingNext = ""; }

        public void Play(Conv conv)
        {
            if (conv == null || conv.IsEmpty) return;
            int prio = conv.Priority;
            if (Active)
            {
                if (prio > Current.Priority)
                {
                    queue.Insert(0, conv);
                    Finish();
                    return;
                }
                if (prio == 0) return;     // idle chatter never queues behind a live call
                queue.Add(conv);
                return;
            }
            Show(conv);
        }

        public void Choose(int index)
        {
            if (!AwaitingChoice) return;
            var opts = Current.Options;
            if (index < 0 || index >= opts.Count) return;
            var opt = opts[index];
            AwaitingChoice = false;
            session.State.Trust += opt.Trust;
            foreach (var f in opt.Set) session.State.SetFlag(f);
            foreach (var f in opt.Clear) session.State.ClearFlag(f);
            pendingNext = opt.Next;
            Sfx?.Invoke("squelch");
            ReplyShown?.Invoke("Clara, replying", opt.Reply);
            NextTimerSeconds = ReadingTime(opt.Reply);
        }

        public void Dismiss()
        {
            if (Active) Finish();
        }

        /// <summary>The host's reading timer expired.</summary>
        public void Timeout() => Finish();

        void Show(Conv conv)
        {
            Active = true;
            Current = conv;
            AwaitingChoice = conv.Options.Count > 0;
            Sfx?.Invoke("squelch");
            LineShown?.Invoke(conv.Speaker, conv.Text, conv.Options);
            NextTimerSeconds = AwaitingChoice ? 30.0 : ReadingTime(conv.Text);
        }

        void Finish()
        {
            Active = false;
            AwaitingChoice = false;
            Current = Conv.Empty;
            string nxt = pendingNext;
            pendingNext = "";
            if (nxt != "") queue.Insert(0, session.Convs.GetConv(session, nxt));
            while (queue.Count > 0 && queue[0].IsEmpty) queue.RemoveAt(0);
            if (queue.Count > 0)
            {
                var c = queue[0];
                queue.RemoveAt(0);
                Show(c);                  // a follow-up replaces the panel; no hide in between
            }
            else
            {
                Hidden?.Invoke();
            }
        }
    }
}
