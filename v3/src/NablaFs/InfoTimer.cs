using System;


namespace NablaFs
{
    internal delegate void InfoTimerEventHandler(TimeSpan dt);

    internal class InfoTimer : System.Timers.Timer
    {
        #region Fields
        private DateTime               _StartTime;
        private object                 _Locker;
        private InfoTimerEventHandler? _Handler;
        #endregion

        #region Ctors
        public InfoTimer()
        {
            _Handler = null;
            _Locker  = new object();
            Enabled  = false;
            Elapsed += (sender, e) => _Handler?.Invoke(DateTime.Now - _StartTime);
        }
        #endregion

        #region Properties
        public object Locker => _Locker;
        #endregion

        #region Methods
        public void Start(int interval, InfoTimerEventHandler handler)
        {
            Interval   = interval;
            _Handler   = handler;
            _Locker    = new object();
            _StartTime = DateTime.Now;
            Enabled    = true;
            Start();
        }

        public new void Stop()
        {
            base.Stop();
            Enabled = false;

            _Handler?.Invoke(DateTime.Now - _StartTime);
        }
        #endregion
    }
}