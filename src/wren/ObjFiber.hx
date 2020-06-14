package wren;

import wren.FiberState;
import wren.ObjUpvalue;
import wren.CallFrame;

typedef ObjFiber = {
    > Obj,
    var obj:Obj;

    /**
     * The stack of value slots. This is used for holding local variables and
     * temporaries while the fiber is executing. It heap-allocated and grown as
     * needed.
     */
    var stack:Array<Value>;

    /**
     * A pointer to one past the top-most value on the stack.
     */
    var stackTop:Value;
    /**
     * The number of allocated slots in the stack array.
     */
    var stackCapacity:Int;

    /**
     * The stack of call frames. This is a dynamic array that grows as needed but
     * never shrinks.
     */
    var callFrame:Array<CallFrame>;

    /**
     * The number of frames currently in use in [frames].
     */
    var numFrames:Int;

    /**
     * The number of [frames] allocated.
     */
    var frameCapacity:Int;

    /**
     * Pointer to the first node in the linked list of open upvalues that are
     * pointing to values still on the stack. The head of the list will be the
     * upvalue closest to the top of the stack, and then the list works downwards.
     */
    var openUpvalues:ObjUpvalue;

    /**
     * The fiber that ran this one. If this fiber is yielded, control will resume
     * to this one. May be `NULL`.
     */
    var caller:ObjFiber;

    /**
     * If the fiber failed because of a runtime error, this will contain the
     * error object. Otherwise, it will be null.
     */
    var error:Value;

    var state:FiberState;
}