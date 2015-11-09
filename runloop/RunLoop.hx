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

import de.polygonal.ds.LinkedQueue;
import de.polygonal.ds.DLL;
import haxe.Timer;

#if cpp
import cpp.vm.Mutex;
#end

class RunLoop
{
    static private var mainLoop : MainRunLoop;
    static private var pooledRunLoop : RunLoop;

    #if cpp
    private var queueMutex : Mutex;
    #end

    private var queuedFunctions : LinkedQueue<Dynamic>;
    private var queuedParams : LinkedQueue< Dynamic >;
    private var queuedParamCount : LinkedQueue<Int>;

    private var queuedASAPFunctions : LinkedQueue<Dynamic>;
    private var queuedASAPParams : LinkedQueue< Dynamic >;
    private var queuedASAPParamCount : LinkedQueue<Int>;

    private var loopObservers : DLL<RunLoop->Void>;

    public var timeOfLoopStart(default, null): Float = 0;
    public var deltaOfLoop(default, null): Float = 0;

    static public function getMainLoop() : MainRunLoop
    {
        if(mainLoop == null)
            initializeBaseRunLoops();
        return mainLoop;
    }

    static public function getPooledLoop() : RunLoop
    {
        if(pooledRunLoop == null)
            initializeBaseRunLoops();
        return pooledRunLoop;
    }

    public function new()
    {
        #if cpp
        queueMutex = new Mutex();
        #end

        clear();
    }

    static private function initializeBaseRunLoops()
    {
        if(mainLoop != null)
        {
            throw "Only one main RunLoop is allowed. Use RunLoop.getMainLoop() to get the main one.";
        }

        mainLoop = new MainRunLoop();

        pooledRunLoop = new PooledRunLoop();

    }

    /// like loopOnce, but will loop until the loopOnceQueues returns false (it didnt do anything)
    public function loopAll()
    {
        loopOnceDetermineTime();

        loopOnceObservers();

        while(loopOnceQueues()) continue;
    }

    /// runs loopOnceDetermineTime, loopOnceObservers and loopOnceQueues
    public function loopOnce(?timeLimit: Float)
    {
        loopOnceDetermineTime();

        loopOnceObservers();

        loopOnceQueues(timeLimit);
    }

    public function loopOnceDetermineTime()
    {
        if (timeOfLoopStart == 0)
        {
            timeOfLoopStart = Timer.stamp();
            deltaOfLoop = 0;
        }
        else
        {
            var newTime = Timer.stamp();
            deltaOfLoop = newTime - timeOfLoopStart;
            timeOfLoopStart = newTime;
        }
    }

    /// Run automatically on loop once, unless slave mode is set
    public function loopOnceObservers()
    {
        /// run the observers
        var node = loopObservers.head;

        while (node != null)
        {
            node.val(this);
            node = node.next;
        }
    }

    /// returns true if it did something
    public function loopOnceQueues(?timeLimit : Float): Bool
    {
        var executedCount = 0;

        var timeLeft = timeLimit;

        var asapFunctionCount = queuedASAPFunctions.size();
        var lowPrioFunctionCount = queuedFunctions.size();

        /// execute all asap functions

        while(asapFunctionCount > 0)
        {
            doOneASAPPriorityFunction();
            --asapFunctionCount;
            executedCount++;
        }

        /// execute 1 low prio function, and as much as possible for the time limit

        if(lowPrioFunctionCount == 0)
        {
            return executedCount > 0;
        }

        doOneLowPriorityFunction();
        --lowPrioFunctionCount;

        var timeAfterASAPAndOneLowPrio = Timer.stamp();

        if (timeLeft != null)
            timeLeft -= timeAfterASAPAndOneLowPrio - timeOfLoopStart;
        /// execute remaining low prios for as much as the time limit allows

        var timeBeforeOneLowPrio = Timer.stamp();
        while((timeLeft != null || timeLeft > 0) && lowPrioFunctionCount > 0)
        {
            doOneLowPriorityFunction();

            var newTime = Timer.stamp();

            if (timeLeft != null)
                timeLeft -= newTime - timeBeforeOneLowPrio;

            timeBeforeOneLowPrio = newTime;

            --lowPrioFunctionCount;
            executedCount++;
        }

        return executedCount > 0;
    }

    /// main run loop instance will be garbage collected after this, if it's not held somewhere
    public function terminate()
    {
        if(mainLoop == this)
            mainLoop = null;

        queuedFunctions = null;
        queuedParams = null;
        queuedParamCount = null;

        queuedASAPFunctions = null;
        queuedASAPParams = null;
        queuedASAPParamCount = null;
    }

    private function doOneLowPriorityFunction()
    {
        #if cpp
        queueMutex.acquire();
        #end

        var func : Dynamic = queuedFunctions.dequeue();

        var paramCount = queuedParamCount.dequeue();

        var param1 = null, param2 = null, param3 = null, param4 = null;


        switch(paramCount)
        {
            case (0):
            case (1):
                param1 = queuedParams.dequeue();
            case (2):
                param1 = queuedParams.dequeue();
                param2 = queuedParams.dequeue();
            case (3):
                param1 = queuedParams.dequeue();
                param2 = queuedParams.dequeue();
                param3 = queuedParams.dequeue();
            case (4):
                param1 = queuedParams.dequeue();
                param2 = queuedParams.dequeue();
                param3 = queuedParams.dequeue();
                param4 = queuedParams.dequeue();
        }

        #if cpp
        queueMutex.release();
        #end

        switch(paramCount)
        {
            case (0):
                func();
            case (1):
                func(param1);
            case (2):
                func(param1, param2);
            case (3):
                func(param1, param2, param3);
            case (4):
                func(param1, param2, param3, param4);

        }
    }

