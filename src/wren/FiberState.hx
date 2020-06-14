package wren;

/**
 * Tracks how this fiber has been invoked, aside from the ways that can be
 * detected from the state of other fields in the fiber.
 */
enum FiberState {
  /**
   * The fiber is being run from another fiber using a call to `try()`.
   */
  FIBER_TRY;
  
  /**
   * The fiber was directly invoked by `runInterpreter()`. This means it's the
   * initial fiber used by a call to `wrenCall()` or `wrenInterpret()`.
   */
  FIBER_ROOT;
  
  // The fiber is invoked some other way. If [caller] is `NULL` then the fiber
  // was invoked using `call()`. If [numFrames] is zero, then the fiber has
  // finished running and is done. If [numFrames] is one and that frame's `ip`
  // points to the first byte of code, the fiber has not been started yet.
  FIBER_OTHER;   
}