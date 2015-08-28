# asyncevents module

This module implements an asynchronous event loop which can distribute and callback **`asyncdispatch.Future`**. **`{.async.}`** is effective. 

It's expected to easy programming with **MVC**.

There has two emitter objects. **`AsyncEventEmitter[T]`** just binds a name for callback, and **`AsyncEventTypeEmitter[T]`** binds a type and a name (like namespace) for callback.

### example:

```nim
import asyncdispatch, asyncevents

type MyArgs = ref object
	userId: int
	article: string

proc foo(e: MyArgs) {.async, closure.} =
    await sleepAsync(100)
    echo e.userId

proc bar(e: MyArgs) {.async, closure.} =
	await sleepAsync(100)
	echo "incoming"

proc foobar(e: MyArgs) {.async, closure.} =
    await sleepAsync(200)
    echo e.article

var args = new(MyArgs)
args.userId = 1
args.article = "Hello world!"

var em = initAsyncEventEmitter[MyArgs]()
em.on("request", foo, bar)
em.emit("request", args)

var emm = initAsyncEventTypeEmitter[MyArgs]()
emm.on("get", "/articles", foobar)
emm.emit("get", "/articles", args)

runForever()
```

[API Documentation](https://github.com/tulayang/asyncevents/wiki/API-Documentation)
