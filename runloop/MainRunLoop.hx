/*
 * Created by IntelliJ IDEA.
 * User: rcam
 * Date: 04/07/14
 * Time: 12:04
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
    private var timeInTheBeginningOfTheFrame : Float;
    private var timeOnTheNextFrame : Float;
    private var firstLoopHappened : Bool;

    private var taskPool : Array<DelayPriorityQueueElement>;
    static inline var TASK_POOL_INITIAL_SIZE = 40;
    private var priorityQueue : PriorityQueue<DelayPriorityQueueElement>;

    /// use RunLoop.getMainLoop()
    private function new() : Void
    {
        super();

        firstLoopHappened = false;

        taskPool = [];

        for(i in 0...TASK_POOL_INITIAL_SIZE)
        {
            taskPool.push(new DelayPriorityQueueElement());
        }

        priorityQueue = new PriorityQueue(true, TASK_POOL_INITIAL_SIZE);
    }

    public function loopMainLoop() : Void
    {
        timeOnTheNextFrame = Timer.stamp();
        if(!firstLoopHappened)
        {
            firstLoopHappened = true;
        }
        else
        {
            var timeUsed = timeOnTheNextFrame - timeInTheBeginningOfTheFrame;
            var timeLeft = (1.0 / 60.0) - timeUsed; /// 60 fps, should be a settable variable later

            handleDelays();

            loopOnce(timeLeft);
        }

        timeInTheBeginningOfTheFrame = timeOnTheNextFrame;
    }

    private function handleDelays()
    {
        if (priorityQueue.size() == 0)
            return;

        #if cpp
        queueMutex.acquire();
        #end

        while(priorityQueue.size() != 0 && priorityQueue.peek().priority < timeOnTheNextFrame)
        {
            var prioElem = priorityQueue.dequeue();

            prioElem.func();

            recyclePriorityElement(prioElem);
        }

        #if cpp
        queueMutex.release();
        #end
    }

    public function delay(func : Void->Void, delay : Float)
    {
        #if cpp
        queueMutex.acquire();
        #end

        var prioElem = getPriorityElementFromPool();

        prioElem.priority = timeOnTheNextFrame + delay;
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
    }
}