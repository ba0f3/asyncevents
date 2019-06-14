import asyncdispatch

type
    EventKey* = int | string
    EventProc*[T] = proc(e: T): Future[void] {.closure, gcsafe.}

    EventProcNode*[T] = ref object
        next: EventProcNode[T]
        value*: proc(e: T): Future[void] {.closure, gcsafe.}

    EventProcList*[T] = object
        head: EventProcNode[T]
        tail: EventProcNode[T]
        length: int

    EventPathNode*[T, Path] = ref object
        next: EventPathNode[T, Path]
        value*: Path
        list: EventProcList[T]

    EventPathList*[T, Path] = object
        head: EventPathNode[T, Path]
        tail: EventPathNode[T, Path]
        length: int

    EventNameNode*[T, Name, Path] = ref object
        next: EventNameNode[T, Name, Path]
        value*: Name
        list: EventPathList[T, Path]

    EventNameList*[T, Name, Path] = object
        head: EventNameNode[T, Name, Path]
        tail: EventNameNode[T, Name, Path]
        length: int

    AsyncEventEmitter*[T, Path] = EventPathList[T, Path]
    AsyncEventNameEmitter*[T, Name, Path] = EventNameList[T, Name, Path]

proc initAsyncEventEmitter*[T; Path: EventKey](): AsyncEventEmitter[T, Path] =
    ## Creates and returns a new AsyncEventEmitter[T, Path].
    discard

proc initAsyncEventNameEmitter*[T; Name,Path: EventKey](): AsyncEventNameEmitter[T, Name, Path] =
    ## Creates and returns a new AsyncEventNameEmitter[T].
    discard

template newImpl() {.dirty.} = 
    new(result)
    result.value = value

proc newEventProcNode*[T](value: EventProc[T]): EventProcNode[T] = 
    newImpl()

proc newEventPathNode*[T; Path: EventKey](value: Path): EventPathNode[T, Path] = 
    newImpl()

proc newEventNameNode*[T; Name,Path: EventKey](value: Name): EventNameNode[T, Name, Path] = 
    newImpl()

template nodesImpl() {.dirty.} =
    var it = L.head
    while it != nil:
        var next = it.next
        yield it
        it = next

iterator nodes*[T](L: EventProcList[T]): EventProcNode[T]  {.inline.} = 
    nodesImpl()

iterator nodes*[T; Path: EventKey](L: EventPathList[T, Path]): EventPathNode[T, Path] {.inline.} = 
    nodesImpl()

iterator nodes*[T; Name,Path: EventKey](L: EventNameList[T, Name, Path]): EventNameNode[T, Name, Path] {.inline.} = 
    nodesImpl()

iterator nodes*[T; Path: EventKey](L: AsyncEventEmitter[T, Path]): EventPathNode[T, Path] {.inline.} = 
    nodesImpl()

iterator nodes*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path]): EventNameNode[T, Name, Path] {.inline.} = 
    nodesImpl()

template findImpl() {.dirty.} =
    for n in nodes(L):
        if n.value == value: return n

proc find*[T](L: EventProcList[T], value: EventProc[T]): EventProcNode[T] =
    findImpl()

proc find*[T; Path: EventKey](L: EventPathList[T, Path], value: Path): EventPathNode[T, Path] =
    findImpl()

proc find*[T; Name,Path: EventKey](L: EventNameList[T, Name, Path], value: Name): EventNameNode[T, Name, Path] =
    findImpl()

proc find*[T; Path: EventKey](L: AsyncEventEmitter[T, Path], value: Path): EventPathNode[T, Path] =
    findImpl()

proc find*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path], value: Name): EventNameNode[T, Name, Path] =
    findImpl()

template findsImpl() {.dirty.} =
    for n in L.nodes():
        if n.value == value:
            return (prev: prev, curr: n)
        prev = n

