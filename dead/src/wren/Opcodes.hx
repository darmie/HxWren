package wren;


enum EOpcodes {
	OPCODE(name:String, stackEffect:Int);
}

enum abstract  Opcodes(EOpcodes) from EOpcodes to EOpcodes {

    inline function new(name:String, effect:Int) {
		Compiler.stackEffects.push(effect);
        this = OPCODE(name, effect);
    }

	/**
	 * Load the constant at index [arg].
	 */
	public static final CODE_CONSTANT = new Opcodes("CONSTANT", 1);

	/**
	 * Push null onto the stack.
	 */
	public static final CODE_NULL = new Opcodes("NULL", 1);

	/**
	 * Push false onto the stack.
	 */
	public static final CODE_FALSE = new Opcodes("FALSE", 1);

	/**
	 * Push true onto the stack.
	 */
	public static final CODE_TRUE = new Opcodes("TRUE", 1);

	// Pushes the value in the given local slot.
	public static final CODE_LOAD_LOCAL_0 = new Opcodes("LOAD_LOCAL_0", 1);
	public static final CODE_LOAD_LOCAL_1 = new Opcodes("LOAD_LOCAL_1", 1);
	public static final CODE_LOAD_LOCAL_2 = new Opcodes("LOAD_LOCAL_2", 1);
	public static final CODE_LOAD_LOCAL_3 = new Opcodes("LOAD_LOCAL_3", 1);
	public static final CODE_LOAD_LOCAL_4 = new Opcodes("LOAD_LOCAL_4", 1);
	public static final CODE_LOAD_LOCAL_5 = new Opcodes("LOAD_LOCAL_5", 1);
	public static final CODE_LOAD_LOCAL_6 = new Opcodes("LOAD_LOCAL_6", 1);
	public static final CODE_LOAD_LOCAL_7 = new Opcodes("LOAD_LOCAL_7", 1);
	public static final CODE_LOAD_LOCAL_8 = new Opcodes("LOAD_LOCAL_8", 1);

	/**
	 * Stores the top of stack in local slot [arg]. Does not pop it.
	 */
	public static final CODE_STORE_LOCAL = new Opcodes("STORE_LOCAL", 0);

	/**
	 * Pushes the value in upvalue [arg].
	 */
	public static final CODE_LOAD_UPVALUE = new Opcodes("LOAD_UPVALUE", 1);

	/**
	 * Stores the top of stack in upvalue [arg]. Does not pop it.
	 */
	public static final CODE_STORE_UPVALUE = new Opcodes("STORE_UPVALUE", 0);

	/**
	 * Pushes the value of the top-level variable in slot [arg].
	 */
	public static final CODE_LOAD_MODULE_VAR = new Opcodes("LOAD_MODULE_VAR", 1);

	/**
	 * Stores the top of stack in top-level variable slot [arg]. Does not pop it.
	 */
	public static final CODE_STORE_MODULE_VAR = new Opcodes("STORE_MODULE_VAR", 0);

	/**
	 * Pushes the value of the field in slot [arg] of the receiver of the current
	 * function. This is used for regular field accesses on "this" directly in
	 * methods. This instruction is faster than the more general CODE_LOAD_FIELD
	 * instruction.
	 */
	public static final CODE_LOAD_FIELD_THIS = new Opcodes("LOAD_FIELD_THIS", 1);

	/**
	 * Stores the top of the stack in field slot [arg] in the receiver of the
	 * current value. Does not pop the value. This instruction is faster than the
	 * more general CODE_LOAD_FIELD instruction.
	 */
	public static final CODE_STORE_FIELD_THIS = new Opcodes("STORE_FIELD_THIS", 0);

	/**
	 *  Pops an instance and pushes the value of the field in slot [arg] of it.
	 */
	public static final CODE_LOAD_FIELD = new Opcodes("LOAD_FIELD", 0);

	/**
	 * Pops an instance and stores the subsequent top of stack in field slot
	 * [arg] in it. Does not pop the value.
	 */
	public static final CODE_STORE_FIELD = new Opcodes("STORE_FIELD", -1);

