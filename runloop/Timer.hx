package runloop;

import msignal.Signal.Signal1;

class Timer
{
    public var onFire(default, null): Signal1<Float>;
    public var paused(default, null): Bool = false;

    public var timeScale: Float = 1.0;

    /// accumulation of all frame deltas
    public var time(default, null) : Float = 0.0; 
    public var frameDelta(default, null) : Float = 0.0;
    public var frameStartTime(default, null) : Float = 0.0;

    public var ticksPerFrame(default, null): Int;

    private var tickCount: Int = 0;
    private var frameCount: Int = 0;

    public var frameDeltaMax: Float = 0;
    public var frameDeltaMin: Float = 0;

    public function new(?ticksPerFrame = 1): Void
    {
        set_ticksPerFrame(ticksPerFrame);
        onFire = new Signal1();
    }

    private function set_ticksPerFrame(value: Int): Int
    {
        if (value < 1)
        {
            value = 1;
        }

        ticksPerFrame = value;
        return value;
    }

    private function tick(runLoop: RunLoop): Void
    {
        if (paused)
        {
            return;
        }

        ++tickCount;

        if (tickCount % ticksPerFrame == 0)
        {
            tickCount = 0;
            frameCount++;

            if (ticksPerFrame == 1)
            {
                frameStartTime = runLoop.timeOfLoopStart;
                frameDelta = runLoop.deltaOfLoop * timeScale;
            }
            else
            {
                // Since we are missing frames we measure time over several frames.
                // As more frames we drop as bigger gets the frameDelta
                frameDelta = (runLoop.timeOfLoopStart - frameStartTime) * timeScale;
                frameStartTime = runLoop.timeOfLoopStart;
            }

            if (frameDeltaMax != 0)
            {
                frameDelta = Math.min(frameDelta, frameDeltaMax * timeScale);
            }

            if (frameDeltaMin != 0)
            {
                frameDelta = Math.max(frameDelta, frameDeltaMin * timeScale);
            }

            time += frameDelta;

            onFire.dispatch(frameDelta);
        }
    }

    /// If the Timer is paused you can tick the timer manually
    public function manualTick(?delta: Float = 1.0/60.0): Void
    {
        if (!paused)
        {
            return;
        }

        frameDelta = delta * timeScale;

        if (frameDeltaMax != 0)
        {
            frameDelta = Math.min(frameDelta, frameDeltaMax * timeScale);
        }

        if (frameDeltaMin != 0)
        {
            frameDelta = Math.max(frameDelta, frameDeltaMin * timeScale);
        }

        time += frameDelta;
        onFire.dispatch(frameDelta);
    }

    public function stop(): Void
    {
        paused = true;
        RunLoop.getMainLoop().removeLoopObserver(tick);
    }

    public function start(): Void
    {
        paused = false;

        tickCount = 0;
        frameCount = 0;
        frameDelta = 0.0;

        RunLoop.getMainLoop().addLoopObserver(tick);
    }

    public function reset(): Void
    {
        time = 0.0;
    }
}
