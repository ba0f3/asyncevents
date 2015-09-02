import asyncdispatch

type
    AsyncEventProc*[T] = proc(e: T): Future[void] {.closure.}

    AsyncEventProcNodeObj*[T] = object  ## A handler node, a name node consists of
        next: ref AsyncEventProcNodeObj[T]
        value*: proc(e: T): Future[void] {.closure.}
    AsyncEventProcNode*[T] = ref AsyncEventProcNodeObj[T]

    AsyncEventNameNodeObj*[T] = object  ## A name node, a emitter consists of, a type node consists of
        next: ref AsyncEventNameNodeObj[T]
        value*: string
        head: AsyncEventProcNode[T]
        tail: AsyncEventProcNode[T]
        length: int
    AsyncEventNameNode*[T] = ref AsyncEventNameNodeObj[T]

    AsyncEventEmitter*[T] = object  ## An object that fires events and holds event handlers for an object.
        head: AsyncEventNameNode[T]
        tail: AsyncEventNameNode[T]
        length: int

    AsyncEventTypeNodeObj*[T] = object  ## A type node, a type emitter consists of
        next: ref AsyncEventTypeNodeObj[T]
        value*: string
        head: AsyncEventNameNode[T]
        tail: AsyncEventNameNode[T]
        length: int
    AsyncEventTypeNode*[T] = ref AsyncEventTypeNodeObj[T]

    AsyncEventTypeEmitter*[T] = object  ## An object that fires events and holds event handlers for an object.
        head: AsyncEventTypeNode[T]
        tail: AsyncEventTypeNode[T]
        length: int

proc initAsyncEventTypeEmitter*[T](): AsyncEventTypeEmitter[T] =
    ## Creates and returns a new AsyncEventTypeEmitter[T].
    discard

proc initAsyncEventEmitter*[T](): AsyncEventEmitter[T] =
    ## Creates and returns a new AsyncEventEmitter[T].
    discard

template newImpl() = 
    new(result)
    result.value = value

proc newAsyncEventProcNode*[T](value: proc(e: T): Future[void] {.closure.}): 
                              AsyncEventProcNode[T] =
    newImpl()

proc newAsyncEventNameNode*[T](value: string): AsyncEventNameNode[T] =
    newImpl()

proc newAsyncEventTypeNode*[T](value: string): AsyncEventTypeNode[T] =
    newImpl()

template nodesImpl() {.dirty.} =
    var it = L.head
    while it != nil:
        var nxt = it.next
        yield it
        it = nxt

iterator nodes*[T](L: AsyncEventNameNode[T]) {.inline.} = 
    nodesImpl()

iterator nodes*[T](L: AsyncEventTypeNode[T]) {.inline.} = 
    nodesImpl()

iterator nodes*[T](L: AsyncEventEmitter[T]) {.inline.} = 
    nodesImpl()

iterator nodes*[T](L: AsyncEventTypeEmitter[T]) {.inline.} = 
    nodesImpl()

template findImpl() {.dirty.} =
    for n in L.nodes():
        if n.value == value: return n

proc find*[T](L: AsyncEventNameNode[T], value: proc(e: T): Future[void] {.closure.}): 
             AsyncEventProcNode[T] =
    findImpl()

proc find*[T](L: AsyncEventTypeNode[T], value: string): 
             AsyncEventNameNode[T] =
    findImpl()

proc find*[T](L: AsyncEventEmitter[T], value: string): 
             AsyncEventNameNode[T] =
    findImpl()

proc find*[T](L: AsyncEventTypeEmitter[T], value: string): 
             AsyncEventTypeNode[T] =
    findImpl()

template findsImpl() {.dirty.} =
    for n in L.nodes():
        if n.value == value:
            return (prev: prev, curr: n)
        prev = n

proc finds[T](L: AsyncEventNameNode[T], value: proc(e: T): Future[void] {.closure.}): 
             tuple[prev: AsyncEventProcNode[T], curr: AsyncEventProcNode[T]] =
    var prev: AsyncEventProcNode[T]
    findsImpl()

