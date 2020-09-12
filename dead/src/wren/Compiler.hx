package wren;

import wren.Token.TokenType;
import haxe.ds.Vector;
import wren.Buffer.IntBuffer;
import wren.Buffer.SymbolTable;
import wren.ObjString;
import wren.Macros.*;

typedef Local = {
	/**
	 * The name of the local variable. This points directly into the original
	 * source code string.
	 */
	var name:String;

	/**
	 * The length of the local variable's name.
	 */
	var length:Int;

	/**
	 * The depth in the scope chain that this variable was declared at. Zero is
	 * the outermost scope--parameters for a method, or the first local block in
	 * top level code. One is the scope within that, etc.
	 */
	var depth:Int;

	/**
	 * If this local variable is being used as an upvalue.
	 */
	var isUpvalue:Bool;
}

enum SignatureType {
	// A name followed by a (possibly empty) parenthesized parameter list. Also
	// used for binary operators.
	SIG_METHOD;

	// Just a name. Also used for unary operators.
	SIG_GETTER;
	// A name followed by "=".
	SIG_SETTER;
	// A square bracketed parameter list.
	SIG_SUBSCRIPT;
	// A square bracketed parameter list followed by "=".
	SIG_SUBSCRIPT_SETTER;
	// A constructor initializer function. This has a distinct signature to
	// prevent it from being invoked directly outside of the constructor on the
	// metaclass.
	SIG_INITIALIZER;
}

typedef Signature = {
	var name:String;
	var length:Int;
	var type:SignatureType;
	var arity:Int;
}

typedef CompilerUpvalue = {
	/**
	 * True if this upvalue is capturing a local variable from the enclosing
	 * function. False if it's capturing an upvalue.
	 */
	var isLocal:Bool;

	/**
	 * The index of the local or upvalue being captured in the enclosing function.
	 */
	var index:Int;
}

/**
 * Bookkeeping information for the current loop being compiled.
 */
typedef Loop = {
	/**
	 * Index of the instruction that the loop should jump back to.
	 */
	var start:Int;

	/**
	 * Index of the argument for the CODE_JUMP_IF instruction used to exit the
	 * loop. Stored so we can patch it once we know where the loop ends.
	 */
	var exitJump:Int;

	/**
	 * Index of the first instruction of the body of the loop.
	 */
	var body:Int;

	/**
	 * Depth of the scope(s) that need to be exited if a break is hit inside the
	 * loop.
	 */
	var scopeDepth:Int;

	/**
	 * The loop enclosing this one, or NULL if this is the outermost loop.
	 */
	var enclosing:Loop;
}

/**
 * Bookkeeping information for compiling a class definition.
 */
typedef ClassInfo = {
	/**
	 * The name of the class.
	 */
	var name:ObjString;

	/**
	 * Symbol table for the fields of the class.
	 */
	var fields:SymbolTable;

	/**
	 * Symbols for the methods defined by the class. Used to detect duplicate
	 * method definitions.
	 */
	var methods:IntBuffer;

	var staticMethods:IntBuffer;

	/**
	 * True if the class being compiled is a foreign class.
	 */
	var ifForeign:Bool;

	/**
	 * True if the current method being compiled is static.
	 */
	var inStatic:Bool;

	var signature:Signature;
}

/**
 * Describes where a variable is declared.
 */
enum Scope {
  // A local variable in the current function.
    SCOPE_LOCAL;
  
  // A local variable declared in an enclosing function.
  SCOPE_UPVALUE;
  
  // A top-level module variable.
  SCOPE_MODULE;   
}

/**
 * A reference to a variable and the scope where it is defined. This contains
 * enough information to emit correct code to load or store the variable.
 */
typedef Variable = {
    /**
     * The stack slot, upvalue slot, or module symbol defining the variable.
     */
    var index:Int;

    /**
     * Where the variable is declared.
     */
    var scope:Scope;
}

typedef Keyword = {
	var identifier:String;
	var length:Int;
	var tokenType:TokenType;
}

class Compiler {
	/**
		*  This is written in bottom-up order, so the tokenization comes first, then
				parsing/code generation. This minimizes the number of explicit forward
				declarations needed.

				The maximum number of local (i.e. not module level) variables that can be
				declared in a single function, method, or chunk of top level code. This is
				the maximum number of variables in scope at one time, and spans block scopes.

				Note that this limitation is also explicit in the bytecode. Since
				`CODE_LOAD_LOCAL` and `CODE_STORE_LOCAL` use a single argument byte to
				identify the local, only 256 can be in scope at one time.
	 */
	public static final MAX_LOCALS = 256;

	/**
	 * The maximum number of upvalues (i.e. variables from enclosing functions)
	 * that a function can close over.
	 */
	public static final MAX_UPVALUES = 256;

