package wren;

import wren.Buffer.ValueBuffer;
import wren.Buffer.SymbolTable;
import wren.Macros.*;
import haxe.ds.Vector;


class VM {

    public var boolClass:ObjClass;
    public var classClass:ObjClass;
    public var fiberClass:ObjClass;
    public var fnClass:ObjClass;
    public var listClass:ObjClass;
    public var mapClass:ObjClass;
    public var nullClass:ObjClass;
    public var numClass:ObjClass;
    public var objectClass:ObjClass;
    public var rangeClass:ObjClass;
    public var stringClass:ObjClass;


    /**
     * The fiber that is currently running.
     */
    public var fiber:ObjFiber;

    /**
     * The loaded modules. Each key is an ObjString (except for the main module,
     * whose key is null) for the module's name and the value is the ObjModule
     * for the module.
     */
    public var lastModule:ObjModule;

    /**
     * Memory management data:
     * 
     * The number of bytes that are known to be currently allocated. Includes all
     * memory that was proven live after the last GC, as well as any new bytes
     * that were allocated since then. Does *not* include bytes for objects that
     * were freed since the last GC.
     */
    public var bytesAllocated:Int;

    /**
     * The number of total allocated bytes that will trigger the next GC.
     */
    public var nextGC:Int;

    /**
     * The first object in the linked list of all currently allocated objects.
     */
    public var first:Obj;

    /**
     * The "gray" set for the garbage collector. This is the stack of unprocessed
     * objects while a garbage collection pass is in process.
     */
    public var gray:Array<Obj>;
    public var grayCount:Int;
    public var grayCapacity:Int;

    public static final WREN_MAX_TEMP_ROOTS:Int = 5;

    /**
     * The list of temporary roots. This is for temporary or new objects that are
     * not otherwise reachable but should not be collected.
     * 
     * They are organized as a stack of pointers stored in this array. This
     * implies that temporary roots need to have stack semantics: only the most
     * recently pushed object can be released.
     */
    public final tempRoots:Vector<Obj> = new Vector<Obj>(WREN_MAX_TEMP_ROOTS);

    public var numTempRoots:Int;

    /**
     * Pointer to the first node in the linked list of active handles or NULL if
     * there are none.
     */
    public var handles:WrenHandle;

    /**
     * Pointer to the bottom of the range of stack slots available for use from
     * the C API. During a foreign method, this will be in the stack of the fiber
     * that is executing a method.
     * 
     * If not in a foreign method, this is initially NULL. If the user requests
     * slots by calling wrenEnsureSlots(), a stack is created and this is
     * initialized.
     */
    public var apiStack:Value;

    public var configuration:WrenConfiguration;

    /**
     * Compiler and debugger data:
     * 
     * The compiler that is currently compiling code. This is used so that heap
     * allocated objects used by the compiler can be found if a GC is kicked off
     * in the middle of a compile.
     */
    public var compiler:Compiler;

    /**
     * There is a single global symbol table for all method names on all classes.
     * Method calls are dispatched directly by index in this table.
     */
    public var methodNames:SymbolTable;

    public function new() {
    }

    public function symbolTableEnsure(symbols:SymbolTable, name:String, length:Int):Int {
        trace(symbols, name, length);
        return 1;
    }

    public function bindMethod(objectClass:ObjClass, symbol:Int, method:Method) {
        trace(objectClass, symbol, method);
    }

    /**
     * Returns the class of [value].
     * 
     * Unlike wrenGetClassInline in wren_vm.h, this is not inlined. Inlining helps
     * performance (significantly) in some cases, but degrades it in others. The
     * ones used by the implementation were chosen to give the best results in the
     * benchmarks.
     * @param value 
     * @return ObjClass
     */
    public function getClass(value:Value):ObjClass {
        return null;
    }
    
    /**
     * Creates a new open upvalue pointing to [value] on the stack.
     * @param value 
     * @return ObjUpvalue
     */
    public function newUpvalue(value:Value):ObjUpvalue {
        return null;
    }
    /**
     * Mark [obj] as reachable and still in use. This should only be called
     * during the sweep phase of a garbage collection.
     * @param obj 
     */
    public function greyObj(obj:Obj) {
        
    }

    /**
     * Mark the values in [value] as reachable and still in use. This should only
     * be called during the sweep phase of a garbage collection.
     * @param value 
     */
    public function greyValue(value:Value) {
        
    }

    /**
     * Mark the values in [buffer] as reachable and still in use. This should only
     * be called during the sweep phase of a garbage collection.
     * @param value 
     */
     public function greyBuffer(value:Value) {
        
    }

    /**
     * Processes every object in the gray stack until all reachable objects have
     * been marked. After that, all objects are either white (freeable) or black
     * (in use and fully traversed).
     *
     */
    public function blackenObjects() {
        
    }

    /**
     * Releases all memory owned by [obj], including [obj] itself.
     * @param obj 
     */
    public function freeObj(obj:Obj) {
        
    }


    public static function reallocate<T>(vm:VM, memory:T):T {
        return null;
    }

    /**
     * Immediately run the garbage collector to free unused memory
     */
    public function collectGarbage() {
        
    }

    public function newStringLength(text:String) {
        
    }

    public function allocateString(text:String) {
        
    }