proc finds[T](L: AsyncEventTypeNode[T], value: string): 
             tuple[prev: AsyncEventNameNode[T], curr: AsyncEventNameNode[T]] =
    var prev: AsyncEventNameNode[T]
    findsImpl()

proc finds[T](L: AsyncEventEmitter[T], value: string): 
             tuple[prev: AsyncEventNameNode[T], curr: AsyncEventNameNode[T]] =
    var prev: AsyncEventNameNode[T]
    findsImpl()

proc finds[T](L: AsyncEventTypeEmitter[T], value: string): 
             tuple[prev: AsyncEventTypeNode[T], curr: AsyncEventTypeNode[T]] =
    var prev: AsyncEventTypeNode[T]
    findsImpl()

template appendImpl() =
    n.next = nil
    if L.tail != nil:
        assert(L.tail.next == nil)
        L.tail.next = n
    L.tail = n
    if L.head == nil: L.head = n
    L.length.inc()

proc append[T](L: AsyncEventNameNode[T], n: AsyncEventProcNode[T]) = 
    appendImpl()

proc append[T](L: AsyncEventTypeNode[T], n: AsyncEventNameNode[T]) = 
    appendImpl()

proc append[T](L: var AsyncEventEmitter[T], n: AsyncEventNameNode[T]) = 
    appendImpl()

proc append[T](L: var AsyncEventTypeEmitter[T], n: AsyncEventTypeNode[T]) = 
    appendImpl()

proc append[T](nNode: AsyncEventNameNode[T], p: proc(e: T): Future[void] {.closure.}) = 
    nNode.append(newAsyncEventProcNode[T](p))

proc append[T](tNode: AsyncEventTypeNode[T], name: string, p: proc(e: T): Future[void] {.closure.}) = 
    var pNode = newAsyncEventProcNode[T](p)
    var nNode = newAsyncEventNameNode[T](name)
    nNode.append(pNode)
    tNode.append(nNode)

proc append[T](eNode: var AsyncEventEmitter[T], name: string, p: proc(e: T): Future[void] {.closure.}) = 
    var pNode = newAsyncEventProcNode[T](p)
    var nNode = newAsyncEventNameNode[T](name)
    nNode.append(pNode)
    eNode.append(nNode)

proc append[T](eNode: var AsyncEventTypeEmitter[T], 
               typ: string, name: string, p: proc(e: T): Future[void] {.closure.}) = 
    var pNode = newAsyncEventProcNode[T](p)
    var nNode = newAsyncEventNameNode[T](name)
    var tNode = newAsyncEventTypeNode[T](typ)
    nNode.append(pNode)
    tNode.append(nNode)
    eNode.append(tNode)

template removeImpl() =
    # L, prev, curr, next = curr.next
    if prev.isNil():
        L.head = curr.next
    else:
        prev.next = curr.next
    L.tail = curr.next
    curr.next = nil
    L.length.dec()

proc remove[T](L: AsyncEventNameNode[T], prev: AsyncEventProcNode[T], curr: AsyncEventProcNode[T]) = 
    removeImpl()

proc remove[T](L: AsyncEventTypeNode[T], prev: AsyncEventNameNode[T], curr: AsyncEventNameNode[T]) = 
    removeImpl()

proc remove[T](L: var AsyncEventEmitter[T], prev: AsyncEventNameNode[T], curr: AsyncEventNameNode[T]) = 
    removeImpl()

proc remove[T](L: var AsyncEventTypeEmitter[T], prev: AsyncEventTypeNode[T], curr: AsyncEventTypeNode[T]) = 
    removeImpl()

proc countProcs*[T](L: AsyncEventTypeEmitter[T], typ: string, name: string): int {.inline.} =
    ## Counts the handlers of an AsyncEventTypeEmitter[T]. 
    var tnode = L.find(typ)
    if not tnode.isNil():
        var nnode = tnode.find(name)
        if not nnode.isNil():
            return nnode.length

