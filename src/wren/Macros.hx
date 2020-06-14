package wren;

import haxe.macro.Expr;
import haxe.macro.Context;
import sys.FileSystem;
import haxe.io.Path;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import wren.Value;

class Macros {
	macro static public function RETURN_VAL(value:Expr):Expr {
		var locals = Context.getLocalVars();
		var exprs:Expr = null;
		for (local in locals.keys()) {
			if (local == "args") {
				exprs = macro $i{local}[0] = $value;
				break;
			}
		}

		return macro do {
			$b{[exprs]};
			return true;
		} while (true);
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

	static public final RETURN_FALSE = () -> {
		RETURN_VAL({type: VAL_FALSE, as: null});
		return false;
	};

	static public final RETURN_TRUE = () -> {
		RETURN_VAL({type: VAL_TRUE, as: null});
		return false;
	};

	static public final RETURN_NULL = () -> {
		RETURN_VAL({type: VAL_NULL, as: null});
		return false;
	};

	static public inline function OBJ_VAL(obj:Obj):Value {
		var toVal:Value = obj;
		return toVal;
	}

	static public inline function NUM_VAL(val:Int):Value {
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

	static public inline function RETURN_OBJ(value:Value)
		return RETURN_VAL(OBJ_VAL(value));

	static public inline function RETURN_NUM(value:Int)
		return RETURN_VAL(NUM_VAL(value));

	static public inline function BOOL_VAL(b:Bool):Value
		return b ? {type: VAL_TRUE, as: null} : {type: VAL_FALSE, as: null};

	static public inline function AS_BOOL(value:Value)
		return value.type == VAL_TRUE;

	static public inline function RETURN_BOOL(value:Bool)
		return RETURN_VAL(BOOL_VAL(value));

	static public inline function CONST_STRING(vm:VM, text:String) {
		return vm.newStringLength(text);
	}

	/**
	 * Use the VM's allocator to allocate an object of [type].
	 * @param vm
	 * @return cast vm.reallocate(null, 0)
	 */
	public static inline function ALLOCATE<T>(vm:VM):T
		return cast vm.reallocate(null, 0);

	public static inline function ALLOCATE_FLEX<T1, T2>(vm:VM):T1
		return cast vm.reallocate(null, 0);

	public static inline function ALLOCATE_ARRAY<T1>(vm:VM):T1
		return cast vm.reallocate(null, 0);

	public static inline function DEALLOCATE<T>(vm:VM, val:T):T
		return cast vm.reallocate(val, 0);
}