    private function doOneASAPPriorityFunction()
    {
        #if cpp
        queueMutex.acquire();
        #end

        var func : Dynamic = queuedASAPFunctions.dequeue();

        var paramCount = queuedASAPParamCount.dequeue();

        var param1 = null, param2 = null, param3 = null, param4 = null;

        switch(paramCount)
        {
            case (0):
            case (1):
                param1 = queuedASAPParams.dequeue();
            case (2):
                param1 = queuedASAPParams.dequeue();
                param2 = queuedASAPParams.dequeue();
            case (3):
                param1 = queuedASAPParams.dequeue();
                param2 = queuedASAPParams.dequeue();
                param3 = queuedASAPParams.dequeue();
            case (4):
                param1 = queuedASAPParams.dequeue();
                param2 = queuedASAPParams.dequeue();
                param3 = queuedASAPParams.dequeue();
                param4 = queuedASAPParams.dequeue();
        }

        #if cpp
        queueMutex.release();
        #end

        switch(paramCount)
        {
            case (0):
                func();
            case (1):
                func(param1);
            case (2):
                func(param1, param2);
            case (3):
                func(param1, param2, param3);
            case (4):
                func(param1, param2, param3, param4);

        }
    }

    /// run every loop
    public function addLoopObserver(func: RunLoop->Void): Void
    {
        loopObservers.append(func);
    }

    public function removeLoopObserver(func: RunLoop->Void): Void
    {
        for (element in loopObservers)
        {
            if (Reflect.compareMethods(element, func))
            {
                loopObservers.remove(element);
                break;
            }
        }
    }

    public function queue(func : Void->Void, priority : Priority) : Void
    {

        #if cpp
        queueMutex.acquire();
        #end

        switch(priority)
        {
            case(PriorityASAP):
                queuedASAPFunctions.enqueue(func);
                queuedASAPParamCount.enqueue(0);
            case(PriorityLow):
                queuedFunctions.enqueue(func);
                queuedParamCount.enqueue(0);
        }

        #if cpp
        queueMutex.release();
        #end
    }

    public function queue1(func : Dynamic->Void, param : Dynamic, priority : Priority) : Void
    {
        #if cpp
        queueMutex.acquire();
        #end

        switch(priority)
        {
            case(PriorityASAP):
                queuedASAPFunctions.enqueue(func);
                queuedASAPParamCount.enqueue(1);
                queuedASAPParams.enqueue(param);
            case(PriorityLow):
                queuedFunctions.enqueue(func);
                queuedParamCount.enqueue(1);
                queuedParams.enqueue(param);
        }

        #if cpp
        queueMutex.release();
        #end
    }

    public function queue2(func : Dynamic->Dynamic->Void, param1 : Dynamic, param2 : Dynamic, priority : Priority) : Void
    {
        #if cpp
        queueMutex.acquire();
        #end

        switch(priority)
        {
            case(PriorityASAP):
                queuedASAPFunctions.enqueue(func);
                queuedASAPParamCount.enqueue(2);
                queuedASAPParams.enqueue(param1);
                queuedASAPParams.enqueue(param2);
            case(PriorityLow):
                queuedFunctions.enqueue(func);
                queuedParamCount.enqueue(2);
                queuedParams.enqueue(param1);
                queuedParams.enqueue(param2);
        }

        #if cpp
        queueMutex.release();
        #end
    }

    public function queue3(func : Dynamic->Dynamic->Dynamic->Void, param1 : Dynamic, param2 : Dynamic, param3 : Dynamic, priority : Priority) : Void
    {
        #if cpp
        queueMutex.acquire();
        #end

        switch(priority)
        {
            case(PriorityASAP):
                queuedASAPFunctions.enqueue(func);
                queuedASAPParamCount.enqueue(3);
                queuedASAPParams.enqueue(param1);
                queuedASAPParams.enqueue(param2);
                queuedASAPParams.enqueue(param3);
            case(PriorityLow):
                queuedFunctions.enqueue(func);
                queuedParamCount.enqueue(3);
                queuedParams.enqueue(param1);
                queuedParams.enqueue(param2);
                queuedParams.enqueue(param3);
        }

        #if cpp
        queueMutex.release();
        #end
    }


    public function queue4(func : Dynamic->Dynamic->Dynamic->Dynamic->Void, param1 : Dynamic, param2 : Dynamic, param3 : Dynamic, param4 : Dynamic, priority : Priority) : Void
    {
        #if cpp
        queueMutex.acquire();
        #end

        switch(priority)
        {
            case(PriorityASAP):
                queuedASAPFunctions.enqueue(func);
                queuedASAPParamCount.enqueue(4);
                queuedASAPParams.enqueue(param1);
                queuedASAPParams.enqueue(param2);
                queuedASAPParams.enqueue(param3);
                queuedASAPParams.enqueue(param4);
            case(PriorityLow):
                queuedFunctions.enqueue(func);
                queuedParamCount.enqueue(4);
                queuedParams.enqueue(param1);
                queuedParams.enqueue(param2);
                queuedParams.enqueue(param3);
                queuedParams.enqueue(param4);
        }

        #if cpp
        queueMutex.release();
        #end
    }

    private function clear(): Void
    {
        #if cpp
        queueMutex.acquire();
        #end

        queuedFunctions = new LinkedQueue();
        queuedParams = new LinkedQueue();
        queuedParamCount = new LinkedQueue();

        queuedASAPFunctions = new LinkedQueue();
        queuedASAPParams = new LinkedQueue();
        queuedASAPParamCount = new LinkedQueue();

        loopObservers = new DLL(32);

        #if cpp
        queueMutex.release();
        #end
    }
}
