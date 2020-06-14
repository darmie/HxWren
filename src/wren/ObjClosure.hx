package wren;

import wren.ObjUpvalue;
import wren.ObjFn;

/**
 * An instance of a first-class function and the environment it has closed over.
 * Unlike [ObjFn], this has captured the upvalues that the function accesses.
 */
typedef ObjClosure = {
    > Obj,
    var obj:Obj;
    /**
     * The function that this closure is an instance of.
     */
    var fn:ObjFn;
    /**
     * The upvalues this function has closed over.
     */
    var upvalues:Array<ObjUpvalue>;
};