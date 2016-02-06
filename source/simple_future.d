module simple_future;
  
import core.thread;
import std.concurrency;
import std.traits;

/**
  Represents a value yet to be computed.
  Its status can be queried (pending, failed, completed).
  A Future fails If the function throws an exception or error.
  A Future is completed once the async function that instantiated it has successfully returned a value.

  The value computed by the async function can be retrieved from a completed Future with result().
  The thread can wait for the Future to complete or fail by calling await().
  await() returns the Future again, so it may be chained before a call to result();
*/
final class Future(T)
if(!is(T == void))
{
public:

  bool pending()() const
  {
    return state.status == Status.pending;
  }
  bool failed()() const
  {
    return state.status == Status.failed;
  }
  bool completed()() const
  {
    return state.status == Status.completed;
  }

  T result()()
  in {
    assert(this.completed);
  } body {
    return state.result;
  }

  Future await()()
  {
    while(this.pending)
      Thread.yield;

    return this;
  }
  
  private{
    this(){}

    enum Status { pending, failed, completed }

    struct State
    {
      T result;
      Status status = Status.pending;
    }
    State state;
  }
}

/**
  Lifts a function to an asynchronous context.
  Calling the lifted function will compute f in a new thread.

  If the function, f, returned a T, then async!f will return a Future!T.
*/
template async(alias f)
{
  Future!(ReturnType!f) async(A...)(A args) // don't want to use ParamterTypeTuple in case f has default args
  {
    alias B = ReturnType!f;

    auto future = new Future!B;

    static auto run(
      shared(Future!B) future
      , A args
    )
    {mixin(asyncBody);}

    spawn(
      &run, cast(shared)future, args
    );

    return future;
  }
}
Future!(B) async(B, A...)(B function(A) f, A args)
{
  auto future = new Future!B;

  static auto run(
    shared(Future!B) future
    , B function(A) f, A args
  )
  {mixin(asyncBody);}

  spawn(
    &run, cast(shared)future, f, args
  );

  return future;
}

private {//
  enum asyncBody = q{
    with((cast()future).state)
    {
      scope(success)
        status = Future!B.Status.completed;
      scope(failure)
        status = Future!B.Status.failed;

      result = f(args);
    }
  };
}

unittest
{
  static real square(real x)
  {
    return x*x;
  }

  auto fsq = async!square(5);

  fsq.await;

  assert(fsq.completed);
  assert(fsq.result == 25);

  static string wait100()
  {
    Thread.sleep(100.msecs);

    return "done";
  }

  auto fwait = async!wait100;

  assert(!fwait.completed);
  assert(fwait.pending);

  Thread.sleep(200.msecs);

  assert(fwait.completed);
  assert(fwait.result == "done");

  static int crash()
  {
    throw new Exception("crashed");
  }

  auto fcrash = async!crash;

  fcrash.await;

  assert(!fcrash.completed);
  assert(!fcrash.pending);
  assert(fcrash.failed);
}
