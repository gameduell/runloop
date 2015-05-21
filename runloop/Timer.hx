/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
