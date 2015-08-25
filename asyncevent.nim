import asyncdispatch, lists

type
    AsyncEventArgs* = object of RootObj
    AsyncEventProc* = proc(e: AsyncEventArgs): Future[void] {.closure.}
    AsyncEventHandler = tuple[name: string, handlers: DoublyLinkedRing[AsyncEventProc]]
    AsyncEventNameHandler = tuple[event: string, nameHandlers: DoublyLinkedRing[AsyncEventHandler]]
    AsyncEventNameEmitter* = object
        events: DoublyLinkedRing[AsyncEventNameHandler]

proc initAsyncEventNameEmitter*(): AsyncEventNameEmitter =
    result.events = initDoublyLinkedRing[AsyncEventNameHandler]()

proc find(x: AsyncEventNameEmitter, event: string): 
         DoublyLinkedNode[AsyncEventNameHandler] =
    for node in x.events.nodes():
        if node.value.event == event:
            return node

proc find(x: AsyncEventNameHandler, name: string): 
         DoublyLinkedNode[AsyncEventHandler] =
    for node in x.nameHandlers.nodes():
        if node.value.name == name:
            return node

proc find(x: AsyncEventHandler, p: AsyncEventProc): 
         DoublyLinkedNode[AsyncEventProc] =
    for node in x.handlers.nodes():
        if node.value == p:
            return node

proc initAsyncEventHandler(name: string, p: AsyncEventProc): 
                          AsyncEventHandler = 
    result.name = name
    result.handlers = initDoublyLinkedRing[AsyncEventProc]()
    result.handlers.append(p)

proc initAsyncEventNameHandler(event: string, handler: AsyncEventHandler): 
                              AsyncEventNameHandler =
    result.event = event
    result.nameHandlers = initDoublyLinkedRing[AsyncEventHandler]()
    result.nameHandlers.append(handler)

proc on*(x: var AsyncEventNameEmitter, 
         event: string, name: string, p: AsyncEventProc) =
    var eNode = x.find(event)
    if eNode.isNil():
        x.events.append(initAsyncEventNameHandler(
            event, initAsyncEventHandler(name, p)))
    else:
        var nNode = eNode.value.find(name)
        if nNode.isNil():
            eNode.value.nameHandlers.append(initAsyncEventHandler(name, p))
        else:
            nNode.value.handlers.append(p)

proc off*(x: var AsyncEventNameEmitter, 
          event: string, name: string, p: AsyncEventProc) =
    var eNode = x.find(event)
    if not eNode.isNil():
        var nNode = eNode.value.find(name)
        if not nNode.isNil():
            var pNode = nNode.value.find(p)
            if not pNode.isNil():
                nNode.value.handlers.remove(pNode)
                if nNode.value.handlers.head.isNil():
                    eNode.value.nameHandlers.remove(nNode)
                if eNode.value.nameHandlers.head.isNil():
                    x.events.remove(eNode)

proc emit*(x: AsyncEventNameEmitter, 
           event: string, name: string, e: AsyncEventArgs) =
    var eNode = x.find(event)
    if not eNode.isNil():
        var nNode = eNode.value.find(name)
        if not nNode.isNil():
            for p in nNode.value.handlers.items():
                asyncCheck p(e)

when isMainModule:
    var em = initAsyncEventNameEmitter()

    proc foo1(e: AsyncEventArgs) {.async.} =
        await sleepAsync(100)
        echo 1

    proc foo2(e: AsyncEventArgs): Future[void] {.closure.} =
        var fut1 = newFuture[void]()
        var fut2 = sleepAsync(100)
        fut2.callback = proc() =
            echo 2
            fut1.complete()
        return fut1

    proc foo3(e: AsyncEventArgs): Future[void] {.closure.} =
        var fut1 = newFuture[void]()
        var fut2 = sleepAsync(100)
        fut2.callback = proc() =
            echo 3
            fut1.complete()
        return fut1

    em.on("A", "/path", foo1)
    em.on("A", "/path", foo2)
    em.on("A", "/path", foo3)
    em.on("B", "/", foo1)
    em.on("B", "/", foo1)

    em.emit("A", "/path", AsyncEventArgs())
    em.emit("B", "/", AsyncEventArgs())

    em.off("A", "/path", foo1)
    em.off("A", "/path", foo2)
    em.off("A", "/path", foo2)
    em.off("A", "/path", foo3)
    em.emit("A", "/path", AsyncEventArgs())

    runForever()
    
