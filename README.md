## Description

This library provides a simple runloop API that allows the execution of asynchronous methods. It also provides a pool of runloops which can be used to execute tasks on a different thread (cpp targets only). It also supports delaying execution.

## Usage:

In order to use the runloop you must call RunLoop.getMainLoop().loopMainLoop() once per frame. Usually this is simply attached to a graphical library's onRender method.
If you want to execute something in a different thread, simply use the runloop returned by RunLoop.getPooledLoop().
Not that the threaded runloop is a bit tricky to use due to the nature of the hxcpp GC method. You should avoid creating objects (new) on the code that is ran in the thread. Please not that there are many things which create objects, even if the "new" method is not called directly.
