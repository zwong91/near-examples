import { NearBindgen, near, call, view } from 'near-sdk-js'

@NearBindgen({})
class Counter {
  val: number = 0;

  @view({}) // Public read-only method: Returns the counter value.
  get_num(): number {
    return this.val
  }

  @call({}) // Public method: Increment the counter.
  increment() {
    this.val += 1;
    near.log(`Increased number to ${this.val}`)
  }

  @call({}) // Public method: Decrement the counter.
  decrement() {
    this.val -= 1;
    near.log(`Decreased number to ${this.val}`)
  }

  @call({}) // Public method - Reset to zero.
  reset() {
    this.val = 0;
    near.log(`Reset counter to zero`)
  }
}