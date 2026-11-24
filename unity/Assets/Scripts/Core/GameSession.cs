namespace LowTide.Core
{
    /// <summary>
    /// Everything that makes up one run of the game, with no engine dependency. The Unity layer
    /// owns one of these and drives it each frame.
    /// </summary>
    public sealed class GameSession
    {
        public readonly GameClock Clock = new GameClock();
        public readonly GameState State;
        public readonly DayDirector Director;
        public readonly Conversations Convs;
        public readonly RadioLogic Radio;
        public readonly ReactiveDirector Reactions;

        public GameSession(Conversations convs)
        {
            Convs = convs;
            State = new GameState(Clock);
            Director = new DayDirector(this);
            Radio = new RadioLogic(this);
            Reactions = new ReactiveDirector(this);
        }

        /// <summary>Water height (metres) at the current game time.</summary>
        public double TideHeight => TideModel.WaterHeightAbs(Clock.AbsMinute);

        public void NewGame()
        {
            State.Reset();
            Radio.ClearQueue();
            Director.BeginDay(1);
        }
    }
}
