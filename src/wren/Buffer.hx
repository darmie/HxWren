package wren;

import wren.Value;


typedef IntBuffer = Buffer<Int>;
typedef ByteBuffer = IntBuffer;
typedef StringBuffer = Buffer<Int>;
typedef ValueBuffer = Buffer<Value>;
typedef MethodBuffer = Buffer<Method>;

/**
 * TODO: Change this to use a map.
 */
typedef SymbolTable = StringBuffer;

class Buffer<T> {
    public var data:Array<T>;
    public var count:Int;
    public var capacity:Int;

    var vm:VM;

    public function new(vm:VM) {
        this.vm = vm;
        data = [];
        capacity = 0;
        count = 0;
    }

    public function clear() {
        // vm.reallocate(data, 0, 0);
        data = [];
        capacity = 0;
        count = 0;
    }

    public function fill(data:T, count:Int) {
        
    }

    public function write(data:T) {
        
    }
}