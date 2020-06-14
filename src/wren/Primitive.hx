package wren;

/**
 * The type of a primitive function.
 * 
 * Primitives are similiar to foreign functions, but have more direct access to
 * VM internals. It is passed the arguments in [args]. If it returns a value,
 * it places it in `args[0]` and returns `true`. If it causes a runtime error
 * or modifies the running fiber, it returns `false`.
 */
typedef Primitive = (vm:VM, args:Array<Value>)->Bool;