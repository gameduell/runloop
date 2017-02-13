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

import haxe.Timer;

import de.polygonal.ds.Prioritizable;
import de.polygonal.ds.PriorityQueue;

#if cpp
import cpp.vm.Mutex;
#end

class DelayPriorityQueueElement implements Prioritizable
{
    public var priority : Float;
    public var func : Void->Void;

    /// used internally by ds
    public var position : Int;


    public function new() {}
}

class MainRunLoop extends RunLoop
{
		// Sets the amount of time allocated per frame for running queued tasks.
		// Set this to e.g. 1.0 second while loading to spend less time rendering.
	public var loopDeltaForTasks (default, default): Float;

    private var firstLoopHappened : Bool;

    private var taskPool : Array<DelayPriorityQueueElement>;
    static inline var TASK_POOL_INITIAL_SIZE = 40;
    private var priorityQueue : PriorityQueue<DelayPriorityQueueElement>;

    /// use RunLoop.getMainLoop()
    private function new() : Void
    {
        super();

		loopDeltaForTasks = 1.0 / 60.0;	// 60 FPS by default

        firstLoopHappened = false;

        taskPool = [];

        for(i in 0...TASK_POOL_INITIAL_SIZE)
        {
            taskPool.push(new DelayPriorityQueueElement());
        }

        priorityQueue = new PriorityQueue(true, TASK_POOL_INITIAL_SIZE);
    }

    public function loopOnceDelays() : Void
    {
        if (priorityQueue.size() == 0)
            return;

        #if cpp
        queueMutex.acquire();
        #end

        while(priorityQueue.size() != 0 && priorityQueue.peek().priority < timeOfLoopStart)
        {
            var prioElem = priorityQueue.dequeue();

            prioElem.func();

            recyclePriorityElement(prioElem);
        }

        #if cpp
        queueMutex.release();
        #end
    }

    public function loopMainLoop(loopUntilEmpty: Bool = false) : Void
    {
        var timeLeft: Float = 0.0;

        if(!firstLoopHappened)
        {
            firstLoopHappened = true;
            timeLeft = loopDeltaForTasks;
        }
        else
        {
            timeLeft = Math.max(loopDeltaForTasks - deltaOfLoop, 0.0);
        }

        loopOnce(timeLeft, loopUntilEmpty);
    }

    /// adds the loopOnceDelays
    override function loopOnce(timeLimit: Float, loopUntilEmpty: Bool = false) : Void
    {
        loopOnceDelays();

        super.loopOnce(timeLimit, loopUntilEmpty);
    }

    public function delay(func : Void->Void, delay : Float)
    {
        #if cpp
        queueMutex.acquire();
        #end

        var prioElem = getPriorityElementFromPool();

        prioElem.priority = timeOfLoopStart + delay;
        prioElem.func = func;

        priorityQueue.enqueue(prioElem);

        #if cpp
        queueMutex.release();
        #end
    }

    private function getPriorityElementFromPool() : DelayPriorityQueueElement
    {
        if(taskPool.length > 0)
            return taskPool.pop();

        return new DelayPriorityQueueElement();
    }

    private function recyclePriorityElement(prioElem : DelayPriorityQueueElement)
    {
        taskPool.push(prioElem);
        prioElem.func = null;
    }

    override private function clear()
    {
        super.clear();

        priorityQueue = new PriorityQueue(true, TASK_POOL_INITIAL_SIZE);
    }
}
