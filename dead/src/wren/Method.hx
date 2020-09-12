package wren;

using wren.WrenFn;

typedef Method = {
    ?type: MethodType,
    ?as:{
        ?primitive:Primitive,
        ?foreign: WrenForeignMethodFn,
        ?closure: ObjClosure
    }
}