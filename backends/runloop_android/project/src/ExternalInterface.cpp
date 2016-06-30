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

#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#include <hx/CFFI.h>
#include <jni.h>

#ifdef __GNUC__
	#define JAVA_EXPORT __attribute__ ((visibility("default"))) JNIEXPORT
#else
	#define JAVA_EXPORT JNIEXPORT
#endif

static value *__onExecutorCallback = NULL;


static value runloopandroid_initialize(value callback)
{
	val_check_function(callback, 1); // Is Func ?
	if (__onExecutorCallback == NULL)
	{
		__onExecutorCallback = alloc_root();
	}

	*__onExecutorCallback = callback;

	return alloc_null();
}
DEFINE_PRIM (runloopandroid_initialize, 1);


extern "C" {
	JAVA_EXPORT void JNICALL Java_org_haxe_duell_runloop_RunloopDispatch_onCallback(JNIEnv * env, jobject obj, jint id);
};


struct AutoHaxe
{
	int base;
	const char *message;
	AutoHaxe(const char *inMessage)
	{
		base = 0;
		message = inMessage;
		gc_set_top_of_stack(&base,true);
		//__android_log_print(ANDROID_LOG_VERBOSE, "OpenGL", "Enter %s %p", message, pthread_self());
	}
	~AutoHaxe()
	{
		//__android_log_print(ANDROID_LOG_VERBOSE, "OpenGL", "Leave %s %p", message, pthread_self());
		gc_set_top_of_stack(0,true);
	}
};

JAVA_EXPORT void JNICALL Java_org_haxe_duell_runloop_RunloopDispatch_onCallback(JNIEnv * env, jobject obj, jint count)
{
	AutoHaxe haxe("RunloopDispatch_onCallback");
	val_call1(*__onExecutorCallback, alloc_int(count));
}


extern "C" int inputandroid_register_prims () { return 0; }