	/**
	 * The maximum number of distinct constants that a function can contain. This
	 * value is explicit in the bytecode since `CODE_CONSTANT` only takes a single
	 * two-byte argument.
	 */
	public static final MAX_CONSTANTS = (1 << 16);

	/**
	 * The maximum distance a CODE_JUMP or CODE_JUMP_IF instruction can move the
	 * instruction pointer.
	 */
	public static final MAX_JUMP = (1 << 16);

	/**
	 * The maximum depth that interpolation can nest. For example, this string has
	 * three levels:
	 *  "outside %(one + "%(two + "%(three)")")"
	 */
	public static final MAX_INTERPOLATION_NESTING = 8;

	/**
		* The buffer size used to format a compile error message, excluding the header
				with the module name and error location. Using a hardcoded buffer for this
				is kind of hairy, but fortunately we can control what the longest possible
				message is and handle that. Ideally, we'd use `snprintf()`, but that's not
				available in standard C++98.
	 */
    public static final ERROR_MESSAGE_SIZE = (80 + MAX_VARIABLE_NAME + 15);
    
	public static final stackEffects:Array<Int> = [];
	
	public static final keywords:Array<Keyword> = [
		{identifier:"break",     length:5, tokenType:TOKEN_BREAK},
		{identifier:"class",     length:5, tokenType:TOKEN_CLASS},
		{identifier:"construct", length:9, tokenType:TOKEN_CONSTRUCT},
		{identifier:"else",      length:4, tokenType:TOKEN_ELSE},
		{identifier:"false",     length:5, tokenType:TOKEN_FALSE},
		{identifier:"for",       length:3, tokenType:TOKEN_FOR},
		{identifier:"foreign",   length:7, tokenType:TOKEN_FOREIGN},
		{identifier:"if",        length:2, tokenType:TOKEN_IF},
		{identifier:"import",    length:6, tokenType:TOKEN_IMPORT},
		{identifier:"in",        length:2, tokenType:TOKEN_IN},
		{identifier:"is",        length:2, tokenType:TOKEN_IS},
		{identifier:"null",      length:4, tokenType:TOKEN_NULL},
		{identifier:"return",    length:6, tokenType:TOKEN_RETURN},
		{identifier:"static",    length:6, tokenType:TOKEN_STATIC},
		{identifier:"super",     length:5, tokenType:TOKEN_SUPER},
		{identifier:"this",      length:4, tokenType:TOKEN_THIS},
		{identifier:"true",      length:4, tokenType:TOKEN_TRUE},
		{identifier:"var",       length:3, tokenType:TOKEN_VAR},
		{identifier:"while",     length:5, tokenType:TOKEN_WHILE},
		{identifier:null,        length:0, tokenType:TOKEN_EOF}
	];

	public var parser:Parser;

	/**
	 * The compiler for the function enclosing this one, or NULL if it's the
	 * top level.
	 */
	public var parent:Compiler;

	/**
	 * The currently in scope local variables.
	 */
	public var locals:Array<Local> = [];

	/**
	 * The number of local variables currently in scope.
	 */
	public var numLocals:Int;

	/**
	 * The upvalues that this function has captured from outer scopes. The count
	 * of them is stored in [numUpvalues].
	 */
	public var upvalues:Array<CompilerUpvalue> = [];

	/**
	 * The current level of block scope nesting, where zero is no nesting. A -1
	 * here means top-level code is being compiled and there is no block scope
	 * in effect at all. Any variables declared will be module-level.
	 */
	public var scopeDepth:Int;

	/**
				 The current number of slots (locals and temporaries) in use.

				We use this and maxSlots to track the maximum number of additional slots
				a function may need while executing. When the function is called, the
				fiber will check to ensure its stack has enough room to cover that worst
				case and grow the stack if needed.

				This value here doesn't include parameters to the function. Since those
				are already pushed onto the stack by the caller and tracked there, we
				don't need to double count them here.
	 */
    public var numSlots:Int;

    /**
     * The current innermost loop being compiled, or NULL if not in a loop.
     */
    public var loop:Loop;

    /**
     * If this is a compiler for a method, keeps track of the class enclosing it.
     */
    public var enclosingClass:ClassInfo;

    /**
     * The function being compiled.
     */
    public var fn:ObjFn;
    public var constants:ObjMap;

