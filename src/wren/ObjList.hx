package wren;

import wren.Buffer.ValueBuffer;

typedef ObjList = {
    > Obj,
    var ?obj:Obj;
    /**
     * The elements in the list.
     */
    var ?elements:ValueBuffer;
}