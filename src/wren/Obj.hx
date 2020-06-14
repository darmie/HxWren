package wren;


/**
 * Base struct for all heap-allocated objects.
 */
typedef Obj = {
    var type:ObjType;
    var isDark:Bool;

    /**
     * The object's class.
     */
    var classObj:ObjClass;

    /**
     * The next object in the linked list of all currently allocated objects.
     */
    var next:Obj;
}