	/**
	 *  Pop and discard the top of stack.
	 */
	public static final POP = new Opcodes("POP", 0);

	// Invoke the method with symbol [arg]. The number indicates the number of
	// arguments (not including the receiver).
	public static final CODE_CALL_0 = new Opcodes("CALL_0", 0);
	public static final CODE_CALL_1 = new Opcodes("CALL_1", -1);
	public static final CODE_CALL_2 = new Opcodes("CALL_2", -2);
	public static final CODE_CALL_3 = new Opcodes("CALL_3", -3);
	public static final CODE_CALL_4 = new Opcodes("CALL_4", -4);
	public static final CODE_CALL_5 = new Opcodes("CALL_5", -5);
	public static final CODE_CALL_6 = new Opcodes("CALL_6", -6);
	public static final CODE_CALL_7 = new Opcodes("CALL_7", -7);
	public static final CODE_CALL_8 = new Opcodes("CALL_8", -8);
	public static final CODE_CALL_9 = new Opcodes("CALL_9", -9);
	public static final CODE_CALL_10 = new Opcodes("CALL_10", -10);
	public static final CODE_CALL_11 = new Opcodes("CALL_11", -11);
	public static final CODE_CALL_12 = new Opcodes("CALL_12", -12);
	public static final CODE_CALL_13 = new Opcodes("CALL_13", -13);
	public static final CODE_CALL_14 = new Opcodes("CALL_14", -14);
	public static final CODE_CALL_15 = new Opcodes("CALL_15", -15);
	public static final CODE_CALL_16 = new Opcodes("CALL_16", -16);

	// Invoke a superclass method with symbol [arg]. The number indicates the
	// number of arguments (not including the receiver).
	public static final CODE_SUPER_0 = new Opcodes("SUPER_0", 0);
	public static final CODE_SUPER_1 = new Opcodes("SUPER_1", -1);
	public static final CODE_SUPER_2 = new Opcodes("SUPER_2", -2);
	public static final CODE_SUPER_3 = new Opcodes("SUPER_3", -3);
	public static final CODE_SUPER_4 = new Opcodes("SUPER_4", -4);
	public static final CODE_SUPER_5 = new Opcodes("SUPER_5", -5);
	public static final CODE_SUPER_6 = new Opcodes("SUPER_6", -6);
	public static final CODE_SUPER_7 = new Opcodes("SUPER_7", -7);
	public static final CODE_SUPER_8 = new Opcodes("SUPER_8", -8);
	public static final CODE_SUPER_9 = new Opcodes("SUPER_9", -9);
	public static final CODE_SUPER_10 = new Opcodes("SUPER_10", -10);
	public static final CODE_SUPER_11 = new Opcodes("SUPER_11", -11);
	public static final CODE_SUPER_12 = new Opcodes("SUPER_12", -12);
	public static final CODE_SUPER_13 = new Opcodes("SUPER_13", -13);
	public static final CODE_SUPER_14 = new Opcodes("SUPER_14", -14);
	public static final CODE_SUPER_15 = new Opcodes("SUPER_15", -15);
	public static final CODE_SUPER_16 = new Opcodes("SUPER_16", -16);

	/**
	 * Jump the instruction pointer [arg] forward.
	 */
	public static final CODE_JUMP = new Opcodes("JUMP", 0);

	/**
	 * Jump the instruction pointer [arg] backward.
	 */
	public static final CODE_LOOP = new Opcodes("LOOP", 0);

	/**
	 * Pop and if not truthy then jump the instruction pointer [arg] forward.
	 */
	public static final CODE_JUMP_IF = new Opcodes("JUMP_IF", -1);

	/**
	 * If the top of the stack is false, jump [arg] forward. Otherwise, pop and
	 * continue.
	 */
	public static final CODE_AND = new Opcodes("AND", -1);

