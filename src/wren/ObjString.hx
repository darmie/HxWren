package wren;

typedef ObjString = {
    > Obj,
    var obj:Obj;
    /**
     *  The hash value of the string's contents.
     */
    var hash:Int;
    var value:String;
}