proc finds*[T](L: EventProcList[T], value: EventProc[T]): 
             tuple[prev: EventProcNode[T], curr: EventProcNode[T]] =
    var prev: EventProcNode[T]
    findsImpl()

proc finds*[T; Path: EventKey](L: EventPathList[T, Path], value: Path):
             tuple[prev: EventPathNode[T, Path], curr: EventPathNode[T, Path]] =
    var prev: EventPathNode[T, Path]
    findsImpl()

proc finds*[T; Name,Path: EventKey](L: EventNameList[T, Name, Path], value: Name):
             tuple[prev: EventNameNode[T, Name, Path], curr: EventNameNode[T, Name, Path]] =
    var prev: EventNameNode[T, Name, Path]
    findsImpl()

proc finds*[T; Path: EventKey](L: AsyncEventEmitter[T, Path], value: Path):
             tuple[prev: EventPathNode[T, Path], curr: EventPathNode[T, Path]] =
    var prev: EventPathNode[T, Path]
    findsImpl()

proc finds*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path], value: Name):
             tuple[prev: EventNameNode[T, Name, Path], curr: EventNameNode[T, Name, Path]] =
    var prev: EventNameNode[T, Name, Path]
    findsImpl()

template appendImpl() =
    n.next = nil
    if L.tail != nil:
        assert L.tail.next == nil
        L.tail.next = n
    L.tail = n
    if L.head == nil: L.head = n
    inc(L.length)

proc append*[T](L: var EventProcList[T], n: EventProcNode[T]) = 
    appendImpl()

proc append*[T; Path: EventKey](L: var EventPathList[T, Path], n: EventPathNode[T, Path]) = 
    appendImpl()

proc append*[T; Name,Path: EventKey](L: var EventNameList[T, Name, Path], n: EventNameNode[T, Name, Path]) = 
    appendImpl()

proc append*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], n: EventPathNode[T, Path]) = 
    appendImpl()

proc append*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], n: EventNameNode[T, Name, Path]) = 
    appendImpl()

proc append*[T](L: var EventProcList[T], p: EventProc[T]) = 
    append(L, newEventProcNode[T](p))

proc append*[T; Path: EventKey](L: var EventPathList[T, Path], path: Path, p: EventProc[T]) = 
    var procNode = newEventProcNode[T](p)
    var pathNode = newEventPathNode[T, Path](path)
    append(pathNode.list, procNode)
    append(L, pathNode)

proc append*[T; Name,Path: EventKey](L: var EventNameList[T, Name, Path], name: Name, path: Path, p: EventProc[T]) = 
    var procNode = newEventProcNode[T](p)
    var pathNode = newEventPathNode[T, Path](path)
    var nameNode = newEventNameNode[T, Name, Path](name)
    append(pathNode.list, procNode)
    append(nameNode.list, pathNode)
    append(L, nameNode)

proc append*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], path: Path, p: EventProc[T]) = 
    var procNode = newEventProcNode[T](p)
    var pathNode = newEventPathNode[T, Path](path)
    append(pathNode.list, procNode)
    append(L, pathNode)

proc append*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path, p: EventProc[T]) = 
    var procNode = newEventProcNode[T](p)
    var pathNode = newEventPathNode[T, Path](path)
    var nameNode = newEventNameNode[T, Name, Path](name)
    append(pathNode.list, procNode)
    append(nameNode.list, pathNode)
    append(L, nameNode)

template removeImpl() =
    # L, prev, curr, next = curr.next
    if isNil(prev):
        L.head = curr.next
    else:
        prev.next = curr.next
    L.tail = curr.next
    curr.next = nil
    dec(L.length)

proc remove*[T](L: var EventProcList[T], prev: EventProcNode[T], curr: EventProcNode[T]) = 
    removeImpl()

proc remove*[T; Path: EventKey](L: var EventPathList[T, Path], prev: EventPathNode[T, Path], curr: EventPathNode[T, Path]) = 
    removeImpl()

