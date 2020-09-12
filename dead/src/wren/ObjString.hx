package wren;

import haxe.crypto.Sha1;

typedef TObjString = {
    > Obj,
    var obj:Obj;
    /**
     *  The hash value of the string's contents.
     */
    var hash:Int;
    var value:String;
}
@:forward(type, classObj, isDark, next, obj, hash, value)
abstract ObjString(TObjString) from TObjString to TObjString {
    inline function new(i:TObjString){
        this = i;
    }

    @:from public static inline function fromString(s:String):ObjString {
        return {
            type: OBJ_STRING,
            classObj: null,
            value: s,
            hash: 0,
            obj: null,
            isDark: false, 
            next: null
        }
    }
    @:to public function toString():String {
        return this.value;
    }
}