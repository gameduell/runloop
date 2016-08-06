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

#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#include <hx/CFFI.h>
#include <map>
using std::map;
#import "DUELLAppDelegate.h"

value *__onExecutorCallback = NULL;
NSMutableDictionary* __callbackDict = nil;
static unsigned int __nextId = 0;

static value runloopios_initialize(value callback)
{
	__callbackDict = [NSMutableDictionary dictionaryWithDictionary:@{}];
	val_check_function(callback, 1); // Is Func ?
	if (__onExecutorCallback == NULL)
	{
		__onExecutorCallback = alloc_root();
	}

	[DUELLAppDelegate overrideExecutor: ^(DuellCallbackBlock block)
	{
		@synchronized(__callbackDict)
		{
			int id = __nextId++;
			[__callbackDict setObject: [block copy] forKey:[NSNumber numberWithInt:id]];
			value intValue = alloc_int(id);
			val_call1(*__onExecutorCallback, intValue);
		}

	}];


	*__onExecutorCallback = callback;
	return alloc_null();
}
DEFINE_PRIM (runloopios_initialize, 1);

static value runloopios_invoke(value id)
{
	@synchronized(__callbackDict)
	{
		DuellCallbackBlock block = __callbackDict[[NSNumber numberWithInt:val_int(id)]];
    	block();
    	[__callbackDict removeObjectForKey:[NSNumber numberWithInt:val_int(id)]];
	}

	return alloc_null();
}
DEFINE_PRIM (runloopios_invoke, 1);

static value dummy()
{
	return alloc_null();
}

extern "C" int runloopios_register_prims () { return 0; }