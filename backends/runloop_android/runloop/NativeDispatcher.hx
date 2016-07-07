/*
 * Copyright (c) 2003-2016, GameDuell GmbH
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

import cpp.Lib;
import hxjni.JNI;

class NativeDispatcher
{
    static private var runloopandroid_initialize = Lib.load ("runloopandroid", "runloopandroid_initialize", 1);

    static private var java_initialize = JNI.createStaticMethod("org/haxe/duell/runloop/RunloopDispatch", "initialize", "()V");
    static private var java_invoke = JNI.createStaticMethod("org/haxe/duell/runloop/RunloopDispatch", "invoke", "(I)V");

    public function new(): Void
    {

    }

    public function initialize(): Void
    {
        var executor = function(id: Int)
        {
            var onQueue = function()
            {
                java_invoke(id);
            }

            RunLoop.getMainLoop().queue(onQueue, Priority.PriorityASAP);
        }

        java_initialize();
        runloopandroid_initialize(executor);
    }
}