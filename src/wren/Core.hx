package wren;

import wren.Buffer.SymbolTable;
import wren.Macros.*;
import haxe.io.Bytes;
import wren.ObjType;

using wren.FiberTools;
using be.Constant;
using wren.Tools;
using StringTools;

@:build(wren.Macros.BuildPrimitives())
class Core {
	var vm:VM;

	static final coreModuleSource = "class Bool {}\n"
		+ "class Fiber {}\n"
		+ "class Fn {}\n"
		+ "class Null {}\n"
		+ "class Num {}\n"
		+ "\n"
		+ "class Sequence {\n"
		+ "  all(f) {\n"
		+ "    var result = true\n"
		+ "    for (element in this) {\n"
		+ "      result = f.call(element)\n"
		+ "      if (!result) return result\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  any(f) {\n"
		+ "    var result = false\n"
		+ "    for (element in this) {\n"
		+ "      result = f.call(element)\n"
		+ "      if (result) return result\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  contains(element) {\n"
		+ "    for (item in this) {\n"
		+ "      if (element == item) return true\n"
		+ "    }\n"
		+ "    return false\n"
		+ "  }\n"
		+ "\n"
		+ "  count {\n"
		+ "    var result = 0\n"
		+ "    for (element in this) {\n"
		+ "      result = result + 1\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  count(f) {\n"
		+ "    var result = 0\n"
		+ "    for (element in this) {\n"
		+ "      if (f.call(element)) result = result + 1\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  each(f) {\n"
		+ "    for (element in this) {\n"
		+ "      f.call(element)\n"
		+ "    }\n"
		+ "  }\n"
		+ "\n"
		+ "  isEmpty { iterate(null) ? false : true }\n"
		+ "\n"
		+ "  map(transformation) { MapSequence.new(this, transformation) }\n"
		+ "\n"
		+ "  skip(count) {\n"
		+ "    if (!(count is Num) || !count.isInteger || count < 0) {\n"
		+ "      Fiber.abort(\"Count must be a non-negative integer.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    return SkipSequence.new(this, count)\n"
		+ "  }\n"
		+ "\n"
		+ "  take(count) {\n"
		+ "    if (!(count is Num) || !count.isInteger || count < 0) {\n"
		+ "      Fiber.abort(\"Count must be a non-negative integer.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    return TakeSequence.new(this, count)\n"
		+ "  }\n"
		+ "\n"
		+ "  where(predicate) { WhereSequence.new(this, predicate) }\n"
		+ "\n"
		+ "  reduce(acc, f) {\n"
		+ "    for (element in this) {\n"
		+ "      acc = f.call(acc, element)\n"
		+ "    }\n"
		+ "    return acc\n"
		+ "  }\n"
		+ "\n"
		+ "  reduce(f) {\n"
		+ "    var iter = iterate(null)\n"
		+ "    if (!iter) Fiber.abort(\"Can't reduce an empty sequence.\")\n"
		+ "\n"
		+ "    // Seed with the first element.\n"
		+ "    var result = iteratorValue(iter)\n"
		+ "    while (iter = iterate(iter)) {\n"
		+ "      result = f.call(result, iteratorValue(iter))\n"
		+ "    }\n"
		+ "\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  join() { join(\"\") }\n"
		+ "\n"
		+ "  join(sep) {\n"
		+ "    var first = true\n"
		+ "    var result = \"\"\n"
		+ "\n"
		+ "    for (element in this) {\n"
		+ "      if (!first) result = result + sep\n"
		+ "      first = false\n"
		+ "      result = result + element.toString\n"
		+ "    }\n"
		+ "\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  toList {\n"
		+ "    var result = List.new()\n"
		+ "    for (element in this) {\n"
		+ "      result.add(element)\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "}\n"
		+ "\n"
		+ "class MapSequence is Sequence {\n"
		+ "  construct new(sequence, fn) {\n"
		+ "    _sequence = sequence\n"
		+ "    _fn = fn\n"
		+ "  }\n"
		+ "\n"
		+ "  iterate(iterator) { _sequence.iterate(iterator) }\n"
		+ "  iteratorValue(iterator) { _fn.call(_sequence.iteratorValue(iterator)) }\n"
		+ "}\n"
		+ "\n"
		+ "class SkipSequence is Sequence {\n"
		+ "  construct new(sequence, count) {\n"
		+ "    _sequence = sequence\n"
		+ "    _count = count\n"
		+ "  }\n"
		+ "\n"
		+ "  iterate(iterator) {\n"
		+ "    if (iterator) {\n"
		+ "      return _sequence.iterate(iterator)\n"
		+ "    } else {\n"
		+ "      iterator = _sequence.iterate(iterator)\n"
		+ "      var count = _count\n"
		+ "      while (count > 0 && iterator) {\n"
		+ "        iterator = _sequence.iterate(iterator)\n"
		+ "        count = count - 1\n"
		+ "      }\n"
		+ "      return iterator\n"
		+ "    }\n"
		+ "  }\n"
		+ "\n"
		+ "  iteratorValue(iterator) { _sequence.iteratorValue(iterator) }\n"
		+ "}\n"
		+ "\n"
		+ "class TakeSequence is Sequence {\n"
		+ "  construct new(sequence, count) {\n"
		+ "    _sequence = sequence\n"
		+ "    _count = count\n"
		+ "  }\n"
		+ "\n"
		+ "  iterate(iterator) {\n"
		+ "    if (!iterator) _taken = 1 else _taken = _taken + 1\n"
		+ "    return _taken > _count ? null : _sequence.iterate(iterator)\n"
		+ "  }\n"
		+ "\n"
		+ "  iteratorValue(iterator) { _sequence.iteratorValue(iterator) }\n"
		+ "}\n"
		+ "\n"
		+ "class WhereSequence is Sequence {\n"
		+ "  construct new(sequence, fn) {\n"
		+ "    _sequence = sequence\n"
		+ "    _fn = fn\n"
		+ "  }\n"
		+ "\n"
		+ "  iterate(iterator) {\n"
		+ "    while (iterator = _sequence.iterate(iterator)) {\n"
		+ "      if (_fn.call(_sequence.iteratorValue(iterator))) break\n"
		+ "    }\n"
		+ "    return iterator\n"
		+ "  }\n"
		+ "\n"
		+ "  iteratorValue(iterator) { _sequence.iteratorValue(iterator) }\n"
		+ "}\n"
		+ "\n"
		+ "class String is Sequence {\n"
		+ "  bytes { StringByteSequence.new(this) }\n"
		+ "  codePoints { StringCodePointSequence.new(this) }\n"
		+ "\n"
		+ "  split(delimiter) {\n"
		+ "    if (!(delimiter is String) || delimiter.isEmpty) {\n"
		+ "      Fiber.abort(\"Delimiter must be a non-empty string.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    var result = []\n"
		+ "\n"
		+ "    var last = 0\n"
		+ "    var index = 0\n"
		+ "\n"
		+ "    var delimSize = delimiter.byteCount_\n"
		+ "    var size = byteCount_\n"
		+ "\n"
		+ "    while (last < size && (index = indexOf(delimiter, last)) != -1) {\n"
		+ "      result.add(this[last...index])\n"
		+ "      last = index + delimSize\n"
		+ "    }\n"
		+ "\n"
		+ "    if (last < size) {\n"
		+ "      result.add(this[last..-1])\n"
		+ "    } else {\n"
		+ "      result.add(\"\")\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  replace(from, to) {\n"
		+ "    if (!(from is String) || from.isEmpty) {\n"
		+ "      Fiber.abort(\"From must be a non-empty string.\")\n"
		+ "    } else if (!(to is String)) {\n"
		+ "      Fiber.abort(\"To must be a string.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    var result = \"\"\n"
		+ "\n"
		+ "    var last = 0\n"
		+ "    var index = 0\n"
		+ "\n"
		+ "    var fromSize = from.byteCount_\n"
		+ "    var size = byteCount_\n"
		+ "\n"
		+ "    while (last < size && (index = indexOf(from, last)) != -1) {\n"
		+ "      result = result + this[last...index] + to\n"
		+ "      last = index + fromSize\n"
		+ "    }\n"
		+ "\n"
		+ "    if (last < size) result = result + this[last..-1]\n"
		+ "\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  trim() { trim_(\"\t\r\n \", true, true) }\n"
		+ "  trim(chars) { trim_(chars, true, true) }\n"
		+ "  trimEnd() { trim_(\"\t\r\n \", false, true) }\n"
		+ "  trimEnd(chars) { trim_(chars, false, true) }\n"
		+ "  trimStart() { trim_(\"\t\r\n \", true, false) }\n"
		+ "  trimStart(chars) { trim_(chars, true, false) }\n"
		+ "\n"
		+ "  trim_(chars, trimStart, trimEnd) {\n"
		+ "    if (!(chars is String)) {\n"
		+ "      Fiber.abort(\"Characters must be a string.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    var codePoints = chars.codePoints.toList\n"
		+ "\n"
		+ "    var start\n"
		+ "    if (trimStart) {\n"
		+ "      while (start = iterate(start)) {\n"
		+ "        if (!codePoints.contains(codePointAt_(start))) break\n"
		+ "      }\n"
		+ "\n"
		+ "      if (start == false) return \"\"\n"
		+ "    } else {\n"
		+ "      start = 0\n"
		+ "    }\n"
		+ "\n"
		+ "    var end\n"
		+ "    if (trimEnd) {\n"
		+ "      end = byteCount_ - 1\n"
		+ "      while (end >= start) {\n"
		+ "        var codePoint = codePointAt_(end)\n"
		+ "        if (codePoint != -1 && !codePoints.contains(codePoint)) break\n"
		+ "        end = end - 1\n"
		+ "      }\n"
		+ "\n"
		+ "      if (end < start) return \"\"\n"
		+ "    } else {\n"
		+ "      end = -1\n"
		+ "    }\n"
		+ "\n"
		+ "    return this[start..end]\n"
		+ "  }\n"
		+ "\n"
		+ "  *(count) {\n"
		+ "    if (!(count is Num) || !count.isInteger || count < 0) {\n"
		+ "      Fiber.abort(\"Count must be a non-negative integer.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    var result = \"\"\n"
		+ "    for (i in 0...count) {\n"
		+ "      result = result + this\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "}\n"
		+ "\n"
		+ "class StringByteSequence is Sequence {\n"
		+ "  construct new(string) {\n"
		+ "    _string = string\n"
		+ "  }\n"
		+ "\n"
		+ "  [index] { _string.byteAt_(index) }\n"
		+ "  iterate(iterator) { _string.iterateByte_(iterator) }\n"
		+ "  iteratorValue(iterator) { _string.byteAt_(iterator) }\n"
		+ "\n"
		+ "  count { _string.byteCount_ }\n"
		+ "}\n"
		+ "\n"
		+ "class StringCodePointSequence is Sequence {\n"
		+ "  construct new(string) {\n"
		+ "    _string = string\n"
		+ "  }\n"
		+ "\n"
		+ "  [index] { _string.codePointAt_(index) }\n"
		+ "  iterate(iterator) { _string.iterate(iterator) }\n"
		+ "  iteratorValue(iterator) { _string.codePointAt_(iterator) }\n"
		+ "\n"
		+ "  count { _string.count }\n"
		+ "}\n"
		+ "\n"
		+ "class List is Sequence {\n"
		+ "  addAll(other) {\n"
		+ "    for (element in other) {\n"
		+ "      add(element)\n"
		+ "    }\n"
		+ "    return other\n"
		+ "  }\n"
		+ "\n"
		+ "  toString { \"[%(join(\", \"))]\" }\n"
		+ "\n"
		+ "  +(other) {\n"
		+ "    var result = this[0..-1]\n"
		+ "    for (element in other) {\n"
		+ "      result.add(element)\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "\n"
		+ "  *(count) {\n"
		+ "    if (!(count is Num) || !count.isInteger || count < 0) {\n"
		+ "      Fiber.abort(\"Count must be a non-negative integer.\")\n"
		+ "    }\n"
		+ "\n"
		+ "    var result = []\n"
		+ "    for (i in 0...count) {\n"
		+ "      result.addAll(this)\n"
		+ "    }\n"
		+ "    return result\n"
		+ "  }\n"
		+ "}\n"
		+ "\n"
		+ "class Map is Sequence {\n"
		+ "  keys { MapKeySequence.new(this) }\n"
		+ "  values { MapValueSequence.new(this) }\n"
		+ "\n"
		+ "  toString {\n"
		+ "    var first = true\n"
		+ "    var result = \"{\"\n"
		+ "\n"
		+ "    for (key in keys) {\n"
		+ "      if (!first) result = result + \", \"\n"
		+ "      first = false\n"
		+ "      result = result + \"%(key): %(this[key])\"\n"
		+ "    }\n"
		+ "\n"
		+ "    return result + \"}\"\n"
		+ "  }\n"
		+ "\n"
		+ "  iteratorValue(iterator) {\n"
		+ "    return MapEntry.new(\n"
		+ "        keyIteratorValue_(iterator),\n"
		+ "        valueIteratorValue_(iterator))\n"
		+ "  }\n"
		+ "}\n"
		+ "\n"
		+ "class MapEntry {\n"
		+ "  construct new(key, value) {\n"
		+ "    _key = key\n"
		+ "    _value = value\n"
		+ "  }\n"
		+ "\n"
		+ "  key { _key }\n"
		+ "  value { _value }\n"
		+ "\n"
		+ "  toString { \"%(_key):%(_value)\" }\n"
		+ "}\n"
		+ "\n"
		+ "class MapKeySequence is Sequence {\n"
		+ "  construct new(map) {\n"
		+ "    _map = map\n"
		+ "  }\n"
		+ "\n"
		+ "  iterate(n) { _map.iterate(n) }\n"
		+ "  iteratorValue(iterator) { _map.keyIteratorValue_(iterator) }\n"
		+ "}\n"
		+ "\n"
		+ "class MapValueSequence is Sequence {\n"
		+ "  construct new(map) {\n"
		+ "    _map = map\n"
		+ "  }\n"
		+ "\n"
		+ "  iterate(n) { _map.iterate(n) }\n"
		+ "  iteratorValue(iterator) { _map.valueIteratorValue_(iterator) }\n"
		+ "}\n"
		+ "\n"
		+ "class Range is Sequence {}\n"
		+ "\n"
		+ "class System {\n"
		+ "  static print() {\n"
		+ "    writeString_(\"\n\")\n"
		+ "  }\n"
		+ "\n"
		+ "  static print(obj) {\n"
		+ "    writeObject_(obj)\n"
		+ "    writeString_(\"\n\")\n"
		+ "    return obj\n"
		+ "  }\n"
		+ "\n"
		+ "  static printAll(sequence) {\n"
		+ "    for (object in sequence) writeObject_(object)\n"
		+ "    writeString_(\"\n\")\n"
		+ "  }\n"
		+ "\n"
		+ "  static write(obj) {\n"
		+ "    writeObject_(obj)\n"
		+ "    return obj\n"
		+ "  }\n"
		+ "\n"
		+ "  static writeAll(sequence) {\n"
		+ "    for (object in sequence) writeObject_(object)\n"
		+ "  }\n"
		+ "\n"
		+ "  static writeObject_(obj) {\n"
		+ "    var string = obj.toString\n"
		+ "    if (string is String) {\n"
		+ "      writeString_(string)\n"
		+ "    } else {\n"
		+ "      writeString_(\"[invalid toString]\")\n"
		+ "    }\n"
		+ "  }\n"
		+ "}\n";

	public function new(vm:VM) {
		this.vm = vm;

		var coreModule = vm.newModule(null);
		vm.pushRoot(cast coreModule);

		// The core module's key is null in the module map.
		vm.mapSet(vm.modules, {type: VAL_NULL, as: null}, OBJ_VAL(coreModule));
		vm.popRoot(); // coreModule.

		// Define the root Object class. This has to be done a little specially
		// because it has no superclass.
		vm.objectClass = vm.defineClass(coreModule, "Object");
		PRIMITIVE(vm.objectClass, "!", object_not);
		PRIMITIVE(vm.objectClass, "==(_)", object_eqeq);
		PRIMITIVE(vm.objectClass, "!=(_)", object_bangeq);
		PRIMITIVE(vm.objectClass, "is(_)", object_is);
		PRIMITIVE(vm.objectClass, "toString", object_toString);
		PRIMITIVE(vm.objectClass, "type", object_type);

		// Now we can define Class, which is a subclass of Object.
		vm.classClass = vm.defineClass(coreModule, "Class");
		vm.bindSuperclass(vm.classClass, vm.objectClass);
		PRIMITIVE(vm.classClass, "name", class_name);
		PRIMITIVE(vm.classClass, "supertype", class_supertype);
		PRIMITIVE(vm.classClass, "toString", class_toString);

		// Finally, we can define Object's metaclass which is a subclass of Class.
		var objectMetaclass = vm.defineClass(coreModule, "Object metaclass");

		// Wire up the metaclass relationships now that all three classes are built.
		vm.objectClass.obj.classObj = objectMetaclass;
		objectMetaclass.obj.classObj = vm.classClass;
		vm.classClass.obj.classObj = vm.classClass;

		// Do this after wiring up the metaclasses so objectMetaclass doesn't get collected.
		vm.BindSuperclass(objectMetaclass, vm.classClass);

		PRIMITIVE(objectMetaclass, "same(_,_)", object_same);

		// The core class diagram ends up looking like this, where single lines point
		// to a class's superclass, and double lines point to its metaclass:
		//
		//        .------------------------------------. .====.
		//        |                  .---------------. | #    #
		//        v                  |               v | v    #
		//   .---------.   .-------------------.   .-------.  #
		//   | Object  |==>| Object metaclass  |==>| Class |=="
		//   '---------'   '-------------------'   '-------'
		//        ^                                 ^ ^ ^ ^
		//        |                  .--------------' # | #
		//        |                  |                # | #
		//   .---------.   .-------------------.      # | # -.
		//   |  Base   |==>|  Base metaclass   |======" | #  |
		//   '---------'   '-------------------'        | #  |
		//        ^                                     | #  |
		//        |                  .------------------' #  | Example classes
		//        |                  |                    #  |
		//   .---------.   .-------------------.          #  |
		//   | Derived |==>| Derived metaclass |=========="  |
		//   '---------'   '-------------------'            -'

		// The rest of the classes can now be defined normally.
		vm.interpret(null, coreModuleSource);
		vm.boolClass = AS_CLASS(vm.findVariable(coreModule, "Bool"));
		PRIMITIVE(vm.boolClass, "toString", bool_toString);
		PRIMITIVE(vm.boolClass, "!", bool_not);

		vm.fiberClass = AS_CLASS(wrenFindVariable(vm, coreModule, "Fiber"));
		PRIMITIVE(vm.fiberClass.obj.classObj, "new(_)", fiber_new);
		PRIMITIVE(vm.fiberClass.obj.classObj, "abort(_)", fiber_abort);
		PRIMITIVE(vm.fiberClass.obj.classObj, "current", fiber_current);
		PRIMITIVE(vm.fiberClass.obj.classObj, "suspend()", fiber_suspend);
		PRIMITIVE(vm.fiberClass.obj.classObj, "yield()", fiber_yield);
		PRIMITIVE(vm.fiberClass.obj.classObj, "yield(_)", fiber_yield1);
		PRIMITIVE(vm.fiberClass, "call()", fiber_call);
		PRIMITIVE(vm.fiberClass, "call(_)", fiber_call1);
		PRIMITIVE(vm.fiberClass, "error", fiber_error);
		PRIMITIVE(vm.fiberClass, "isDone", fiber_isDone);
		PRIMITIVE(vm.fiberClass, "transfer()", fiber_transfer);
		PRIMITIVE(vm.fiberClass, "transfer(_)", fiber_transfer1);
		PRIMITIVE(vm.fiberClass, "transferError(_)", fiber_transferError);
		PRIMITIVE(vm.fiberClass, "try()", fiber_try);

		vm.fnClass = AS_CLASS(vm.findVariable(coreModule, "Fn"));
		PRIMITIVE(vm.fnClass.obj.classObj, "new(_)", fn_new);
		PRIMITIVE(vm.fnClass, "arity", fn_arity);
		PRIMITIVE(vm.fnClass, "call()", fn_call0);
		PRIMITIVE(vm.fnClass, "call(_)", fn_call1);
		PRIMITIVE(vm.fnClass, "call(_,_)", fn_call2);
		PRIMITIVE(vm.fnClass, "call(_,_,_)", fn_call3);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_)", fn_call4);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_)", fn_call5);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_)", fn_call6);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_)", fn_call7);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_)", fn_call8);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_)", fn_call9);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_)", fn_call10);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_,_)", fn_call11);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_,_,_)", fn_call12);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_,_,_,_)", fn_call13);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_,_,_,_,_)", fn_call14);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)", fn_call15);
		PRIMITIVE(vm.fnClass, "call(_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_)", fn_call16);
		PRIMITIVE(vm.fnClass, "toString", fn_toString);

		vm.nullClass = AS_CLASS(vm.findVariable(coreModule, "Null"));
		PRIMITIVE(vm.nullClass, "!", null_not);
		PRIMITIVE(vm.nullClass, "toString", null_toString);

		vm.numClass = AS_CLASS(vm.findVariable(coreModule, "Num"));
		PRIMITIVE(vm.numClass.obj.classObj, "fromString(_)", num_fromString);
		PRIMITIVE(vm.numClass.obj.classObj, "pi", num_pi);
		PRIMITIVE(vm.numClass.obj.classObj, "largest", num_largest);
		PRIMITIVE(vm.numClass.obj.classObj, "smallest", num_smallest);
		PRIMITIVE(vm.numClass, "-(_)", num_minus);
		PRIMITIVE(vm.numClass, "+(_)", num_plus);
		PRIMITIVE(vm.numClass, "*(_)", num_multiply);
		PRIMITIVE(vm.numClass, "/(_)", num_divide);
		PRIMITIVE(vm.numClass, "<(_)", num_lt);
		PRIMITIVE(vm.numClass, ">(_)", num_gt);
		PRIMITIVE(vm.numClass, "<=(_)", num_lte);
		PRIMITIVE(vm.numClass, ">=(_)", num_gte);
		PRIMITIVE(vm.numClass, "&(_)", num_bitwiseAnd);
		PRIMITIVE(vm.numClass, "|(_)", num_bitwiseOr);
		PRIMITIVE(vm.numClass, "^(_)", num_bitwiseXor);
		PRIMITIVE(vm.numClass, "<<(_)", num_bitwiseLeftShift);
		PRIMITIVE(vm.numClass, ">>(_)", num_bitwiseRightShift);
		PRIMITIVE(vm.numClass, "abs", num_abs);
		PRIMITIVE(vm.numClass, "acos", num_acos);
		PRIMITIVE(vm.numClass, "asin", num_asin);
		PRIMITIVE(vm.numClass, "atan", num_atan);
		PRIMITIVE(vm.numClass, "ceil", num_ceil);
		PRIMITIVE(vm.numClass, "cos", num_cos);
		PRIMITIVE(vm.numClass, "floor", num_floor);
		PRIMITIVE(vm.numClass, "-", num_negate);
		PRIMITIVE(vm.numClass, "round", num_round);
		PRIMITIVE(vm.numClass, "sin", num_sin);
		PRIMITIVE(vm.numClass, "sqrt", num_sqrt);
		PRIMITIVE(vm.numClass, "tan", num_tan);
		PRIMITIVE(vm.numClass, "log", num_log);
		PRIMITIVE(vm.numClass, "%(_)", num_mod);
		PRIMITIVE(vm.numClass, "~", num_bitwiseNot);
		PRIMITIVE(vm.numClass, "..(_)", num_dotDot);
		PRIMITIVE(vm.numClass, "...(_)", num_dotDotDot);
		PRIMITIVE(vm.numClass, "atan(_)", num_atan2);
		PRIMITIVE(vm.numClass, "pow(_)", num_pow);
		PRIMITIVE(vm.numClass, "fraction", num_fraction);
		PRIMITIVE(vm.numClass, "isInfinity", num_isInfinity);
		PRIMITIVE(vm.numClass, "isInteger", num_isInteger);
		PRIMITIVE(vm.numClass, "isNan", num_isNan);
		PRIMITIVE(vm.numClass, "sign", num_sign);
		PRIMITIVE(vm.numClass, "toString", num_toString);
		PRIMITIVE(vm.numClass, "truncate", num_truncate);

		// These are defined just so that 0 and -0 are equal, which is specified by
		// IEEE 754 even though they have different bit representations.
		PRIMITIVE(vm.numClass, "==(_)", num_eqeq);
		PRIMITIVE(vm.numClass, "!=(_)", num_bangeq);

		vm.stringClass = AS_CLASS(vm.findVariable(coreModule, "String"));
		PRIMITIVE(vm.stringClass.obj.classObj, "fromCodePoint(_)", string_fromCodePoint);
		PRIMITIVE(vm.stringClass.obj.classObj, "fromByte(_)", string_fromByte);
		PRIMITIVE(vm.stringClass, "+(_)", string_plus);
		PRIMITIVE(vm.stringClass, "[_]", string_subscript);
		PRIMITIVE(vm.stringClass, "byteAt_(_)", string_byteAt);
		PRIMITIVE(vm.stringClass, "byteCount_", string_byteCount);
		PRIMITIVE(vm.stringClass, "codePointAt_(_)", string_codePointAt);
		PRIMITIVE(vm.stringClass, "contains(_)", string_contains);
		PRIMITIVE(vm.stringClass, "endsWith(_)", string_endsWith);
		PRIMITIVE(vm.stringClass, "indexOf(_)", string_indexOf1);
		PRIMITIVE(vm.stringClass, "indexOf(_,_)", string_indexOf2);
		PRIMITIVE(vm.stringClass, "iterate(_)", string_iterate);
		PRIMITIVE(vm.stringClass, "iterateByte_(_)", string_iterateByte);
		PRIMITIVE(vm.stringClass, "iteratorValue(_)", string_iteratorValue);
		PRIMITIVE(vm.stringClass, "startsWith(_)", string_startsWith);
		PRIMITIVE(vm.stringClass, "toString", string_toString);

		vm.listClass = AS_CLASS(vm.findVariable(coreModule, "List"));
		PRIMITIVE(vm.listClass.obj.classObj, "filled(_,_)", list_filled);
		PRIMITIVE(vm.listClass.obj.classObj, "new()", list_new);
		PRIMITIVE(vm.listClass, "[_]", list_subscript);
		PRIMITIVE(vm.listClass, "[_]=(_)", list_subscriptSetter);
		PRIMITIVE(vm.listClass, "add(_)", list_add);
		PRIMITIVE(vm.listClass, "addCore_(_)", list_addCore);
		PRIMITIVE(vm.listClass, "clear()", list_clear);
		PRIMITIVE(vm.listClass, "count", list_count);
		PRIMITIVE(vm.listClass, "insert(_,_)", list_insert);
		PRIMITIVE(vm.listClass, "iterate(_)", list_iterate);
		PRIMITIVE(vm.listClass, "iteratorValue(_)", list_iteratorValue);
		PRIMITIVE(vm.listClass, "removeAt(_)", list_removeAt);

		vm.mapClass = AS_CLASS(vm.findVariable(coreModule, "Map"));
		PRIMITIVE(vm.mapClass.obj.classObj, "new()", map_new);
		PRIMITIVE(vm.mapClass, "[_]", map_subscript);
		PRIMITIVE(vm.mapClass, "[_]=(_)", map_subscriptSetter);
		PRIMITIVE(vm.mapClass, "addCore_(_,_)", map_addCore);
		PRIMITIVE(vm.mapClass, "clear()", map_clear);
		PRIMITIVE(vm.mapClass, "containsKey(_)", map_containsKey);
		PRIMITIVE(vm.mapClass, "count", map_count);
		PRIMITIVE(vm.mapClass, "remove(_)", map_remove);
		PRIMITIVE(vm.mapClass, "iterate(_)", map_iterate);
		PRIMITIVE(vm.mapClass, "keyIteratorValue_(_)", map_keyIteratorValue);
		PRIMITIVE(vm.mapClass, "valueIteratorValue_(_)", map_valueIteratorValue);

		vm.rangeClass = AS_CLASS(vm.findVariable(coreModule, "Range"));
		PRIMITIVE(vm.rangeClass, "from", range_from);
		PRIMITIVE(vm.rangeClass, "to", range_to);
		PRIMITIVE(vm.rangeClass, "min", range_min);
		PRIMITIVE(vm.rangeClass, "max", range_max);
		PRIMITIVE(vm.rangeClass, "isInclusive", range_isInclusive);
		PRIMITIVE(vm.rangeClass, "iterate(_)", range_iterate);
		PRIMITIVE(vm.rangeClass, "iteratorValue(_)", range_iteratorValue);
		PRIMITIVE(vm.rangeClass, "toString", range_toString);

		var systemClass:ObjClass = AS_CLASS(vm.findVariable(coreModule, "System"));
		PRIMITIVE(systemClass.obj.classObj, "clock", system_clock);
		PRIMITIVE(systemClass.obj.classObj, "gc()", system_gc);
		PRIMITIVE(systemClass.obj.classObj, "writeString_(_)", system_writeString);

		var obj = vm.first;
		while (obj != null) {
			if (obj.type == OBJ_STRING)
				obj.classObj = vm.stringClass;
			obj = vm.next;
		}
	}

	@:DEF_PRIMITIVE("bool_not")
	static function bool_not(vm:VM, args:Array<Value>):Bool {
		RETURN_BOOL(!AS_BOOL(args[0]));
		return false;
	}

	@:DEF_PRIMITIVE("bool_toString")
	static function bool_toString(vm:VM, args:Array<Value>):Bool {
		if (AS_BOOL(args[0])) {
			RETURN_VAL(CONST_STRING(vm, "true"));
		} else {
			RETURN_VAL(CONST_STRING(vm, "false"));
		}
		return false;
	}

	@:DEF_PRIMITIVE("class_name")
	static function class_name(vm:VM, args:Array<Value>):Bool {
		RETURN_OBJ(AS_CLASS(args[0]).name);
		return false;
	}

	@:DEF_PRIMITIVE("class_supertype")
	static function class_supertype(vm:VM, args:Array<Value>):Bool {
		var classObj:ObjClass = AS_CLASS(args[0]);
		// Object has no superclass.
		if (classObj.superclass == null)
			RETURN_VAL({type: NULL_VAL, as: null});

		RETURN_OBJ(classObj.superclass);
		return false;
	}

	@:DEF_PRIMITIVE("class_toString")
	static function class_toString(vm:VM, args:Array<Value>):Bool {
		RETURN_OBJ(AS_CLASS(args[0]).name);
		return false;
	}

	@:DEF_PRIMITIVE("fiber_new")
	static function fiber_new(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateFn(args[1], "Argument"))
			return false;
		var closure:ObjClosure = AS_CLOSURE(args[1]);
		if (closure.fn.arity > 1) {
			RETURN_ERROR("Function cannot take more than one parameter.");
		}

		RETURN_OBJ(vm.newFiber(closure));
	}

	@:DEF_PRIMITIVE("fiber_abort")
	static function fiber_abort(vm:VM, args:Array<Value>) {
		vm.fiber.error = args[1];
		// If the error is explicitly null, it's not really an abort.
		return args[1].isNull();
	}

	/**
	 * Transfer execution to [fiber] coming from the current fiber whose stack has
	 * [args].
	 *
	 * [isCall] is true if [fiber] is being called and not transferred.
	 *
	 * [hasValue] is true if a value in [args] is being passed to the new fiber.
	 * Otherwise, `null` is implicitly being passed.
	 * @param vm
	 * @param fiber
	 * @param args
	 * @param isCall
	 * @param hasValue
	 * @param verb
	 * @return Bool
	 */
	static function runFiber(vm:VM, fiber:ObjFiber, args:Array<Value>, isCall:Bool, hasValue:Bool, verb:String):Bool {
		return false;
	}

	@:DEF_PRIMITIVE("fiber_call")
	static function fiber_call(vm:VM, args:Array<Value>):Bool {
		return runFiber(vm, AS_FIBER(args[0]), args, true, false, "call");
	}

	@:DEF_PRIMITIVE("fiber_call1")
	static function fiber_call1(vm:VM, args:Array<Value>):Bool {
		return runFiber(vm, AS_FIBER(args[0]), args, true, true, "call");
	}

	@:DEF_PRIMITIVE("fiber_current")
	static function fiber_current(vm:VM, args:Array<Value>):Bool {
		RETURN_OBJ(vm.fiber);
		return false;
	}

	@:DEF_PRIMITIVE("fiber_error")
	static function fiber_error(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL(AS_FIBER(args[0]).error);
		return false;
	}

	@:DEF_PRIMITIVE("fiber_isDone")
	static function fiber_isDone(vm:VM, args:Array<Value>):Bool {
		var runFiber = AS_FIBER(args[0]);
		RETURN_BOOL(runFiber.numFrames == 0 || runFiber.hasError());
	}

	@:DEF_PRIMITIVE("fiber_suspend")
	static function fiber_suspend(vm:VM, args:Array<Value>):Bool {
		// Switching to a null fiber tells the interpreter to stop and exit.
		vm.fiber = null;
		vm.apiStack = null;
		return false;
	}

	@:DEF_PRIMITIVE("fiber_transfer")
	static function fiber_transfer(vm:VM, args:Array<Value>):Bool {
		return runFiber(vm, AS_FIBER(args[0]), args, false, false, "transfer to");
	}

	@:DEF_PRIMITIVE("fiber_transfer1")
	static function fiber_transfer1(vm:VM, args:Array<Value>):Bool {
		return runFiber(vm, AS_FIBER(args[0]), args, false, true, "transfer to");
	}

	@:DEF_PRIMITIVE("fiber_transferError")
	static function fiber_transferError(vm:VM, args:Array<Value>):Bool {
		runFiber(vm, AS_FIBER(args[0]), args, false, true, "transfer to");
		vm.fiber.error = args[1];
		return false;
	}

	@:DEF_PRIMITIVE("fiber_try")
	static function fiber_try(vm:VM, args:Array<Value>):Bool {
		runFiber(vm, AS_FIBER(args[0]), args, true, false, "try");
		// If we're switching to a valid fiber to try, remember that we're trying it.
		if (!vm.fiber.hasError())
			vm.fiber.state = FIBER_TRY;
		return false;
	}

	@:DEF_PRIMITIVE("fiber_yield")
	static function fiber_yield(vm:VM, args:Array<Value>):Bool {
		var current = vm.fiber;
		vm.fiber = current.caller;
		// Unhook this fiber from the one that called it.
		current.caller = null;
		current.state = FIBER_OTHER;
		if (vm.fiber != null) {
			// Make the caller's run method return null.
			vm.fiber.stackTop[-1] = {type: NULL_VAL, as: null};
		}
		return false;
	}

	@:DEF_PRIMITIVE("fiber_yield1")
	static function fiber_yield1(vm:VM, args:Array<Value>):Bool {
		var current = vm.fiber;
		vm.fiber = current.caller;
		// Unhook this fiber from the one that called it.
		current.caller = null;
		current.state = FIBER_OTHER;
		if (vm.fiber != null) {
			// Make the caller's run method return null.
			vm.fiber.stackTop[-1] = args[1];
			// When the yielding fiber resumes, we'll store the result of the yield
			// call in its stack. Since Fiber.yield(value) has two arguments (the Fiber
			// class and the value) and we only need one slot for the result, discard
			// the other slot now.
			current.stackTop--;
		}
		return false;
	}

	@:DEF_PRIMITIVE("fn_new")
	static function fn_new(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateFn(args[1], "Argument"))
			return false;
		// The block argument is already a function, so just return it.
		RETURN_VAL(args[1]);
		return false;
	}

	@:DEF_PRIMITIVE("fn_arity")
	static function fn_arity(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(AS_CLOSURE(args[0]).fn.arity);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call0")
	static function fn_call0(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 0);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call1")
	static function fn_call1(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 1);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call2")
	static function fn_call2(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 2);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call3")
	static function fn_call3(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 3);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call4")
	static function fn_call4(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 4);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call5")
	static function fn_call5(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 5);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call6")
	static function fn_call6(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 6);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call7")
	static function fn_call7(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 7);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call8")
	static function fn_call8(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 8);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call9")
	static function fn_call9(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 9);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call10")
	static function fn_call10(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 10);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call11")
	static function fn_call11(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 11);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call12")
	static function fn_call12(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 12);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call13")
	static function fn_call13(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 13);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call14")
	static function fn_call14(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 14);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call15")
	static function fn_call15(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 15);
		return false;
	}

	@:DEF_PRIMITIVE("fn_call16")
	static function fn_call16(vm:VM, args:Array<Value>):Bool {
		call_fn(vm, args, 16);
		return false;
	}

	@:DEF_PRIMITIVE("fn_toString")
	static function fn_toString(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL(CONST_STRING(vm, "<fn>"));
		return false;
	}

	// Creates a new list of size args[1], with all elements initialized to args[2].

	@:DEF_PRIMITIVE("list_filled")
	static function list_filled(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateInt(args[1], "Size"))
			return false;
		if (AS_NUM(args[1]) < 0)
			RETURN_ERROR("Size cannot be negative.");

		var size:Int = AS_NUM(args[1]);
		var list:ObjList = vm.newList(size);

		for (i in 0...size) {
			list.elements.data[i] = args[2];
		}

		RETURN_OBJ(list);
		return false;
	}

	@:DEF_PRIMITIVE("list_new")
	static function list_new(vm:VM, args:Array<Value>):Bool {
		RETURN_OBJ(vm.newList(0));
		return false;
	}

	@:DEF_PRIMITIVE("list_add")
	static function list_add(vm:VM, args:Array<Value>):Bool {
		AS_LIST(args[0]).elements.write(args[1]);
		RETURN_VAL(args[1]);
		return false;
	}

	/**
	 * Adds an element to the list and then returns the list itself. This is called
	 * by the compiler when compiling list literals instead of using add() to
	 * minimize stack churn.
	 * @param vm
	 * @param args
	 * @return Bool
	 */
	@:DEF_PRIMITIVE("list_addCore")
	static function list_addCore(vm:VM, args:Array<Value>):Bool {
		AS_LIST(args[0]).elements.write(args[1]);
		RETURN_VAL(args[0]);
		return false;
	}

	@:DEF_PRIMITIVE("list_clear")
	static function list_clear(vm:VM, args:Array<Value>):Bool {
		AS_LIST(args[0]).elements.clear(args[1]);
		RETURN_VAL({type: VAL_NULL, as: null});
		return false;
	}

	@:DEF_PRIMITIVE("list_count")
	static function list_count(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(AS_LIST(args[0]).elements.count);
		return false;
	}

	@:DEF_PRIMITIVE("list_insert")
	static function list_insert(vm:VM, args:Array<Value>):Bool {
		var list = AS_LIST(args[0]);
		// count + 1 here so you can "insert" at the very end.
		var index = vm.validateIndex(args[1], list.elements.count + 1, "Index");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		vm.listInsert(list, args[2], index);
		RETURN_VAL(args[2]);
		return false;
	}

	@:DEF_PRIMITIVE("list_iterate")
	static function list_iterate(vm:VM, args:Array<Value>):Bool {
		var list = AS_LIST(args[0]);
		// If we're starting the iteration, return the first index.
		if (IS_NULL(args[1])) {
			if (list.elements.count == 0)
				RETURN_VAL({type: VAL_FALSE, as: null});
			RETURN_NUM(0);
		}

		if (!vm.validateInt(args[1], "Iterator"))
			return false;

		// Stop if we're out of bounds.
		var index = AS_NUM(args[1]);
		if (index < 0 || index >= list.elements.count - 1)
			RETURN_VAL({type: VAL_FALSE, as: null});

		// Otherwise, move to the next index.
		RETURN_NUM(index + 1);
		return false;
	}

	@:DEF_PRIMITIVE("list_iteratorValue")
	static function list_iteratorValue(vm:VM, args:Array<Value>):Bool {
		var list = AS_LIST(args[0]);
		var index = vm.validateIndex(args[1], list.elements.count, "Iterator");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		RETURN_VAL(list.elements.data[index]);
		return false;
	}

	@:DEF_PRIMITIVE("list_removeAt")
	static function list_removeAt(vm:VM, args:Array<Value>):Bool {
		var list = AS_LIST(args[0]);
		var index = vm.validateIndex(args[1], list.elements.count, "Index");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		RETURN_VAL(vm.listRemoveAt(list, index));
		return false;
	}

	@:DEF_PRIMITIVE("list_subscript")
	static function list_subscript(vm:VM, args:Array<Value>):Bool {
		var list = AS_LIST(args[0]);
		if (IS_NUM(args[1])) {
			var index = vm.validateIndex(args[1], list.elements.count, "Subscript");
			#if cpp
			if (index == untyped __cpp__('UINT32_MAX'))
				return false;
			#elseif cs
			if (index == untyped __cs__('UInt32.MaxValue'))
				return false;
			#else
			if (index == 4294967295)
				return false;
			#end
			RETURN_VAL(list.elements.data[index]);
		}

		if (!IS_RANGE(args[1])) {
			RETURN_ERROR("Subscript must be a number or a range.");
		}
		var step:Int;
		var count = list.elements.count;
		var start = vm.calculateRange(AS_RANGE(args[1]), count, step);
		#if cpp
		if (start == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (start == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (start == 4294967295)
			return false;
		#end
		var result = vm.newList(count);
		for (i in 0...count) {
			result.elements.data[i] = list.elements.data[start + i * step];
		}

		RETURN_OBJ(result);
		return false;
	}

	@:DEF_PRIMITIVE("list_subscriptSetter")
	static function list_subscriptSetter(vm:VM, args:Array<Value>):Bool {
		var list = AS_LIST(args[0]);
		var index = vm.validateIndex(args[1], list.elements.count, "Subscript");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		list.elements.data[index] = args[2];
		RETURN_VAL(args[2]);
		return false;
	}

	@:DEF_PRIMITIVE("map_new")
	static function map_new(vm:VM, args:Array<Value>) {
		RETURN_OBJ(vm.newMap());
		return false;
	}

	@:DEF_PRIMITIVE("map_subscript")
	static function map_subscript(vm:VM, args:Array<Value>) {
		if (!vm.validateKey(args[1]))
			return false;
		var map = AS_MAP(args[0]);
		var value = vm.mapGet(map, args[1]);
		if (IS_UNDEFINED(value))
			return RETURN_NULL();
		RETURN_VAL(value);
		return false;
	}

	@:DEF_PRIMITIVE("map_subscriptSetter")
	static function map_subscriptSetter(vm:VM, args:Array<Value>) {
		if (!vm.validateKey(args[1]))
			return false;
		vm.mapSet(AS_MAP(args[0]), args[1], args[2]);
		RETURN_VAL(args[2]);
		return false;
	}

	/**
	 * Adds an entry to the map and then returns the map itself. This is called by
	 * the compiler when compiling map literals instead of using [_]=(_) to
	 * minimize stack churn.
	 * @param vm
	 * @param args
	 * @return Bool
	 */
	@:DEF_PRIMITIVE("map_addCore")
	static function map_addCore(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateKey(args[1]))
			return false;

		vm.mapSet(AS_MAP(args[0]), args[1], args[2]);
		// Return the map itself.
		RETURN_VAL(args[0]);
		return false;
	}

	@:DEF_PRIMITIVE("map_clear")
	static function map_clear(vm:VM, args:Array<Value>):Bool {
		vm.mapClear(AS_MAP(args[0]));
		return RETURN_NULL();
	}

	@:DEF_PRIMITIVE("map_containsKey")
	static function map_containsKey(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateKey(args[1]))
			return false;

		RETURN_BOOL(!IS_UNDEFINED(vm.mapGet(AS_MAP(args[0]), args[1])));
		return false;
	}

	@:DEF_PRIMITIVE("map_count")
	static function map_count(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(AS_MAP(args[0]).count);
		return false;
	}

	@:DEF_PRIMITIVE("map_iterate")
	static function map_iterate(vm:VM, args:Array<Value>):Bool {
		var map = AS_MAP(args[0]);
		if (map.count == 0)
			return RETURN_FALSE();
		// If we're starting the iteration, start at the first used entry.
		var index = 0;
		// Otherwise, start one past the last entry we stopped at.
		if (!IS_NULL(args[1])) {
			if (!vm.validateInt(args[1], "Iterator"))
				return false;
			if (AS_NUM(args[1]) < 0)
				return RETURN_FALSE();
			index = AS_NUM(args[1]);

			if (index >= map.capacity)
				return RETURN_FALSE();
			// Advance the iterator.
			index++;
		}
		// Find a used entry, if any.
		while (index < map->capacity) {
			if (!IS_UNDEFINED(map.entries[index].key))
				RETURN_NUM(index);
			index++;
		}
		// If we get here, walked all of the entries.
		return RETURN_FALSE();
	}

	@:DEF_PRIMITIVE("map_remove")
	static function map_remove(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateKey(args[1]))
			return false;
		RETURN_VAL(vm.mapRemoveKey(AS_MAP(args[0]), args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("map_keyIteratorValue")
	static function map_keyIteratorValue(vm:VM, args:Array<Value>):Bool {
		var map = AS_MAP(args[0]);
		var index = vm.validateIndex(args[1], map.capacity, "Iterator");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		var entry = map.entries[index];
		if (IS_UNDEFINED(entry.key)) {
			RETURN_ERROR("Invalid map iterator.");
		}
		RETURN_VAL(entry.key);
		return false;
	}

	@:DEF_PRIMITIVE("map_valueIteratorValue")
	static function map_valueIteratorValue(vm:VM, args:Array<Value>) {
		var map = AS_MAP(args[0]);
		var index = vm.validateIndex(args[1], map.capacity, "Iterator");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		var entry = map.entries[index];
		if (IS_UNDEFINED(entry.key)) {
			RETURN_ERROR("Invalid map iterator.");
		}

		RETURN_VAL(entry.value);
	}

	@:DEF_PRIMITIVE("null_not")
	static function null_not(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL({type: VAL_NULL, as: null});
		return false;
	}

	@:DEF_PRIMITIVE("null_toString")
	static function null_toString(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL(CONST_STRING(vm, "null"));
		return false;
	}

	@:DEF_PRIMITIVE("num_pi")
	static function num_pi(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(3.14159265358979323846);
		return false;
	}

	@:DEF_PRIMITIVE("num_minus")
	static function num_minus(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_NUM(AS_NUM(args[0]) - AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_plus")
	static function num_plus(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_NUM(AS_NUM(args[0]) + AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_multiply")
	static function num_multiply(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_NUM(AS_NUM(args[0]) * AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_divide")
	static function num_divide(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_NUM(AS_NUM(args[0]) / AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_lt")
	static function num_lt(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_BOOL(AS_NUM(args[0]) < AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_gt")
	static function num_gt(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_BOOL(AS_NUM(args[0]) > AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_lte")
	static function num_lte(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_BOOL(AS_NUM(args[0]) <= AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_gte")
	static function num_gte(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_BOOL(AS_NUM(args[0]) >= AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_bitwiseAnd")
	static function num_bitwiseAnd(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		var left:Int = AS_NUM(args[0]);
		var right:Int = AS_NUM(args[1]);
		RETURN_NUM(left & right);
		return false;
	}

	@:DEF_PRIMITIVE("num_bitwiseOr")
	static function num_bitwiseOr(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		var left:Int = AS_NUM(args[0]);
		var right:Int = AS_NUM(args[1]);
		RETURN_NUM(left | right);
		return false;
	}

	@:DEF_PRIMITIVE("num_bitwiseXor")
	static function num_bitwiseXor(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		var left:Int = AS_NUM(args[0]);
		var right:Int = AS_NUM(args[1]);
		RETURN_NUM(left ^ right);
		return false;
	}

	@:DEF_PRIMITIVE("num_bitwiseLeftShift")
	static function num_bitwiseLeftShift(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		var left:Int = AS_NUM(args[0]);
		var right:Int = AS_NUM(args[1]);
		RETURN_NUM(left << right);
		return false;
	}

	@:DEF_PRIMITIVE("num_bitwiseRightShift")
	static function num_bitwiseRightShift(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		var left:Int = AS_NUM(args[0]);
		var right:Int = AS_NUM(args[1]);
		RETURN_NUM(left >> right);
		return false;
	}

	@:DEF_PRIMITIVE("num_abs")
	static function num_abs(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.abs(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_acos")
	static function num_acos(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.acos(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_asin")
	static function num_asin(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.asin(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_atan")
	static function num_atan(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.atan(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_ceil")
	static function num_ceil(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.ceil(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_cos")
	static function num_cos(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.cos(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_sin")
	static function num_sin(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.sin(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_exp")
	static function num_exp(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.exp(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_floor")
	static function num_floor(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.floor(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_negate")
	static function num_negate(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(-AS_NUM(args[0]));
		return false;
	}

	@:DEF_PRIMITIVE("num_round")
	static function num_round(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.round(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_sqrt")
	static function num_sqrt(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.sqrt(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_tan")
	static function num_tan(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.tan(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_log")
	static function num_log(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.log(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_mod")
	static function num_mod(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right operand"))
			return false;
		RETURN_NUM(AS_NUM(args[0]) % AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_eqeq")
	static function num_eqeq(vm:VM, args:Array<Value>):Bool {
		if (!IS_NUM(args[1]))
			RETURN_VAL({type: VAL_FALSE, as: null});
		RETURN_BOOL(AS_NUM(args[0]) == AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_bangeq")
	static function num_bangeq(vm:VM, args:Array<Value>):Bool {
		if (!IS_NUM(args[1]))
			RETURN_VAL({type: VAL_FALSE, as: null});
		RETURN_BOOL(AS_NUM(args[0]) != AS_NUM(args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("num_bitwiseNot")
	static function num_bitwiseNot(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(~AS_NUM(args[0]));
		return false;
	}

	@:DEF_PRIMITIVE("num_dotDot")
	static function num_dotDot(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right hand side of range"))
			return false;
		var from:Float = AS_NUM(args[0]);
		var to:Float = AS_NUM(args[1]);
		RETURN_VAL(vm.newRange(from, to, true));
		return false;
	}

	@:DEF_PRIMITIVE("num_dotDotDot")
	static function num_dotDotDot(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateNum(args[1], "Right hand side of range"))
			return false;
		var from:Float = AS_NUM(args[0]);
		var to:Float = AS_NUM(args[1]);
		RETURN_VAL(vm.newRange(from, to, false));
		return false;
	}

	@:DEF_PRIMITIVE("num_atan2")
	static function num_atan2(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.atan2(AS_NUM(args[0]), AS_NUM(args[1])));
		return false;
	}

	@:DEF_PRIMITIVE("num_pow")
	static function num_pow(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Math.pow(AS_NUM(args[0]), AS_NUM(args[1])));
		return false;
	}

	@:DEF_PRIMITIVE("num_fraction")
	static function num_fraction(vm:VM, args:Array<Value>):Bool {
		var f = AS_NUM(args[0]);
		var v = Math.ceil(((f < 1.0) ? f : (f % Math.floor(f))) * 10000);
		RETURN_NUM(v / 10000);
		return false;
	}

	@:DEF_PRIMITIVE("num_isInfinity")
	static function num_isInfinity(vm:VM, args:Array<Value>):Bool {
		var q = Math.isFinite(AS_NUM(args[0]));
		RETURN_BOOL(!q);
		return false;
	}

	@:DEF_PRIMITIVE("num_isInteger")
	static function num_isInteger(vm:VM, args:Array<Value>):Bool {
		var value = AS_NUM(args[0]);
		if (Math.isNaN(value) || !Math.isFinite(value))
			RETURN_VAL({type: VAL_FALSE, as: null});
		var trunc = value < 0 ? Math.ceil(value) : Math.floor(value);
		RETURN_BOOL(trunc == value);
		return false;
	}

	@:DEF_PRIMITIVE("num_isNan")
	static function num_isNan(vm:VM, args:Array<Value>):Bool {
		var q = Math.isNaN(AS_NUM(args[0]));
		RETURN_BOOL(q);
		return false;
	}

	@:DEF_PRIMITIVE("num_sign")
	static function num_sign(vm:VM, args:Array<Value>):Bool {
		var value = AS_NUM(args[0]);
		if (value > 0) {
			RETURN_NUM(1);
		} else if (value < 0) {
			RETURN_NUM(-1);
		} else {
			RETURN_NUM(0);
		}
		return false;
	}

	@:DEF_PRIMITIVE("num_largest")
	static function num_largest(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Ints.MAX);
		return false;
	}

	@:DEF_PRIMITIVE("num_smallest")
	static function num_smallest(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(Ints.MIN);
		return false;
	}

	@:DEF_PRIMITIVE("num_toString")
	static function num_toString(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL(vm.numToString(AS_NUM(args[0])));
		return false;
	}

	@:DEF_PRIMITIVE("num_truncate")
	static function num_truncate(vm:VM, args:Array<Value>):Bool {
		var value = AS_NUM(args[0]);
		var trunc = value < 0 ? Math.ceil(value) : Math.floor(value);
		RETURN_NUM(trunc);
		return false;
	}

	@:DEF_PRIMITIVE("object_same")
	static function object_same(vm:VM, args:Array<Value>):Bool {
		RETURN_BOOL(Value.equal(args[1], args[2]));
		return false;
	}

	@:DEF_PRIMITIVE("object_not")
	static function object_not(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL({type: VAL_FALSE, as: null});
		return false;
	}

	@:DEF_PRIMITIVE("object_eqeq")
	static function object_eqeq(vm:VM, args:Array<Value>):Bool {
		RETURN_BOOL(Value.equal(args[0], args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("object_bangeq")
	static function object_bangeq(vm:VM, args:Array<Value>):Bool {
		RETURN_BOOL(!Value.equal(args[0], args[1]));
		return false;
	}

	@:DEF_PRIMITIVE("object_is")
	static function object_is(vm:VM, args:Array<Value>):Bool {
		if (!IS_CLASS(args[1])) {
			RETURN_ERROR("Right operand must be a class.");
		}
		var classObj = vm.getClass(args[0]);
		var baseClassObj = AS_CLASS(args[1]);
		// Walk the superclass chain looking for the class.
		do {
			if (baseClassObj == classObj)
				RETURN_BOOL(true);
			classObj = classObj.superclass;
		} while (classObj != null);
		RETURN_BOOL(false);
		return false;
	}

	@:DEF_PRIMITIVE("object_toString")
	static function object_toString(vm:VM, args:Array<Value>):Bool {
		var obj = AS_OBJ(args[0]);
		var name = OBJ_VAL(obj.classObj.name);
		RETURN_VAL(vm.stringFormat("instance of @", [name]));
		return false;
	}

	@:DEF_PRIMITIVE("object_type")
	static function object_type(vm:VM, args:Array<Value>) {
		RETURN_OBJ(vm.getClass(args[0]));
		return false;
	}

	@:DEF_PRIMITIVE("range_from")
	static function range_from(vm:VM, args:Array<Value>) {
		RETURN_NUM(AS_RANGE(args[0]).from);
		return false;
	}

	@:DEF_PRIMITIVE("range_to")
	static function range_to(vm:VM, args:Array<Value>) {
		RETURN_NUM(AS_RANGE(args[0]).to);
		return false;
	}

	@:DEF_PRIMITIVE("range_min")
	static function range_min(vm:VM, args:Array<Value>) {
		var range = AS_RANGE(args[0]);
		RETURN_NUM(Math.min(range.from, range.to));
		return false;
	}

	@:DEF_PRIMITIVE("range_max")
	static function range_max(vm:VM, args:Array<Value>) {
		var range = AS_RANGE(args[0]);
		RETURN_NUM(Math.max(range.from, range.to));
		return false;
	}

	@:DEF_PRIMITIVE("range_isInclusive")
	static function range_isInclusive(vm:VM, args:Array<Value>) {
		RETURN_BOOL(AS_RANGE(args[0]).isInclusive);
		return false;
	}

	@:DEF_PRIMITIVE("range_iterate")
	static function range_iterate(vm:VM, args:Array<Value>) {
		var range = AS_RANGE(args[0]);
		// Special case: empty range.
		if (range.from == range.to && !range.isInclusive)
			return RETURN_FALSE();
		// Start the iteration.
		if (IS_NULL(args[1]))
			RETURN_NUM(range.from);
		if (!vm.validateNum(args[1], "Iterator"))
			return false;
		var iterator:Float = AS_NUM(args[1]);
		// Iterate towards [to] from [from].
		if (range.from < range.to) {
			iterator++;
			if (iterator > range.to)
				return RETURN_FALSE();
		} else {
			iterator--;
			if (iterator < range.to)
				return RETURN_FALSE();
		}
		if (!range.isInclusive && iterator == range.to)
			return RETURN_FALSE();
		RETURN_NUM(iterator);
		return false;
	}

	@:DEF_PRIMITIVE("range_iteratorValue")
	static function range_iteratorValue(vm:VM, args:Array<Value>) {
		// Assume the iterator is a number so that is the value of the range.
		RETURN_VAL(args[1]);
		return false;
	}

	@:DEF_PRIMITIVE("range_toString")
	static function range_toString() {
		var range = AS_RANGE(args[0]);
		var from = vm.numToString(range.from);
		vm.pushRoot(AS_OBJ(from));
		var to = vm.numToString(range.to);
		vm.pushRoot(AS_OBJ(to));
		var result = vm.stringFormat("@$@", [from, range.isInclusive ? ".." : "...", to]);
		vm.popRoot();
		vm.popRoot();
		RETURN_VAL(result);
		return false;
	}

	@:DEF_PRIMITIVE("string_fromCodePoint")
	static function string_fromCodePoint(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateInt(args[1], "Code point"))
			return false;
		var codePoint = Std.int(AS_NUM(args[1]));
		if (codePoint < 0) {
			RETURN_ERROR("Code point cannot be negative.");
		} else if (codePoint > 0x10ffff) {
			RETURN_ERROR("Code point cannot be greater than 0x10ffff.");
		}
		RETURN_VAL(vm.stringFromCodePoint(codePoint));
		return false;
	}

	@:DEF_PRIMITIVE("string_fromByte")
	static function string_fromByte(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateInt(args[1], "Code point"))
			return false;
		var byte = Std.int(AS_NUM(args[1]));
		if (byte < 0) {
			RETURN_ERROR("Byte cannot be negative.");
		} else if (byte > 0xff) {
			RETURN_ERROR("Byte cannot be greater than 0xff.");
		}
		RETURN_VAL(vm.stringFromByte(byte));
		return false;
	}

	@:DEF_PRIMITIVE("string_byteAt")
	static function string_byteAt(vm:VM, args:Array<Value>):Bool {
		var string = AS_STRING(args[0]);
		var index = vm.validateIndex(args[1], string.length, "Index");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end
		RETURN_NUM(string.value.charAt(index));
		return false;
	}

	static function string_byteCount(vm:VM, args:Array<Value>):Bool {
		RETURN_NUM(AS_STRING(args[0]).length);
		return false;
	}

	@:DEF_PRIMITIVE("string_codePointAt")
	static function string_codePointAt(vm:VM, args:Array<Value>):Bool {
		var string = AS_STRING(args[0]);
		var index = vm.validateIndex(args[1], string.length, "Index");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end

		// // If we are in the middle of a UTF-8 sequence, indicate that.
		// var bytes = Bytes.ofString(string.value);
		// if ((bytes.get(index) & 0xc0) == 0x80) RETURN_NUM(-1);
		// // Decode the UTF-8 sequence.

		RETURN_NUM(string.value.fastCodeAt(string.length - index));
		return false;
	}

	@:DEF_PRIMITIVE("string_contains")
	static function string_contains(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateString(args[1], "Argument"))
			return false;
		var string = AS_STRING(args[0]);
		var search = AS_STRING(args[1]);

		RETURN_BOOL(string.value.contains(search));
		return false;
	}

	@:DEF_PRIMITIVE("string_endsWith")
	static function string_endsWith(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateString(args[1], "Argument"))
			return false;
		var string = AS_STRING(args[0]);
		var search = AS_STRING(args[1]);

		RETURN_BOOL(string.value.endsWith(search));
		return false;
	}

	@:DEF_PRIMITIVE("string_indexOf1")
	static function string_indexOf1(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateString(args[1], "Argument"))
			return false;
		var string = AS_STRING(args[0]);
		var search = AS_STRING(args[1]);

		RETURN_NUM(string.value.indexOf(search));
		return false;
	}

	@:DEF_PRIMITIVE("string_indexOf2")
	static function string_indexOf2(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateString(args[1], "Argument"))
			return false;
		var string = AS_STRING(args[0]);
		var search = AS_STRING(args[1]);
		var start = vm.validateIndex(args[2], string.length, "Start");
		#if cpp
		if (start == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (start == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (start == 4294967295)
			return false;
		#end

		RETURN_NUM(string.value.indexOf(search, start));
		return false;
	}

	@:DEF_PRIMITIVE("string_iterate")
	static function string_iterate(vm:VM, args:Array<Value>):Bool {
		var string = AS_STRING(args[0]);
		// If we're starting the iteration, return the first index.
		if (IS_NULL(args[1])) {
			if (string.length == 0)
				return RETURN_FALSE();
			RETURN_NUM(0);
		}

		if (!vm.validateInt(args[1], "Iterator"))
			return false;
		if (AS_NUM(args[1]) < 0)
			return RETURN_FALSE();

		var index = AS_NUM(args[1]);

		// Advance to the beginning of the next UTF-8 sequence.
		do {
			index++;
			if (index >= string.length)
				return RETURN_FALSE();
		} while ((string.value.charAt(index) & 0xc0) == 0x80);

		RETURN_NUM(index);
		return false;
	}

	@:DEF_PRIMITIVE("string_iterateByte")
	static function string_iterateByte(vm:VM, args:Array<Value>):Bool {
		var string = AS_STRING(args[0]);
		// If we're starting the iteration, return the first index.
		if (IS_NULL(args[1])) {
			if (string.length == 0)
				return RETURN_FALSE();
			RETURN_NUM(0);
		}

		if (!vm.validateInt(args[1], "Iterator"))
			return false;
		if (AS_NUM(args[1]) < 0)
			return RETURN_FALSE();

		var index = AS_NUM(args[1]);

		// Advance to the next byte.
		index++;
		if (index >= string.length)
			return RETURN_FALSE();

		RETURN_NUM(index);
		return false;
	}

	@:DEF_PRIMITIVE("string_iteratorValue")
	static function string_iteratorValue(vm:VM, args:Array<Value>):Bool {
		var string = AS_STRING(args[0]);
		var start = vm.validateIndex(args[1], string.length, "Index");
		#if cpp
		if (index == untyped __cpp__('UINT32_MAX'))
			return false;
		#elseif cs
		if (index == untyped __cs__('UInt32.MaxValue'))
			return false;
		#else
		if (index == 4294967295)
			return false;
		#end

		RETURN_VAL(vm.stringCodePointAt(string, index));
		return false;
	}

	@:DEF_PRIMITIVE("string_startsWith")
	static function string_startsWith(vm:VM, args:Array<Value>):Bool {
		if (!vm.validateString(args[1], "Argument"))
			return false;
		var string = AS_STRING(args[0]);
		var search = AS_STRING(args[1]);

		RETURN_BOOL(string.value.startsWith(search));
		return false;
	}

	@:DEF_PRIMITIVE("string_subscript")
	static function string_subscript(vm:VM, args:Array<Value>):Bool {
		var string = AS_STRING(args[0]);
		if (IS_NUM(args[1])) {
			var index = vm.validateIndex(args[1], string.length, "Subscript");
			if (index == -1)
				return false;

			RETURN_VAL(vm.stringCodePointAt(string, index));
		}
		if (!IS_RANGE(args[1])) {
			RETURN_ERROR("Subscript must be a number or a range.");
		}

		var step:Int;
		var count = string.length;
		var start = vm.calculateRange(AS_RANGE(args[1]), count, step);
		if (start == -1)
			return false;

		RETURN_VAL(vm.newStringFromRange(string, start, count, step));
		return false;
	}

	@:DEF_PRIMITIVE("string_toString")
	static function string_toString(vm:VM, args:Array<Value>):Bool {
		RETURN_VAL(args[0]);
		return false;
	}

	static function system_clock(vm:VM, args:Array<Value>):Bool {
		var time = Sys.time();
		RETURN_NUM(time);
		return false;
	}

	@:DEF_PRIMITIVE("system_gc")
	static function system_gc(vm:VM, args:Array<Value>):Bool {
		vm.collectGarbage();
		return RETURN_NULL();
	}

	static function system_writeString(vm:VM, args:Array<Value>):Bool {
		if (vm.config.writeFn != null) {
			vm.config.writeFn(AS_STRING(args[1]).value);
		}
		RETURN_VAL(args[1]);
		return false;
	}
}
