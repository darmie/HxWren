package wren;

enum ValueType {
    VAL_FALSE;
    VAL_NULL;
    VAL_NUM;
    VAL_TRUE;
    VAL_UNDEFINED;
    VAL_OBJ;
}

typedef TValue = {
    var type: ValueType;
    var as: {
       var num:Float;
       var obj:Obj;
    }
}

@:forward(type, as)
abstract Value(TValue) from TValue to TValue {
    public inline function new(?v:TValue) {
        this = v == null ? {type:VAL_NULL, as: null} : v;
    }

    @:from
    public inline static function fromObj(obj:Obj):Value {
        return new Value({
            type: VAL_OBJ,
            as:{
                num: null,
                obj: obj
            }
        });
    }

    @:from 
    public inline static function fromNum(num:Float):Value {
        return new Value({
            type: VAL_NUM,
            as:{
                num: num,
                obj: null
            }
        });
    }

    @:to 
    public function toNum():Float {
        return this.as.num;
    }

    @:to
    public function toObj():Obj {
        return this.as.obj;
    }

    public inline function isBool():Bool {
       return this.type == VAL_TRUE || this.type == VAL_FALSE; 
    }

    public inline function isObj() {
        return this.type == VAL_OBJ && this.as.obj != null;
    }

    public function isObjType(type:ObjType) {
        return isObj() && this.as.obj.type == type;
    }

    public static inline function isSame(a:Value, b:Value):Bool {
        if (a.type != b.type) return false;
        if (a.type == VAL_NUM) return a.as.num == b.as.num;
        return a.as.obj == b.as.obj;
    }

    public static function equal(a:Value, b:Value):Bool {
        return false;
    }

    public inline function isNum():Bool {
        return this.type == VAL_NUM && this.as.num != null;
    }

    public inline function isUndefined():Bool {
        return this.type == VAL_UNDEFINED;
    }


    public inline function isNull():Bool {
        return this.type == VAL_NULL && this.as == null;
    }
}