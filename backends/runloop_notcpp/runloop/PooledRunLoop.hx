/*
 * Created by IntelliJ IDEA.
 * User: rcam
 * Date: 04/07/14
 * Time: 11:47
 */
package runloop;

class PooledRunLoop extends RunLoop
{
    public function new()
    {
        super();
    }

    override function queue(func : Dynamic, priority : Priority) : Void
    {
        var runLoop = RunLoop.getMainLoop();

        runLoop.queue(func, priority);
    }

    override function queue1(func : Dynamic, param : Dynamic, priority : Priority) : Void
    {
        var runLoop = RunLoop.getMainLoop();

        runLoop.queue1(func, param, priority);
    }

    override function queue2(func : Dynamic, param1 : Dynamic, param2 : Dynamic, priority : Priority) : Void
    {
        var runLoop = RunLoop.getMainLoop();

        runLoop.queue2(func, param1, param2, priority);
    }

    override function queue3(func : Dynamic, param1 : Dynamic, param2 : Dynamic, param3 : Dynamic, priority : Priority) : Void
    {
        var runLoop = RunLoop.getMainLoop();

        runLoop.queue3(func, param1, param2, param3, priority);
    }


    override function queue4(func : Dynamic, param1 : Dynamic, param2 : Dynamic, param3 : Dynamic, param4 : Dynamic, priority : Priority) : Void
    {
        var runLoop = RunLoop.getMainLoop();

        runLoop.queue4(func, param1, param2, param3, param4, priority);
    }

}