proc remove*[T; Name,Path: EventKey](L: var EventNameList[T, Name, Path], prev: EventNameNode[T, Name, Path], curr: EventNameNode[T, Name, Path]) = 
    removeImpl()

proc remove*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], prev: EventPathNode[T, Path], curr: EventPathNode[T, Path]) = 
    removeImpl()

proc remove*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], prev: EventNameNode[T, Name, Path], curr: EventNameNode[T, Name, Path]) = 
    removeImpl()

proc countProcs*[T; Path: EventKey](L: AsyncEventEmitter[T, Path], path: Path): int =
    ## Counts the handlers of an AsyncEventEmitter[T]. 
    var pathNode = find(L, path)
    if not isNil(pathNode):
        return pathNode.list.length

proc countPaths*[T; Path: EventKey](L: AsyncEventEmitter[T, Path]): int =
    ## Counts the paths of an AsyncEventEmitter[T]. 
    return L.length

proc countProcs*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path): int =
    ## Counts the handlers of an AsyncEventNameEmitter[T]. 
    var nameNode = find(L, name)
    if not isNil(nameNode):
        var pathNode = find(nameNode.list, path)
        if not isNil(pathNode):
            return pathNode.list.length

proc countPaths*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path], name: Name): int =
    ## Counts the paths of an AsyncEventNameEmitter[T]. 
    var nameNode = find(L, name)
    if not isNil(nameNode): 
        return nameNode.list.length

proc countNames*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path]): int =
    ## Counts the names of an AsyncEventNameEmitter[T]. 
    return L.length

proc on*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], path: Path, p: EventProc[T]) =
    ## Assigns a event handler with the future. If the event
    ## doesn't exist, it will be created.
    var pathNode = find(L, path)
    if isNil(pathNode):
        append(L, path, p)
    else:
        append(pathNode.list, p)

proc on*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], path: Path, ps: varargs[EventProc[T]]) =
    ## Assigns a event handler with the future. If the event
    ## doesn't exist, it will be created.
    var pathNode = find(L, path)
    if isNil(pathNode):
        pathNode = newEventPathNode[T, Path](path)
        append(L, pathNode)
    for p in ps:
        append(pathNode.list, p)

proc on*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path, p: EventProc[T]) =
    ## Assigns a event handler with the callback. If the event
    ## doesn't exist, it will be created.
    var nameNode = find(L, name)
    if isNil(nameNode):
        append(L, name, path, p)
    else:
        var pathNode = find(nameNode.list, path)
        if isNil(pathNode):
            append(nameNode.list, path, p)
        else:
            append(pathNode.list, p)

proc on*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path, ps: varargs[EventProc[T]]) =
    ## Assigns a event handler with the callback. If the event
    ## doesn't exist, it will be created.
    var nameNode = find(L, name)
    var pathNode: EventPathNode[T, Path]
    if isNil(nameNode):
        nameNode = newEventNameNode[T, Name, Path](name)
        pathNode = newEventPathNode[T, Path](path)
        append(L, nameNode)
        append(nameNode.list, pathNode)
    else:
        pathNode = find(nameNode.list, path)
        if isNil(pathNode):
            pathNode = newEventPathNode[T, Path](path)
            append(nameNode.list, pathNode)
    for p in ps:
        append(pathNode.list, p)

proc off*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], path: Path, p: EventProc[T]) =
    ## Removes the callback from the specified event handler.
    var (prevPathNode, currPathNode) = finds(L, path)
    if not isNil(currPathNode):
        var (prevProcNode, currProcNode) = finds(currPathNode.list, p)
        if not isNil(currProcNode):
            remove(currPathNode.list, prevProcNode, currProcNode)
            if isNil(currPathNode.list.head):
                remove(L, prevPathNode, currPathNode)