	/**
		*
		This module defines the compiler for Wren. It takes a string of source code
		and lexes, parses, and compiles it. Wren uses a single-pass compiler. It
		does not build an actual AST during parsing and then consume that to
		generate code. Instead, the parser directly emits bytecode.

		This forces a few restrictions on the grammar and semantics of the language.
		Things like forward references and arbitrary lookahead are much harder. We
		get a lot in return for that, though.

		The implementation is much simpler since we don't need to define a bunch of
		AST data structures. More so, we don't have to deal with managing memory for
		AST objects. The compiler does almost no dynamic allocation while running.

		Compilation is also faster since we don't create a bunch of temporary data
		structures and destroy them after generating code.

		Compiles [source], a string of Wren source code located in [module], to an
		[ObjFn] that will execute that code when invoked. Returns `NULL` if the
		source contains any syntax errors.

		If [isExpression] is `true`, [source] should be a single expression, and
		this compiles it to a function that evaluates and returns that expression.
		Otherwise, [source] should be a series of top level statements.

		If [printErrors] is `true`, any compile errors are output to stderr.
		Otherwise, they are silently discarded.

	 */
	public static function compile(vm:VM, module:ObjModule, source:String, isExpression:Bool, printErrrors:Bool):ObjFn {
		return null;
	}

	/**
		*  When a class is defined, its superclass is not known until runtime since
				class definitions are just imperative statements. Most of the bytecode for a
				a method doesn't care, but there are two places where it matters:

				- To load or store a field, we need to know the index of the field in the
					instance's field array. We need to adjust this so that subclass fields
					are positioned after superclass fields, and we don't know this until the
					superclass is known.

				- Superclass calls need to know which superclass to dispatch to.

				We could handle this dynamically, but that adds overhead. Instead, when a
				method is bound, we walk the bytecode for the function and patch it up.
		* @param classObj
		* @param fn
	 */
	public static function bindMethodCode(classObj:ObjClass, fn:ObjFn) {}

	/**
	 * Reaches all of the heap-allocated objects in use by [compiler] (and all of
	 * its parents) so that they are not collected by the GC.
	 * @param vm
	 */
	public static function mark(vm:VM) {}
	

	/**
	 * Initializes [compiler].
	 */
	public function new(parser:Parser, parent:Compiler, isMethod:Bool) {
		this.parser = parser;
		this.parent = parent;
		this.loop = null;
		this.enclosingClass = null;

		// Initialize these to NULL before allocating in case a GC gets triggered in
		// the middle of initializing the compiler.
		this.fn = null;
		this.constants = null;
		this.parser.vm.compiler = this;

		// Declare a local slot for either the closure or method receiver so that we
		// don't try to reuse that slot for a user-defined local variable. For
		// methods, we name it "this", so that we can resolve references to that like
		// a normal variable. For functions, they have no explicit "this", so we use
		// an empty name. That way references to "this" inside a function walks up
		// the parent chain to find a method enclosing the function whose "this" we
		// can close over.	
		this.numLocals = 1;
		this.numSlots = this.numLocals;
		
		if(isMethod){
			locals[0].name = "this";
			locals[0].length = 4;
		} else {
			locals[0].name = null;
    		locals[0].length = 0;
		}

		locals[0].depth = -1;
		locals[0].isUpvalue = false;
		  
		if (parent == null)
		{
			// Compiling top-level code, so the initial scope is module-level.
			scopeDepth = -1;
		}
		else
		{
			  // The initial scope for functions and methods is local scope.
			  scopeDepth = 0;
		}

		fn = this.parser.vm.newFunction(this.parser.module, this.numSlots);  
	}

    
    public function error(message:String){
        var token = this.parser.previous;

        // If the parse error was caused by an error token, the lexer has already
        // reported it.
        if (token.type == TOKEN_ERROR) return;

        switch token.type {
            case TOKEN_ERROR: return;
            case TOKEN_LINE: this.parser.printError(token.line, "Error at newline", message);
            case TOKEN_EOF: this.parser.printError(token.line, "Error at end of file", message);
            case _: {
                this.parser.printError(token.line, 'Error at ${token.start}'.substr(0, 10 + MAX_VARIABLE_NAME + 4 + 1), message);
            }
        }
    }


    /**
     * Adds [constant] to the constant pool and returns its index.
     * @param constant 
     * @return Int
     */
    public function addConstant(constant:Value):Int {
        if (this.parser.hasError) return -1;
        // See if we already have a constant for the value. If so, reuse it.
        if (this.constants != null){
            var existing:Value = this.constants[constant];
            if(IS_NUM(existing)) return Std.int(AS_NUM(existing));
        }

        // It's a new constant.
        if(this.fn.constants.count < MAX_CONSTANTS){
            if (constant.isObj()) this.parser.vm.pushRoot(AS_OBJ(constant));
            this.fn.constants.write(constant);
            if (constant.isObj()) this.parser.vm.popRoot();

            if (constants == null){
                this.constants = ObjMap.init(this.parser.vm);
			}
			
			this.constants[constant] = NUM_VAL(this.fn.constants.count - 1);
        } else {
			error('A function may only contain $MAX_CONSTANTS unique constants');
		}



        return this.fn.constants.count - 1;
    }
}
