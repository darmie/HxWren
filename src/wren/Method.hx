package wren;

typedef Method = {
    ?type: MethodType,
    ?as:{
        ?primitive:Primitive,
        ?foreign: WrenForeignMethodFn,
        ?closure: ObjClosure
    }
}