# asyncevents module

This module implements an asynchronous event loop which can distribute and callback asyncdispatch.Future. This also can use {.async.}. 

This module is expected to easy programming with MVC.

There has two emitter objects. `AsyncEventEmitter[T]` just binds a name for callback, and `AsyncEventTypeEmitter[T]` binds a type and a name (like namespace) for callback.

Example:

```
type MyArgs = object
	userId: int
	article: string

proc foo(e: MyArgs) {.async.} =
    await sleepAsync(100)
    echo e.userId

proc bar(e: MyArgs) {.async.} =
    await sleepAsync(200)
    echo e.article

var args = new(MyArgs)
args.userId = 1
args.article = "Hello world!"

var em = initAsyncEventEmitter[MyArgs]()
emm.on("request", foo)
emm.emit("request", args)

var emm = initAsyncEventTypeEmitter[MyArgs]()
emm.on("get", "/articles", bar)
emm.emit("get", "/articles", args)
```

[API Documentation]()







