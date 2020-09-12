package wren;

import wren.ObjString;
import wren.Buffer.SymbolTable;
import wren.Buffer.ValueBuffer;

/**
 * A loaded module and the top-level variables it defines.
 * 
 * While this is an Obj and is managed by the GC, it never appears as a
 * first-class object in Wren.
 */
typedef ObjModule = {
    > Obj,
    var obj:Obj;

    /**
     * The currently defined top-level variables.
     */
    var variables:ValueBuffer;
    /**
     * Symbol table for the names of all module variables. Indexes here directly
     * correspond to entries in [variables].
     */
    var variableNames:SymbolTable;
    /**
     * The name of the module.
     */
    var name:ObjString;
}