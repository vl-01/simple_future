# simple_future

Provides a (very) simple async function combinator.

If `f :: A -> B`, then `async!f :: A -> Future!B`. 
Suppose `f(a) = b` and `async!f(a) = c`.

`async!f` will execute `f` in a separate thread when invoked.

While `f` is being computed, `c.pending`.

If `f` succeeds, `c.completed` and `b == c.result`.

If `f` throws, `c.failed`.

Attempting to read `c.result` before `c.completed` is an error.

`async!f` can be made blocking at any time with `c.await`.

For convenience, `c.await` returns `c` so that `c.await.result == c.result`.

Note that, for `async!f`, `f` must be public so that the `async` template can see it.
To lift a non-publicly-visible function `g :: A -> B`, use the non-template `async(g, a)`.