proc countProcs*[T](L: AsyncEventEmitter[T], name: string): int {.inline.} =
    ## Counts the handlers of an AsyncEventEmitter[T]. 
    var nnode = L.find(name)
    if not nnode.isNil():
        return nnode.length

proc countNames*[T](L: AsyncEventTypeEmitter[T], typ: string): int {.inline.} =
    ## Counts the names of an AsyncEventTypeEmitter[T]. 
    var node = L.find(typ)
    if not node.isNil(): 
        return node.length

proc countNames*[T](L: AsyncEventEmitter[T]): int {.inline.} =
    ## Counts the names of an AsyncEventEmitter[T]. 
    return L.length

proc countTypes*[T](L: AsyncEventTypeEmitter[T]): int {.inline.} =
    ## Counts the types of an AsyncEventTypeEmitter[T]. 
    return L.length

proc on*[T](x: var AsyncEventEmitter[T], 
            name: string, p: proc(e: T): Future[void] {.closure.}) =
    ## Assigns a event handler with the future. If the event
    ## doesn't exist, it will be created.
    var nNode = x.find(name)
    if nNode.isNil():
        x.append(name, p)
    else:
        nNode.append(p)

proc on*[T](x: var AsyncEventEmitter[T], 
            name: string, ps: varargs[proc(e: T): Future[void] {.closure.}]) =
    ## Assigns a event handler with the future. If the event
    ## doesn't exist, it will be created.
    var nNode = x.find(name)
    if nNode.isNil():
        nNode = newAsyncEventNameNode[T](name)
        x.append(nNode)
    for p in ps:
        nNode.append(p)

proc on*[T](x: var AsyncEventTypeEmitter[T], 
            typ: string, name: string, p: proc(e: T): Future[void] {.closure.}) =
    ## Assigns a event handler with the callback. If the event
    ## doesn't exist, it will be created.
    var tNode = x.find(typ)
    if tNode.isNil():
        x.append(typ, name, p)
    else:
        var nNode = tNode.find(name)
        if nNode.isNil():
            tNode.append(name, p)
        else:
            nNode.append(p)

proc on*[T](x: var AsyncEventTypeEmitter[T], 
            typ: string, name: string, ps: varargs[proc(e: T): Future[void] {.closure.}]) =
    ## Assigns a event handler with the callback. If the event
    ## doesn't exist, it will be created.
    var tNode = x.find(typ)
    var nNode: AsyncEventNameNode[T]
    if tNode.isNil():
        tNode = newAsyncEventTypeNode[T](typ)
        nNode = newAsyncEventNameNode[T](name)
        x.append(tNode)
        tNode.append(nNode)
    else:
        nNode = tNode.find(name)
        if nNode.isNil():
            nNode = newAsyncEventNameNode[T](name)
            tNode.append(nNode)
    for p in ps:
        nNode.append(p)

proc off*[T](x: var AsyncEventEmitter[T], 
             name: string, p: proc(e: T): Future[void] {.closure.}) =
    ## Removes the callback from the specified event handler.
    var (pnNode, cnNode) = x.finds(name)
    if not cnNode.isNil():
        var (ppNode, cpNode) = cnNode.finds(p)
        if not cpNode.isNil():
            cnNode.remove(ppNode, cpNode)
            if cnNode.head.isNil():
                x.remove(pnNode, cnNode)

proc off*[T](x: var AsyncEventEmitter[T], 
             name: string, ps: varargs[proc(e: T): Future[void] {.closure.}]) =
    var (pnNode, cnNode) = x.finds(name)
    if not cnNode.isNil():
        for p in ps:
            var (ppNode, cpNode) = cnNode.finds(p)
            if not cpNode.isNil():
                cnNode.remove(ppNode, cpNode)
        if cnNode.head.isNil():
            x.remove(pnNode, cnNode)

proc off*[T](x: var AsyncEventTypeEmitter[T], 
             typ: string, name: string, p: proc(e: T): Future[void] {.closure.}) =
    ## Removes the callback from the specified event handler.
    var (ptNode, ctNode) = x.finds(typ)
    if not ctNode.isNil():
        var (pnNode, cnNode) = ctNode.finds(name)
        if not cnNode.isNil():
            var (ppNode, cpNode) = cnNode.finds(p)
            if not cpNode.isNil():
                cnNode.remove(ppNode, cpNode)
                if cnNode.head.isNil():
                    ctNode.remove(pnNode, cnNode)
                if ctNode.head.isNil():
                    x.remove(ptNode, ctNode)

