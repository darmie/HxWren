package wren;

import haxe.macro.Expr;
import haxe.macro.Context;
import sys.FileSystem;
import haxe.io.Path;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import wren.Value;
using haxe.macro.ExprTools;

class Macros {
	/**
	 * The maximum number of module-level variables that may be defined at one time.
	 * This limitation comes from the 16 bits used for the arguments to
	 * `CODE_LOAD_MODULE_VAR` and `CODE_STORE_MODULE_VAR`.
	 */
	public static final MAX_MODULE_VARS = 65536;

	/**
	 * The maximum number of arguments that can be passed to a method. Note that
	 * this limitation is hardcoded in other places in the VM, in particular, the
	 * `CODE_CALL_XX` instructions assume a certain maximum number.
	 */
	public static final MAX_PARAMETERS = 16;

	/**
	 * The maximum name of a method, not including the signature. This is an
	 * arbitrary but enforced maximum just so we know how long the method name
	 * strings need to be in the parser.
	 */
	public static final MAX_METHOD_NAME = 64;

	/**
	 * The maximum length of a method signature. Signatures look like:
	 * ```
	 *      foo        // Getter.
	 *      foo()      // No-argument method.
	 *      foo(_)     // One-argument method.
	 *      foo(_,_)   // Two-argument method.
	 *      init foo() // Constructor initializer.
	 * ```
	 * The maximum signature length takes into account the longest method name, the
	 * maximum number of parameters with separators between them, "init ", and "()".
	 */
	public static final MAX_METHOD_SIGNATURE = (MAX_METHOD_NAME + (MAX_PARAMETERS * 2) + 6);

	/**
	 * The maximum length of an identifier. The only real reason for this limitation
	 * is so that error messages mentioning variables can be stack allocated.
	 */
	public static final MAX_VARIABLE_NAME = 64;

	/**
	 * The maximum number of fields a class can have, including inherited fields.
	 * This is explicit in the bytecode since `CODE_CLASS` and `CODE_SUBCLASS` take
	 * a single byte for the number of fields. Note that it's 255 and not 256
	 * because creating a class takes the *number* of fields, not the *highest
	 * field index*.
	 */
	public static final MAX_FIELDS = 255;

	macro static public function RETURN_VAL(value:Expr):Expr {
		var pos = Context.currentPos();
		var exp = macro $i{'args'}[0] = $value;
		var body = macro do {
			$exp;
			return true;
		} while (true);

		return body;
	}

	macro static public function RETURN_NULL():Expr {
		// var args = macro $i{Context.getLocalVars()[1]};
		var pos = Context.currentPos();
		
		return macro do {
			$i{"args"}[0] = new Value({type: VAL_NULL, as: null});
			return true;
		} while (true);
	}

	macro static public function RETURN_TRUE():Expr {
		// var args = macro $i{Context.getLocalVars()[1]};
		var pos = Context.currentPos();
		
		return macro do {
			$i{"args"}[0] = new Value({type: VAL_TRUE, as: null});
			return true;
		} while (true);
	}

	macro static public function RETURN_FALSE():Expr {
		// var args = macro $i{Context.getLocalVars()[1]};
		var pos = Context.currentPos();
		
		return macro do {
			$i{"args"}[0] = new Value({type: VAL_FALSE, as: null});
			return true;
		} while (true);
	}

	macro static public function ASSERT(condition:Expr, message:Expr):Expr {
		var s:String = condition.toString();
		var p = condition.pos;
		var el = [];
		var descs = [];
		function add(e:Expr, s:String) {
			var v = "_tmp" + el.length;
			el.push(macro var $v = $e);
			descs.push(s);
			return v;
		}
		function map(e:Expr) {
			return switch (e.expr) {
				case EConst((CInt(_) | CFloat(_) | CString(_) | CRegexp(_) | CIdent("true" | "false" | "null"))):
					e;
				case _:
					var s = e.toString();
					e = e.map(map);
					macro $i{add(e, s)};
			}
		}
		var e = map(condition);
		var a = [for (i in 0...el.length) macro {expr: $v{descs[i]}, value: $i{"_tmp" + i}}];
		el.push(macro if (!$e)
			@:pos(p) throw new Assert.AssertionFailure($message, $a{a}));
		return macro $b{el};
	}

	macro static public function UNREACHABLE() {
		var fun = Context.getLocalMethod();
		var pos = Context.currentPos();
		var cls = Context.getLocalClass();
		return macro throw 'ERROR: $cls:$pos This code should not be reached in $fun()';
	}

	macro static public function RETURN_ERROR(msg:Expr):Expr {
		var locals = Context.getLocalVars();

		return macro do {
			vm.fiber.error = vm.newStringLength($msg);
			return false;
		} while (true);
	}

	/**
	 * Binds a primitive method named [name] (in Wren) implemented using Haxe function
	 * [fn] to `ObjClass` [cls].
	 * @param cls
	 * @param name
	 * @param function
	 */
	macro static public function PRIMITIVE(cls:Expr, name:Expr, fn:Expr):Expr {
		var exprs:Array<Expr> = [];
		exprs.push(macro var symbol = vm.symbolTableEnsure($i{"vm"}.methodNames, $name, $name.length));
		var funcName = "";
		switch fn.expr {
			case EConst(CIdent(fname)):
				{
					funcName = 'prim_' + $v{fname};
				}
			case _:
		}

		exprs.push(macro var method:Method = {
			type: $i{"METHOD_PRIMITIVE"},
			as: {
				primitive: $i{funcName}
			}
		});

		exprs.push(macro vm.bindMethod($cls, $i{"symbol"}, $i{"method"}));
		return macro $b{exprs};
	}

