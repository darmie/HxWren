package wren;


/**
 * The dynamically allocated data structure for a variable that has been used
 * by a closure. Whenever a function accesses a variable declared in an
 * enclosing function, it will get to it through this.
 * 
 * An upvalue can be either "closed" or "open". An open upvalue points directly
 * to a [Value] that is still stored on the fiber's stack because the local
 * variable is still in scope in the function where it's declared.
 * 
 * When that local variable goes out of scope, the upvalue pointing to it will
 * be closed. When that happens, the value gets copied off the stack into the
 * upvalue itself. That way, it can have a longer lifetime than the stack
 * variable.
 */
typedef ObjUpvalue = {
    > Obj,
    /**
     * The object header. Note that upvalues have this because they are garbage
     * collected, but they are not first class Wren objects.
     */
    var obj:Obj;
    /**
     * The variable this upvalue is referencing.
     */
    var value:Value;

    /**
     * If the upvalue is closed (i.e. the local variable it was pointing too has
     * been popped off the stack) then the closed-over value will be hoisted out
     * of the stack into here. [value] will then be changed to point to this.
     */
    var closed:Value;

    /**
     * Open upvalues are stored in a linked list by the fiber. This points to the
     * next upvalue in that list.
     */
    var next:ObjUpvalue;
}