proc off*[T](x: var AsyncEventTypeEmitter[T], 
             typ: string, name: string, ps: varargs[proc(e: T): Future[void] {.closure.}]) =
    ## Removes the callback from the specified event handler.
    var (ptNode, ctNode) = x.finds(typ)
    if not ctNode.isNil():
        var (pnNode, cnNode) = ctNode.finds(name)
        if not cnNode.isNil():
            for p in ps:
                var (ppNode, cpNode) = cnNode.finds(p)
                if not cpNode.isNil():
                    cnNode.remove(ppNode, cpNode)
            if cnNode.head.isNil():
                ctNode.remove(pnNode, cnNode)
            if ctNode.head.isNil():
                x.remove(ptNode, ctNode)

proc emit*[T](x: AsyncEventEmitter[T], name: string, e: T) {.async.} =
    ## Fires an event handler with specified event arguments.
    var nNode = x.find(name)
    if not nNode.isNil():
        for pNode in nNode.nodes():
            await pNode.value(e)

proc emit*[T](x: AsyncEventTypeEmitter[T], typ: string, name: string, e: T) {.async.} =
    ## Fires an event handler with specified event arguments.
    var tNode = x.find(typ)
    if not tNode.isNil():
        var nNode = tNode.find(name)
        if not nNode.isNil():
            for pNode in nNode.nodes():
                await pNode.value(e)

when isMainModule:
    type 
        MyArgs = ref object
            id: int

    proc foo(e: MyArgs): Future[void] {.closure.} =
        var fut = newFuture[void]()
        assert e.id == 1
        fut.complete()
        return fut

    proc bar(e: MyArgs) {.async, closure.} =
        await sleepAsync(100)
        assert e.id == 1

    var em = initAsyncEventTypeEmitter[MyArgs]()
    var args = new(MyArgs)  
    args.id = 1

    em.on("A", "/path", foo, bar)
    em.on("B", "/path", foo)
    em.on("B", "/", bar)

    proc emAsync(foo: proc (e: MyArgs): Future[void] {.closure.},
                 bar: proc (e: MyArgs): Future[void] {.closure.}) {.async.} =
        assert em.countTypes() == 2
        assert em.countNames("A") == 1
        assert em.countNames("B") == 2
        assert em.countProcs("A", "/path") == 2
        assert em.countProcs("B", "/path") == 1
        assert em.countProcs("B", "/") == 1

        await em.emit("A", "/path", args)
        await em.emit("B", "/", args)

        em.off("A", "/path", foo, bar)

        assert em.countTypes() == 1
        assert em.countNames("A") == 0
        assert em.countNames("B") == 2
        assert em.countProcs("A", "/path") == 0

        em.off("B", "/path", foo)
        em.off("B", "/", bar)

        assert em.countTypes() == 0
        assert em.countNames("B") == 0
        assert em.countProcs("B", "/path") == 0

    asyncCheck emAsync(foo, bar)

    var emm = initAsyncEventEmitter[MyArgs]()

    emm.on("A", foo, bar)
    emm.on("B", foo)
    emm.on("B", foo, bar)

    proc emmAsync(foo: proc (e: MyArgs): Future[void] {.closure.},
                  bar: proc (e: MyArgs): Future[void] {.closure.}) {.async.} =
        assert emm.countNames() == 2
        assert emm.countProcs("A") == 2
        assert emm.countProcs("B") == 3

        await emm.emit("A", args)
        await emm.emit("B", args)

        emm.off("A", foo, bar)
        emm.off("B", foo)

        assert emm.countNames() == 1
        assert emm.countProcs("A") == 0
        assert emm.countProcs("B") == 2

    asyncCheck emmAsync(foo, bar)

    runForever()
