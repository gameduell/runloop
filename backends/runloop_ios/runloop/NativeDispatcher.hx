package runloop;

import cpp.Lib;

class NativeDispatcher
{
    static private var runloopios_initialize = Lib.load ("runloopios", "runloopios_initialize", 1);
    static private var runloopios_invoke = Lib.load ("runloopios", "runloopios_invoke", 1);

    public function new(): Void
    {

    }

    public function initialize(): Void
    {
        var executor = function(id: Int)
        {
            var onQueue = function()
            {
                runloopios_invoke(id);
            }

            RunLoop.getMainLoop().queue(onQueue, Priority.PriorityASAP);
        }

        runloopios_initialize(executor);
    }
}