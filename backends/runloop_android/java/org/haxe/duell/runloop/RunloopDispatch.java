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

package org.haxe.duell.runloop;

import android.content.Intent;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import org.haxe.duell.DuellActivity;
import org.haxe.duell.MainHaxeThreadHandler;
import android.view.WindowManager;

import java.lang.ref.WeakReference;

import android.util.Log;
import java.util.Hashtable;

public class RunloopDispatch
{
    private  static  Hashtable<Integer, Runnable> map = new Hashtable<Integer, Runnable>();
    private static int nextId = 0;

    public static native void onCallback(int id);

    public static void initialize()
    {
        final DuellActivity activity = DuellActivity.getInstance();
        MainHaxeThreadHandler runloopHaxeThreadHandler = new MainHaxeThreadHandler()
        {
            @Override
            public void queueRunnableOnMainHaxeThread(Runnable runObj)
            {
                int id = nextId++;
                map.put(id, runObj);
                onCallback(id);
            }
        };
        activity.setHaxeRunloopHandler(runloopHaxeThreadHandler);
    }

    public static void invoke(int id)
    {
        Runnable callback = map.get(id);
        map.remove(id);
        callback.run();
    }
}