    public function stringFormat(format:String, args:Array<Dynamic>):Value {
        return null;
    }

    /**
     * Validates a function
     * @param arg 
     * @param argName 
     * @return Bool
     */
    public function validateFn(arg:Value, argName:String):Bool {
        if(IS_CLOSURE(arg)) return true;

        fiber.error = stringFormat("$ must be a function.", [argName]);
        return false;
    }

    /**
     * Validates that the given [arg] is an integer. Returns true if it is. If not, 
     * reports an error and returns false.
     * @param arg 
     * @param argName 
     * @return Bool
     */
    public static function validateInt(arg:Value, argName:String):Bool {
        return false;
    }

    /**
     * Validates that the argument at [argIndex] is an integer within `[0, count]`.
     * Also allows negative indices which map backwards from the end. Returns the
     * valid positive index value. If invalid, reports an error and returns
     * `UINT32_MAX`.
     * @param arg 
     * @param count 
     * @param argNames 
     * @return Int
     */
    public function validateIndex(arg:Value, count:Int, argNames:Array<Value>):Int {
        return 0;
    }

    /**
     * Creates a new list with [numElements] elements (which are left uninitialized.)
     * @param numElelemts 
     * @return ObjList
     */
    public function newList(numElelemts:Int):ObjList {
        return null;
    }

    /**
     * Inserts [value] in [list] at [index], shifting down the other elements.
     * @param list 
     * @param value 
     * @param index 
     */
    public function listInsert(list:ObjList, value:Value, index:Int) {
        
    }

    /**
     * Removes and returns the item at [index] from [list].
     * @param list 
     * @param index 
     * @return Value
     */
    public function listRemoveAt(list:ObjList, index:Int):Value {
        return null;
    }


    /**
     * We need buffers of a few different types. To avoid lots of casting between
     * void* and back, we'll use the preprocessor as a poor man's generics and let
     * it generate a few type-specific ones.
     * @param buffer 
     * @param data 
     */
    public function valueBufferWrite(buffer:ValueBuffer, data:Value) {
        
    }
    /**
     * Given a [range] and the [length] of the object being operated on, determines
     * the series of elements that should be chosen from the underlying object.
     * Handles ranges that count backwards from the end as well as negative ranges.

     * Returns the index from which the range should start or `UINT32_MAX` if the
     * range is invalid. After calling, [length] will be updated with the number of
     * elements in the resulting sequence. [step] will be direction that the range
     * is going: `1` if the range is increasing from the start index or `-1` if the
     * range is decreasing.
     * @param range 
     * @param length 
     * @param step 
     */
    public function calculateRange(range:ObjRange, length:Int, step:Int):Int {
        return 0;
    }


    public function newRange(from:Float, to:Float, isInclusive:Bool):ObjRange {
        return null;
    }

    public function numToString(value:Float):Value {
        return null;
    }


    public function pushRoot(obj:Obj) {
        
    }

    public function popRoot() {
        
    }

    /**
     * Creates a new string containing the UTF-8 encoding of [value].
     * @param value 
     */
    public function stringFromCodePoint(value:Int) {
        
    }

    /**
     * Creates a new string containing the code point in [string] starting at byte
     * index]. If [index] points into the middle of a UTF-8 sequence, returns an
     * empty string.
     * @param string 
     * @param index 
     */
    public function stringCodePointAt(string:ObjString, index:Int):Value {
        return null;
    }

    /**
     * Creates a new string object by taking a range of characters from [source].
     * The range starts at [start], contains [count] bytes, and increments by
     * [step].
     * @param string 
     * @param start 
     * @param count 
     * @param step 
     * @return Value
     */
    public function newStringFromRange(string:ObjString, start:Int, count:Int, step:Int):Value {
        return null;
    }

 
    /**
     * Creates a new module.
     * @param name 
     * @return ObjModule
     */
    public function newModule(name:ObjString):ObjModule {
        return null;
    }

    /**
     * Creates a new Map
     */
    public function newMap():ObjMap {
        return null;
    }

    /**
     * Associates [key] with [value] in [map].
     * @param map 
     * @param key 
     * @param value 
     */
    public function mapSet(map:ObjMap, key:Value, value:Value) {
        
    }

    /**
     * Looks up [key] in [map]. If found, returns the value. Otherwise, returns
     * `UNDEFINED_VAL`.
     * @param map 
     * @param key 
     */
    public function mapGet(map:ObjMap, key:Value):Value {
        return null;
    }

    /**
     * Validates that [arg] is a valid object for use as a map key. Returns true if
     * it is. If not, reports an error and returns false.
     * @param arg 
     * @return Bool
     */
    public function validateKey(arg:Value):Bool {
        return false;
    }

    /**
     * Creates either the Object or Class class in the core module with [name].
     * @param module 
     * @param name 
     * @return ObjClass
     */
    public function defineClass(module:ObjModule, name:String):ObjClass {
        return null;
    }

    /**
     * Makes [superclass] the superclass of [subclass], and causes subclass to
     * inherit its methods. This should be called before any methods are defined
     * on subclass.
     * @param subclass 
     * @param superclass 
     */
    public function bindSuperClass(subclass:ObjClass, superclass:ObjClass){}

    public function interpret(module:String, source:String) {
        
    }
}