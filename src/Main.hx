package ;

import wren.VM;
import wren.Core;


/**
	@author $author
**/
class Main {
	public static function main() {
		new Main();
	}

	public function new() {
		trace(getVal(["boy"]));
	}

	function getVal(args:Array<String>):Bool {
		var vm = new VM(); 
		var core = new Core(vm);
		return false;
	}
}