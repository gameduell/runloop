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

import cpp.vm.Thread;

class PooledRunLoop extends RunLoop
{
    private var wantsToTerminate = false;

    #if ios
    static private var maxPoolCount = 4;
    #else
    static private var maxPoolCount = 0;
    #end

    private var runLoopList : Array<ThreadRunLoop>;
    public function new()
    {
        runLoopList = new Array<ThreadRunLoop>();
        for(i in 0...maxPoolCount)
        {
            Thread.create(runALoop);
        }

        super();
    }

    public function runALoop()
    {
        var runLoop = new ThreadRunLoop();

        runLoopList.push(runLoop);

        var thread : Thread = Thread.current();

        runLoop.boundThread = thread;

        while(!wantsToTerminate)
        {
            runLoop.loopAll();

            runLoop.isSleeping = true;
            Thread.readMessage(true);
            runLoop.isSleeping = false;
        }
    }

    private function getPooledRunLoop() : RunLoop
    {
        if(runLoopList.length == 0)
            return RunLoop.getMainLoop();

        var lowestLoad = runLoopList[0].getCurrentLoad();
        var freerRunLoop = runLoopList[0];

        if(freerRunLoop.isSleeping)
            return freerRunLoop;

        if(runLoopList.length == 1)
            return freerRunLoop;

        for(i in 1...maxPoolCount)
        {
            var currentRunLoop = runLoopList[i];

            if(currentRunLoop.isSleeping)
                return currentRunLoop;

            var currentLoad = currentRunLoop.getCurrentLoad();
            if(lowestLoad > currentLoad)
            {
                lowestLoad = currentLoad;
                freerRunLoop = currentRunLoop;
            }
        }

        return freerRunLoop;
    }

    override function terminate()
    {
        wantsToTerminate = true;

        runLoopList = null;

        super.terminate();
    }

    override function queue(func : Dynamic, priority : Priority) : Void
    {
        var runLoop = getPooledRunLoop();

        runLoop.queue(func, priority);
    }

    override function queue1(func : Dynamic, param : Dynamic, priority : Priority) : Void
    {
        var runLoop = getPooledRunLoop();

        runLoop.queue1(func, param, priority);
    }

    override function queue2(func : Dynamic, param1 : Dynamic, param2 : Dynamic, priority : Priority) : Void
    {
        var runLoop = getPooledRunLoop();

        runLoop.queue2(func, param1, param2, priority);
    }

    override function queue3(func : Dynamic, param1 : Dynamic, param2 : Dynamic, param3 : Dynamic, priority : Priority) : Void
    {
        var runLoop = getPooledRunLoop();

        runLoop.queue3(func, param1, param2, param3, priority);
    }


    override function queue4(func : Dynamic, param1 : Dynamic, param2 : Dynamic, param3 : Dynamic, param4 : Dynamic, priority : Priority) : Void
    {
        var runLoop = getPooledRunLoop();

        runLoop.queue4(func, param1, param2, param3, param4, priority);
    }

}
