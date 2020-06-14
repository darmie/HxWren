package wren;

import wren.ObjClosure;

typedef CallFrame = {
    /**
     * Instruction pointer
     */
    var ip:Int;

    /**
     * The closure being executed.
     */
    var closure:ObjClosure;

    /**
     * The first stack slot used by this call frame. This will contain
     * the receiver, followed by the function's parameters, then local variables
     * and temporaries.
     */
    var stackStart:Value;
}