/**
 * One Sysprose model load at a time.
 *
 * Not a throughput knob: on this host two concurrent loads put two 38k-element
 * standard libraries in memory at once and the machine swaps itself to a halt
 * (see the freeze of 2026-09-02). The lock is held across the analytics too,
 * because the analytics are what hold the model alive — releasing after the
 * load would let a second model in beside the first.
 */
export class SerialQueue {
  #tail: Promise<unknown> = Promise.resolve();

  /** Run `fn` when every earlier call has finished. Rejections do not stall the queue. */
  run<T>(fn: () => Promise<T>): Promise<T> {
    const result = this.#tail.then(fn, fn);
    this.#tail = result.then(
      () => undefined,
      () => undefined,
    );
    return result;
  }
}
