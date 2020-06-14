package wren;

import wren.FnDebug;
import wren.ObjModule;
import wren.Buffer.ValueBuffer;
import wren.Buffer.ByteBuffer;

typedef ObjFn = {
    > Obj,
    var obj:Obj;
    var code:ByteBuffer;
    var constants:ValueBuffer;
    /**
     * The module where this function was defined.
     */
    var module:ObjModule;

    /**
     * The maximum number of stack slots this function may use.
     */
    var maxSlots:Int;
    /**
     * The number of upvalues this function closes over.
     */
    var numUpvalues:Int;

    /**
     * The number of parameters this function expects. Used to ensure that .call
     * handles a mismatch between number of parameters and arguments. This will
     * only be set for fns, and not ObjFns that represent methods or scripts.
     */
    var arity:Int;
    var debug:FnDebug;

}