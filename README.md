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
    await sleepAsync(200)
    echo e.article

var em = initAsyncEventEmitter[MyArgs]()
em.on("request", foo, bar)
em.on("request", foo)

proc test1() {.async.} =
    var args = new(MyArgs)
    args.userId = 1
    args.article = "Hello world!"

    echo "client request"
    await em.emit("request", args)

    # do something

    echo "client response"
    await em.emit("response", args)

var emm = initAsyncEventTypeEmitter[MyArgs]()

emm.on("get", "/article", foo, bar)

proc test2() {.async.} =
    var args = new(MyArgs)
    args.userId = 1
    args.article = "Hello world!"

    echo "client get article"
    await emm.emit("get", "/article", args)

    # do something

asyncCheck test1()
asyncCheck test2()
runForever()
```

[API Documentation](https://github.com/tulayang/asyncevents/wiki/API-Documentation)
