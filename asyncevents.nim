import asyncdispatch, typeinfo

type
    AsyncEventProc*[T] = proc(e: T): Future[void] {.closure.}

    AsyncEventProcNodeObj[T] = object
        next: ref AsyncEventProcNodeObj[T]
        value: proc(e: T): Future[void] {.closure.}
    AsyncEventProcNode[T] = ref AsyncEventProcNodeObj[T]

    AsyncEventNameNodeObj[T] = object
        next: ref AsyncEventNameNodeObj[T]
        value: string
        head: AsyncEventProcNode[T]
        tail: AsyncEventProcNode[T]
        length: int
    AsyncEventNameNode[T] = ref AsyncEventNameNodeObj[T]

    # AsyncEventEmitter*[T] = object
    #     head: AsyncEventNameNode[T]

    AsyncEventTypeNodeObj[T] = object
        next: ref AsyncEventTypeNodeObj[T]
        value: string
        head: AsyncEventNameNode[T]
        tail: AsyncEventNameNode[T]
        length: int
    AsyncEventTypeNode[T] = ref AsyncEventTypeNodeObj[T]

    AsyncEventTypeEmitter*[T] = object
        head: AsyncEventTypeNode[T]
        tail: AsyncEventTypeNode[T]
        length: int

proc initAsyncEventTypeEmitter*[T](): AsyncEventTypeEmitter[T] =
    discard

template newImpl() = 
    new(result)
    result.value = value

proc newAsyncEventProcNode[T](value: proc(e: T): Future[void] {.closure.}): 
                             AsyncEventProcNode[T] =
    newImpl()

proc newAsyncEventNameNode[T](value: string): AsyncEventNameNode[T] =
    newImpl()

proc newAsyncEventTypeNode[T](value: string): AsyncEventTypeNode[T] =
    newImpl()

template nodesImpl() {.dirty.} =
    var it = L.head
    while it != nil:
        var nxt = it.next
        yield it
        it = nxt

iterator nodes[T](L: AsyncEventNameNode[T]) {.inline.} = 
    nodesImpl()

iterator nodes[T](L: AsyncEventTypeNode[T]) {.inline.} = 
    nodesImpl()

iterator nodes[T](L: AsyncEventTypeEmitter[T]) {.inline.} = 
    nodesImpl()

template findImpl() {.dirty.} =
    for n in L.nodes():
        if n.value == value: return n

proc find[T](L: AsyncEventNameNode[T], value: proc(e: T): Future[void] {.closure.}): 
            AsyncEventProcNode[T] =
    findImpl()

proc find[T](L: AsyncEventTypeNode[T], value: string): 
            AsyncEventNameNode[T] =
    findImpl()

proc find[T](L: AsyncEventTypeEmitter[T], value: string): 
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
    ## appends a node `n` to `L`. Efficiency: O(1).
    appendImpl()

proc append[T](L: AsyncEventTypeNode[T], n: AsyncEventNameNode[T]) = 
    ## appends a node `n` to `L`. Efficiency: O(1).
    appendImpl()

proc append[T](L: var AsyncEventTypeEmitter[T], n: AsyncEventTypeNode[T]) = 
    ## appends a node `n` to `L`. Efficiency: O(1).
    appendImpl()

proc append[T](nNode: AsyncEventNameNode[T], p: proc(e: T): Future[void] {.closure.}) = 
    nNode.append(newAsyncEventProcNode[T](p))

proc append[T](tNode: AsyncEventTypeNode[T], name: string, p: proc(e: T): Future[void] {.closure.}) = 
    var pNode = newAsyncEventProcNode[T](p)
    var nNode = newAsyncEventNameNode[T](name)
    nNode.append(pNode)
    tNode.append(nNode)

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

proc remove[T](L: var AsyncEventTypeEmitter[T], prev: AsyncEventTypeNode[T], curr: AsyncEventTypeNode[T]) = 
    removeImpl()

proc countProcs*[T](L: AsyncEventTypeEmitter[T], typ: string, name: string): int {.inline.} =
    var tnode = L.find(typ)
    if not tnode.isNil():
        var nnode = tnode.find(name)
        if not nnode.isNil():
            return nnode.length

proc countNames*[T](L: AsyncEventTypeEmitter[T], typ: string): int {.inline.} =
    var node = L.find(typ)
    if not node.isNil(): 
        return node.length

proc countTypes*[T](L: AsyncEventTypeEmitter[T]): int {.inline.} =
    return L.length

proc on*[T](x: var AsyncEventTypeEmitter[T], 
            typ: string, name: string, p: proc(e: T): Future[void] {.closure.}) =
    var tNode = x.find(typ)
    if tNode.isNil():
        x.append(typ, name, p)
    else:
        var nNode = tNode.find(name)
        if nNode.isNil():
            tNode.append(name, p)
        else:
            nNode.append(p)

proc off*[T](x: var AsyncEventTypeEmitter[T], 
             typ: string, name: string, p: proc(e: T): Future[void] {.closure.}) =
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

proc emit*[T](x: var AsyncEventTypeEmitter[T], 
              typ: string, name: string, e: T) =
    var tNode = x.find(typ)
    if not tNode.isNil():
        var nNode = tNode.find(name)
        if not nNode.isNil():
            for pNode in nNode.nodes():
                asyncCheck pNode.value(e)

when isMainModule:
    type 
        MyArgs = ref object
            id: int

    proc foo1(e: MyArgs): Future[void] {.closure.} =
        var fut = newFuture[void]()
        assert e.id == 1
        return fut

    proc foo2(e: MyArgs) {.async.} =
        await sleepAsync(100)
        assert e.id == 2

    var em = initAsyncEventTypeEmitter[MyArgs]()
    var argsA = new(MyArgs) 
    var argsB = new(MyArgs) 
    argsA.id = 1
    argsB.id = 2

    em.on("A", "/path", foo1)
    em.on("A", "/path", foo1)
    em.on("B", "/path", foo2)
    em.on("B", "/", foo2)

    assert em.countTypes() == 2
    assert em.countNames("A") == 1
    assert em.countNames("B") == 2
    assert em.countProcs("A", "/path") == 2
    assert em.countProcs("B", "/path") == 1

    em.emit("A", "/path", argsA)
    em.emit("B", "/", argsB)

    em.off("A", "/path", foo1)
    em.off("A", "/path", foo1)

    assert em.countTypes() == 1
    assert em.countNames("A") == 0
    assert em.countNames("B") == 2
    assert em.countProcs("A", "/path") == 0
    assert em.countProcs("B", "/path") == 1

    em.off("B", "/path", foo2)
    em.off("B", "/", foo2)

    assert em.countTypes() == 0
    assert em.countNames("A") == 0
    assert em.countNames("B") == 0
    assert em.countProcs("A", "/path") == 0
    assert em.countProcs("B", "/path") == 0

    runForever()