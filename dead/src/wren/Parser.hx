package wren;

import wren.Token.TokenType;

class Parser {
	public var vm:VM;

	/**
	 * The module being parsed.
	 */
	public var module:ObjModule;

	/**
	 * The source code being parsed.
	 */
	public var source:String;

	/**
	 * The beginning of the currently-being-lexed token in [source].
	 */
	public var tokenStart:String;

	/**
	 * The current character being lexed in [source].
	 */
	public var currentChar:Int;

	/**
	 * The 1-based line number of [currentChar].
	 */
	public var currentLine:Int;

	/**
	 * The most recently lexed token.
	 */
	public var current:Token;

	/**
	 * The most recently consumed/advanced token.
	 */
	public var previous:Token;

	/**
		 Tracks the lexing state when tokenizing interpolated strings.

		Interpolated strings make the lexer not strictly regular: we don't know
		whether a ")" should be treated as a RIGHT_PAREN token or as ending an
		interpolated expression unless we know whether we are inside a string
		interpolation and how many unmatched "(" there are. This is particularly
		complex because interpolation can nest:

			" %( " %( inner ) " ) "

		This tracks that state. The parser maintains a stack of ints, one for each
		level of current interpolation nesting. Each value is the number of
		unmatched "(" that are waiting to be closed.
	 */
	public var parens:Array<Int>;

	public var numParens:Int;

	/**
	 * If subsequent newline tokens should be discarded.
	 */
	public var skipNewlines:Bool;

	/**
	 * Whether compile errors should be printed to stderr or discarded.
	 */
	public var printErrors:Bool;

	/**
	 * If a syntax or compile error has occurred.
	 */
	public var hasError:Bool;

	public function new() {}

	public function printError(line:Int, label:String, message:String) {
		this.hasError = true;
		if (!this.printErrors)
			return;

		//  Only report errors if there is a WrenErrorFn to handle them.
		if (this.vm.config.errorFn == null)
			return;

		// Format the label and message.
		var _message = '$label: $message';

		var module:ObjString = this.module.name;
		var module_name:String = module != null ? module.value : "<unknown>";

		this.vm.config.errorFn(this.vm, WREN_ERROR_COMPILE, module_name, line, _message);
	}

	public function lexError(message:String) {
		printError(this.currentLine, "Error", message);
	}

	/**
	 * Returns true if [c] is a valid (non-initial) identifier character.
	 * @param c
	 */
	function isName(c:String) {
		return return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
	}

	function isDigit(c:String) {
		return c >= '0' && c <= '9';
	}

	/**
	 * Returns the current character the parser is sitting on.
	 */
	function peekChar():String {
		return String.fromCharCode(this.currentChar);
	}

	/**
	 * Returns the character after the current character.
	 */
	function peekNextChar() {
		// If we're at the end of the source, don't read past it.
		if (peekChar() == "\\0")
			return "\\0";
		return String.fromCharCode(this.currentChar + 1);
	}

	function nextChar() {
		var c = peekChar();
		currentChar++;
		if (c == '\n')
			currentLine++;
		return c;
	}

	/**
	 * If the current character is [c], consumes it and returns `true`.
	 * @param c
	 */
	function matchChar(c:String) {
		if (peekChar() != c)
			return false;
		nextChar();
		return true;
	}

	/**
	 * Sets the parser's current token to the given [type] and current character
	 * range.
	 * @param type
	 */
	function makeToken(type:TokenType) {
		current = {};
		current.type = type;
		current.start = this.tokenStart;
		current.length = currentChar - tokenStart.charCodeAt(0);
		current.line = currentLine;

		// Make line tokens appear on the line containing the "\n".
		if (type == TOKEN_LINE)
			current.line--;
	}

	/**
	 * If the current character is [c], then consumes it and makes a token of type
	 * [two]. Otherwise makes a token of type [one].
	 * @param c
	 * @param two
	 * @param one
	 */
	function twoCharToken(c:String, two:TokenType, one:TokenType) {
		makeToken(matchChar(c) ? two : one);
	}

	/**
	 * Skips the rest of the current line.
	 */
	function skipLineComment() {
		while (peekChar() != '\n' && peekChar() != '\\0') {
			nextChar();
		}
	}
}