	/**
	 * If the top of the stack is non-false, jump [arg] forward. Otherwise, pop
	 * and continue.
	 */
	public static final CODE_OR = new Opcodes("OR", -1);

	/**
	 * Close the upvalue for the local on the top of the stack, then pop it.
	 */
	public static final CLOSE_UPVALUE = new Opcodes("CLOSE_UPVALUE", -1);

	/**
	 * Exit from the current function and return the value on the top of the
	 * stack
	 */
	public static final CODE_RETURN = new Opcodes("RETURN", 0);

	/**
	 * Creates a closure for the function stored at [arg] in the constant table.
	 *
	 * Following the function argument is a number of arguments, two for each
	 * upvalue. The first is true if the variable being captured is a local (as
	 * opposed to an upvalue), and the second is the index of the local or
	 * upvalue being captured.
	 *
	 * Pushes the created closure.
	 */
	public static final CODE_CLOSURE = new Opcodes("CLOSURE", 1);

	/**
	 * Creates a new instance of a class.
	 *
	 * Assumes the class object is in slot zero, and replaces it with the new
	 * uninitialized instance of that class. This opcode is only emitted by the
	 * compiler-generated constructor metaclass methods.
	 */
	public static final CODE_CONSTRUCT = new Opcodes("CONSTRUCT", 0);

	/**
	 * Creates a new instance of a foreign class.
	 * Assumes the class object is in slot zero, and replaces it with the new
	 * uninitialized instance of that class. This opcode is only emitted by the
	 * compiler-generated constructor metaclass methods.
	 */
	public static final CODE_FOREIGN_CONSTRUCT = new Opcodes("FOREIGN_CONSTRUCT", 0);

	/**
	 * Creates a class. Top of stack is the superclass. Below that is a string for
	 * the name of the class. Byte [arg] is the number of fields in the class.
	 */
	public static final CODE_CLASS = new Opcodes("CLASS", -1);

	/**
	 * Creates a foreign class. Top of stack is the superclass. Below that is a string for
	 * the name of the class. Byte [arg] is the number of fields in the class.
	 */
    public static final CODE_FOREIGN_CLASS = new Opcodes("FOREIGN_CLASS", -1);

    /**
     * Define a method for symbol [arg]. The class receiving the method is popped
     * off the stack, then the function defining the body is popped.
     * 
     * If a foreign method is being defined, the "function" will be a string
     * identifying the foreign method. Otherwise, it will be a function or
     * closure.
     */
    public static final CODE_METHOD_INSTANCE = new Opcodes("METHOD_INSTANCE", -2);

    /**
     * Define a method for symbol [arg]. The class whose metaclass will receive
     * the method is popped off the stack, then the function defining the body is
     * popped.
     * 
     * If a foreign method is being defined, the "function" will be a string
     * identifying the foreign method. Otherwise, it will be a function or
     * closure.
     */
    public static final CODE_METHOD_STATIC = new Opcodes("METHOD_STATIC", -2);

    /**
     * This is executed at the end of the module's body. Pushes NULL onto the stack
     * as the "return value" of the import statement and stores the module as the
     * most recently imported one.
     */
    public static final CODE_END_MODULE = new Opcodes("END_MODULE", 1);

    /**
     * Import a module whose name is the string stored at [arg] in the constant
     * table.
     * 
     * Pushes null onto the stack so that the fiber for the imported module can
     * replace that with a dummy value when it returns. (Fibers always return a
     * value when resuming a caller.)
     */
    public static final CODE_IMPORT_MODULE = new Opcodes("IMPORT_MODULE", 1);

    /**
     * Import a variable from the most recently imported module. The name of the
     * variable to import is at [arg] in the constant table. Pushes the loaded
     * variable's value.
     */
    public static final CODE_IMPORT_VARIABLE = new Opcodes("IMPORT_VARIABLE", 1);

    /**
     * This pseudo-instruction indicates the end of the bytecode. It should
     * always be preceded by a `CODE_RETURN`, so is never actually executed.
     */
    public static final CODE_END =  new Opcodes("END", 0);
    
}