proc off*[T; Path: EventKey](L: var AsyncEventEmitter[T, Path], path: Path, ps: varargs[EventProc[T]]) =
    var (prevPathNode, currPathNode) = finds(L, path)
    if not isNil(currPathNode):
        for p in ps:
            var (prevProcNode, currProcNode) = finds(currPathNode.list, p)
            if not isNil(currProcNode):
                remove(currPathNode.list, prevProcNode, currProcNode)
        if isNil(currPathNode.list.head):
            remove(L, prevPathNode, currPathNode)

proc off*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path, p: EventProc[T]) =
    ## Removes the callback from the specified event handler.
    var (prevNameNode, currNameNode) = finds(L, name)
    if not isNil(currNameNode):
        var (prevPathNode, currPathNode) = finds(currNameNode.list, path)
        if not isNil(currPathNode):
            var (prevProcNode, currProcNode) = finds(currPathNode.list, p)
            if not isNil(currProcNode):
                remove(currPathNode.list, prevProcNode, currProcNode)
                if isNil(currPathNode.list.head):
                    remove(currNameNode.list, prevPathNode, currPathNode)
                    if isNil(currNameNode.list.head):
                        remove(L, prevNameNode, currNameNode)

proc off*[T; Name,Path: EventKey](L: var AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path, ps: varargs[EventProc[T]]) =
    ## Removes the callback from the specified event handler.
    var (prevNameNode, currNameNode) = finds(L, name)
    if not isNil(currNameNode):
        var (prevPathNode, currPathNode) = finds(currNameNode.list, path)
        if not isNil(currPathNode):
            for p in ps:
                var (prevProcNode, currProcNode) = finds(currPathNode.list, p)
                if not isNil(currProcNode):
                    remove(currPathNode.list, prevProcNode, currProcNode)
            if isNil(currPathNode.list.head):
                remove(currNameNode.list, prevPathNode, currPathNode)
                if isNil(currNameNode.list.head):
                    remove(L, prevNameNode, currNameNode)

template createCb(retFutureSym, iteratorNameSym, name: expr): stmt =
    var nameIterVar = iteratorNameSym
    #{.push stackTrace: off.}
    proc cb() {.closure, gcsafe.} =
        try:
            if not nameIterVar.finished:
                var next = nameIterVar()
                if isNil(next):
                    assert retFutureSym.finished, "Async procedure's (" &
                             name & ") return Future was not finished."
                else:
                    next.callback = cb
        except:
            if retFutureSym.finished:
                # Take a look at tasyncexceptions for the bug which this fixes.
                # That test explains it better than I can here.
                raise
            else:
                echo(repr(retFutureSym))
                echo(repr(getCurrentException()))
                fail(retFutureSym, getCurrentException())
    cb()
    #{.pop.}

proc emit*[T; Path: EventKey](L: AsyncEventEmitter[T, Path], path: Path, e: T): Future[void] =
    ## Fires an event handler with specified event arguments.
    var retFuture = newFuture[void]("emit")
    iterator emitIter(): FutureBase {.closure, gcsafe.} = 
        var pathNode = find(L, path)
        if not isNil(pathNode):
            for procNode in nodes(pathNode.list): # proc(e: T): Future[void] 
                yield procNode.value(e)
        complete(retFuture)
    createCb(retFuture, emitIter, "emit")
    return retFuture

proc emit*[T; Name,Path: EventKey](L: AsyncEventNameEmitter[T, Name, Path], name: Name, path: Path, e: T): Future[void] =
    ## Fires an event handler with specified event arguments.
    var retFuture = newFuture[void]("emit")
    iterator emitIter(): FutureBase {.closure.} = 
        var nameNode = find(L, name)
        if not isNil(nameNode):
            var pathNode = find(nameNode.list, name)
            if not isNil(pathNode):
                for procNode in nodes(pathNode.list):
                    yield procNode.value(e)    
        complete(retFuture)
    createCb(retFuture, emitIter, "emit")
    return retFuture

when isMainModule:
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
        proc cb(e: Args): Future[void] {.async.} =
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
