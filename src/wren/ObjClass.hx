package wren;

import wren.Buffer.MethodBuffer;

typedef ObjClass = {
    > Obj,
    var obj:Obj;
    var superClass:ObjClass;

    /**
     * The number of fields needed for an instance of this class, including all
     * of its superclass fields.
     */
    var numFields:Int;

    /**
     * The name of the class.
     */
    var name:ObjString;

    /**
     * The table of methods that are defined in or inherited by this class.
     * Methods are called by symbol, and the symbol directly maps to an index in
     * this table. This makes method calls fast at the expense of empty cells in
     * the list for methods the class doesn't support.
     * 
     * You can think of it as a hash table that never has collisions but has a
     * really low load factor. Since methods are pretty small (just a type and a
     * pointer), this should be a worthwhile trade-off.
     */
    var methods:MethodBuffer;
}
