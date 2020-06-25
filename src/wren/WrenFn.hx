package wren;

typedef WrenForeignMethodFn = (vm:VM)->Void;


typedef WrenForeignClassMethods = {
    /**
     * The callback invoked when the foreign object is created.
     * 
     * This must be provided. Inside the body of this, it must call
     * [wrenSetSlotNewForeign()] exactly once.
     */
    ?allocate:WrenForeignMethodFn,

    /**
     * The callback invoked when the garbage collector is about to collect a
     * foreign object's memory.
     * 
     * This may be `NULL` if the foreign class does not need to finalize.
     */
    ?finalize: (data:Dynamic)->Void
}

/**
 * A generic allocation function that handles all explicit memory management
 * used by Wren. It's used like so:
 * - To allocate new memory, [memory] is NULL and [newSize] is the desired
 * size. It should return the allocated memory or NULL on failure.

 * - To attempt to grow an existing allocation, [memory] is the memory, and
 * [newSize] is the desired size. It should return [memory] if it was able to
 * grow it in place, or a new pointer if it had to move it.

 * - To shrink memory, [memory] and [newSize] are the same as above but it will
 * always return [memory].

 * - To free memory, [memory] will be the memory to free and [newSize] will be
 * zero. It should return NULL.
 */
typedef WrenReallocateFn = (memory:Pointer<Dynamic>, newSize:Int) -> Void;

/**
 * Gives the host a chance to canonicalize the imported module name,
 * potentially taking into account the (previously resolved) name of the module
 * that contains the import. Typically, this is used to implement relative
 * imports.
 */
typedef WrenResolveModuleFn = (vm:VM, importer:String, name:String)->String;

/**
 * Loads and returns the source code for the module [name].
 */
typedef WrenLoadModuleFn = (vm:VM, name:String)->String;

/**
 * Returns a pointer to a foreign method on [className] in [module] with
 * [signature].
 */
typedef WrenBindForeignMethodFn = (vm:VM, module:String, className:String, isStatic:Bool, signature:String)->WrenForeignMethodFn;

/**
 * Returns a pair of pointers to the foreign methods used to allocate and
 * finalize the data for instances of [className] in resolved [module].
 */
typedef WrenBindForeignClassFn = (vm:VM, module:String, className:String)->WrenForeignClassMethods;


typedef WrenWriteFn = (vm:VM, text:String)->String;

typedef WrentErrorFn = (vm:VM, type:ErrorType, module:String, line:Int, message:String) -> Void;