# asyncevents module

This module implements an asynchronous event loop which can distribute and callback **`asyncdispatch.Future`**. **`{.async.}`** is effective. 

It's expected to easy programming with **MVC**.

There has two emitter objects. **`AsyncEventEmitter[T]`** just binds a name for callback, and **`AsyncEventTypeEmitter[T]`** binds a type and a name (like namespace) for callback.

### example:

```nim
import asyncdispatch, asyncevents

type 
    Args = ref object
        id: int

    Callback = EventProc[Args]

    Ctx = ref object
        id: int

proc foo(ctx: Ctx): Callback =
    proc cb (e: Args): Future[void] =
        result = newFuture[void]()
        assert ctx.id == 1
        assert e.id == 1
        complete(result)
    result = cb

proc bar(ctx: Ctx): Callback =
    proc cb(e: Args) {.async.} =
        await sleepAsync(100)
        assert ctx.id == 1
        assert e.id == 1
    result = cb

proc test() {.async.} =
    var args = new(Args)  
    args.id = 1
    var ctx = new(Ctx)
    ctx.id = 1

    var em = initAsyncEventNameEmitter[Args, string, string]()
    var fooCb = foo(ctx)
    var barCb = bar(ctx)

    on(em, "A", "/path", fooCb, barCb)
    on(em, "B", "/path", fooCb)
    on(em, "B", "/", barCb)

    assert countNames(em) == 2
    assert countPaths(em, "A") == 1
    assert countPaths(em, "B") == 2
    assert countProcs(em, "A", "/path") == 2
    assert countProcs(em, "B", "/path") == 1
    assert countProcs(em, "B", "/") == 1

    await emit(em, "A", "/path", args)
    await emit(em, "B", "/", args)

    off(em, "A", "/path", fooCb, barCb)

    assert countNames(em) == 1
    assert countPaths(em, "A") == 0
    assert countPaths(em, "B") == 2
    assert countProcs(em, "A", "/path") == 0

    off(em, "B", "/path", fooCb)
    off(em, "B", "/", barCb)

    assert countNames(em) == 0
    assert countPaths(em, "B") == 0
    assert countProcs(em, "B", "/path") == 0

    var emm = initAsyncEventEmitter[Args, string]()

    on(emm, "A", fooCb, barCb)
    on(emm, "B", fooCb)
    on(emm, "B", fooCb, barCb)

    assert countPaths(emm) == 2
    assert countProcs(emm, "A") == 2
    assert countProcs(emm, "B") == 3

    await emit(emm, "A", args)
    await emit(emm, "B", args)

    off(emm, "A", fooCb, barCb)
    off(emm, "B", fooCb)

    assert countPaths(emm) == 1
    assert countProcs(emm, "A") == 0
    assert countProcs(emm, "B") == 2

    echo "Test complete."
    quit(QUIT_SUCCESS)

asyncCheck test()
runForever()
```

[API Documentation](https://github.com/tulayang/asyncevents/wiki/API-Documentation)