	macro static public function BuildPrimitives():Array<Field> {
		// The context is the class this build macro is called on
		var fields = Context.getBuildFields();

		for (field in fields) {
			var fieldName = field.name;
			if (field.meta == null)
				continue;

			for (meta in field.meta) {
				if (meta.name == ":def" || meta.name == ":DEF_PRIMITIVE") {
					for (param in meta.params) {
						switch (param.expr) {
							case EConst(CString(name)):
								{
									var fname = 'prim_$name';
									fields.push({
										pos: Context.currentPos(),
										access: [AStatic, APublic],
										name: fname,
										meta: null,
										kind: FieldType.FFun({
											ret: TPath({name: "Bool", pack: []}),
											expr: macro return $i{name}(vm, args),
											args: [
												{name: 'vm', type: TPath({name: "VM", pack: ["wren"]})},
												{
													name: 'args',
													type: TPath({
														name: "Array",
														pack: [],
														params: [TPType(TPath({name: "Value", pack: ["wren"]}))]
													})
												}
											]
										})
									});
								}
							case _:
						}
					}
				}
			}
		}
		return fields;
	}

	// static public final RETURN_FALSE = () -> {
	// 	RETURN_VAL({type: VAL_FALSE, as: null});
	// 	return false;
	// };

	// static public final RETURN_TRUE = () -> {
	// 	RETURN_VAL({type: VAL_TRUE, as: null});
	// 	return false;
	// };



	static public inline function OBJ_VAL(obj:Obj):Value {
		var toVal:Value = obj;
		return toVal;
	}

	static public inline function NUM_VAL(val:Float):Value {
		var toVal:Value = val;
		return toVal;
	}

	static public inline function AS_OBJ(value:Value):Obj {
		return value;
	}

	static public inline function AS_NUM(value:Value):Float {
		return value;
	}

	static public inline function AS_CLASS(value:Obj):ObjClass {
		return cast value;
	}

	static public inline function AS_CLOSURE(value:Obj):ObjClosure {
		return cast value;
	}

	static public inline function AS_FIBER(value:Obj):ObjFiber {
		return cast value;
	}

	static public inline function AS_LIST(value:Obj):ObjList {
		return cast value;
	}

	static public inline function AS_MAP(value:Obj):ObjMap {
		return cast value;
	}

	static public inline function AS_RANGE(value:Obj):ObjRange {
		return cast value;
	}

	static public inline function AS_STRING(value:Value):ObjString {
		return cast AS_OBJ(value);
	}

	static public inline function IS_CLOSURE(value:Value):Bool {
		return value.isObjType(OBJ_CLOSURE);
	}

	static public inline function IS_RANGE(value:Value):Bool {
		return value.isObjType(OBJ_RANGE);
	}

	static public inline function IS_CLASS(value:Value):Bool {
		return value.isObjType(OBJ_CLASS);
	}

	static public inline function IS_UNDEFINED(value:Value):Bool {
		return value.isUndefined();
	}

	static public inline function IS_NULL(value:Value):Bool {
		return value.isNull();
	}

	static public inline function IS_NUM(value:Value):Bool {
		return value.isNum();
	}

	macro static public function RETURN_OBJ(value:Expr):Expr {
		var pos = Context.currentPos();
		var exp = macro $i{'args'}[0] = OBJ_VAL($value);
		var body = macro do {
			$exp;
			return true;
		} while (true);

		return body;
	}

	macro static public function RETURN_NUM(value:Expr):Expr {
		var pos = Context.currentPos();
		var exp = macro $i{'args'}[0] = NUM_VAL($value);
		var body = macro do {
			$exp;
			return true;
		} while (true);

		return body;
	}
		

	static public inline function BOOL_VAL(b:Bool):Value
		return b ? new Value({type: VAL_TRUE, as: null}) : new Value({type: VAL_FALSE, as: null});

	static public inline function AS_BOOL(value:Value)
		return value.type == VAL_TRUE;

	macro static public function RETURN_BOOL(value:Expr):Expr {
		var pos = Context.currentPos();
		var exp = macro $i{'args'}[0] = BOOL_VAL($value);
		var body = macro do {
			$exp;
			return true;
		} while (true);

		return body;
	}

		

	static public inline function CONST_STRING(vm:VM, text:String) {
		return vm.newStringLength(text);
	}

	/**
	 * Use the VM's allocator to allocate an object of [type].
	 * @param vm
	 * @return T
	 */
	public static inline function ALLOCATE<T>(vm:VM):T {
		return null;
	}

	public static inline function ALLOCATE_FLEX<T1, T2>(vm:VM):T1 {
		return null;
	}

	public static inline function ALLOCATE_ARRAY<T>(vm:VM):T {
		return null;
	}

	public static inline function DEALLOCATE<T>(vm:VM, val:T):T {
		return null;
	}
}

private typedef AssertionPart = {
	expr:String,
	value:Dynamic
}

class AssertionFailure {
	public var message(default, null):String;
	public var parts(default, null):Array<AssertionPart>;

	public function new(message:String, parts:Array<AssertionPart>) {
		this.message = message;
		this.parts = parts;
	}

	public function toString() {
		var buf = new StringBuf();
		buf.add("Assertion failure: " + message);
		for (part in parts) {
			buf.add("\n\t" + part.expr + ": " + part.value);
		}
		return buf.toString();
	}
}


