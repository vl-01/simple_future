# simple_future

Provides a (very) simple async function combinator.

If `f :: A -> B`, then `async!f :: A -> Future!B`. 
Suppose `f(a) = b` and `async!f(a) = c`.

`async!f` will execute `f` in a separate thread when invoked.
While `f` is being computed, `c.pending`.
If `f` succeeds, `c.completed` and `b = c.result`.
If `f` throws, `c.failed`.

Attempting to read `c.result` before `c.completed` is an error.
