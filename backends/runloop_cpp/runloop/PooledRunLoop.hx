/*
 * Created by IntelliJ IDEA.
 * User: rcam
 * Date: 04/07/14
 * Time: 11:47
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