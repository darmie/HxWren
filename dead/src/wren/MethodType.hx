package wren;

enum MethodType {
	// A primitive method implemented in C in the VM. Unlike foreign methods,
	// this can directly manipulate the fiber's stack.
	METHOD_PRIMITIVE;

	// A externally-defined C method.
	METHOD_FOREIGN;
	// A normal user-defined method.
	METHOD_BLOCK;
	// No method for the given symbol.
	METHOD_NONE;
}
