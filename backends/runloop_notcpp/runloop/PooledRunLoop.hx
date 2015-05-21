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
