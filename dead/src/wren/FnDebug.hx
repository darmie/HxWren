package wren;

import wren.Buffer.IntBuffer;

/**
 * TODO: See if it's actually a perf improvement to have this in a separate
 * struct instead of in ObjFn.
 * Stores debugging information for a function used for things like stack
 * traces.
 */
typedef FnDebug = {
    /**
     * The name of the function. Heap allocated and owned by the FnDebug.
     */
    var name:String;
    /**
     * An array of line numbers. There is one element in this array for each
     * bytecode in the function's bytecode array. The value of that element i
     * the line in the source code that generated that instruction.
     */
    var sourceLines:IntBuffer;
}