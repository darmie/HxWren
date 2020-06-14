package wren;

typedef ObjRange = {
    > Obj,
    var obj:Obj;
    /**
     * The beginning of the range.
     */
    var from:Float;
    /**
     * The end of the range. May be greater or less than [from].
     */
    var to:Float;
    /**
     * True if [to] is included in the range.
     */
    var isInclusive:Bool;
}