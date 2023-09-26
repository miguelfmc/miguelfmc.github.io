---
layout: default
title: "A Few Crazy Python Things (Part II)"
theme: jekyll-theme-slate
---

# A Few Crazy Python Things (Part II)

This is a sequel to [my first post](https://miguelfmc.github.io/2023/09/09/crazy-python-things.html) on a few really interesting things that I recently learned about Python, mostly thanks to David Beazley's [Python Mastery](https://github.com/dabeaz-course/python-mastery) course.

It turns out that I had too many Python tidbits to fit in one post, so, here come another five Python features that I didn't know about or I completely re-discovered.

## 6. `*args` and `**kwargs`

This one is probably well-known by most Pythonistas, but I still wanted to include it.

Python allows us to define functions that take in a variable number of positional or keyword arguments via the `*args` and `**kwargs` syntax, respectively.

`args` will be a tuple containing all variable positional arguments and `kwargs` will be a dictionary containing keys (the keyword argument names) and values (the argument values).
See the example below:

```python
def my_func(a, b, *args, **kwargs):
    print(f"{a=}")
    print(f"{b=}")
    # args is a tuple with positional arguments
    for arg in args:
        print(f"{arg=}")
    # kwargs is a dictionary with keyword arguments
    for key, value in kwargs.items():
        print(f"{key=} {value=}")


my_func("hello", "world!", 1, 2, True, signature="Miguel")
# a='hello'
# b='world!'
# arg=1
# arg=2
# arg=True
# key='signature' value='Miguel'
```

When calling a function, we can expand a tuple of variables as parameters to the function using the `*args` syntax.
Similarly, we can pass the items of a dictionary as keyword arguments to a function using `**kwargs`.
This allows us, for example, to pass whichever variable positional or keyword arguments were passed to our function to other functions.

```python
some_things = (1, 2, True)
other_things = {"signature": "Miguel"}

my_func("hello", "world!", *some_things, **other_things)
# a='hello'
# b='world!'
# arg=1
# arg=2
# arg=True
# key='signature' value='Miguel'
```

By the way, there is nothing special about the names `args` and `kwargs` - you can use any variable names you'd like (preffixed by one or two asterisks, respectively).
That said, it's a pretty well established convention to use those two names.

## 7. Functions as objects

In Python, functions are *objects*.
As objects, they have attributes, including the ubiqituous `__dict__` (!).

With this in mind, we can do strange things like setting arbitrary attributes of our functions:

```python
def square(x):
    return x ** 2

print(square.__dict__)
# {}

# let's set a random attribute in our function
square.foo = 42

print(square.__dict__)
# {'foo': 42}
```

Is this useful in any way?
I'm not convinced it is, but I sure found it intereseting.

## 8. Closures

A closure is an **inner function returned by another (outer) function**, which retains all *necessary* variables for it to run.
For example:

```python
def outer(x, y):
    def inner():
        print(f"Summing 10 to {x}: {x + 10}")
    return inner


fcn = outer(1, 2)
fcn()
# Summing 10 to 1: 11
```

As you can see, the function is somehow keeping track of the variable `x` which was defined in the scope of the `outer` function.

You can check this is indeed the case by looking at the `__closure__` attribute of the function returned by `outer`.

```python
fcn.__closure__
# (<cell at 0x7f3c466563e0: int object at 0x7f3c468300f0>,)
fcn.__closure__[0].cell_contents
# 1
```

Note that the closure is only keeping track of the variable it needs (`x` i.e. the first argument to `outer`).
The second argument to `outer`, i.e. `y`, is not bound to the closure, as it is not needed for it to execute.

Closures can be utilized as objects, since they keep an internal state (via the closure variables), which is *mutable*.
David Beazley gives a very interesing example of this, using closures and the `nonlocal` declaration, similar to the following:

```python
def outer(value):
    def incr():
        nonlocal value
        value += 1
        print(value)
    
    def decr():
        nonlocal value
        value -= 1
        print(value)
    
    return incr, decr


up, down = outer(0)


up()
# 1
up()
# 2
down()
# 1
```

## 9. `globals()` and `locals()`

Also within the topic of function **scopes**, we can use the built-in functions `globals()` and `locals()` to access what is defined in the global and local scope, respectively.
These functions return dictionaries, which are essentially the *namespaces* of each scope.

You can run the following snippet in an interactive Python session to see it with your own eyes:

```python
def func(x):
    print("global namespace:", globals())
    print("local namespace:", locals())


x = 10
func(x)
# global namespace: {'__name__': '__main__', '__doc__': None, '__package__': None, '__loader__': <class '_frozen_importlib.BuiltinImporter'>, '__spec__': None, '__annotations__': {}, '__builtins__': <module 'builtins' (built-in)>, 'func': <function func at 0x7fd4e00f9ca0>, 'x': 10}
# local namespace: {'x': 10}
```

## 10. Executing code with `exec()`

Finally, a powerful but kind of scary Python feature is `exec()`, which allows us to execute code, passed as a string argument to the function.

We can use `exec()` to run code that we generate dynamically in our application.
Look at the following example, in which I defined a function that executes some class definition code.
The class, which is defined in the *local* scope, is then returned.
We could use this function to dynamically create classes.

```python
def create_class(name, *attrs, debug=False):
    """This function creates and returns a simple class
    with the provided name and an __init__ method
    setting the attributes passed in attrs
    """
    lines = "\n        ".join(["self." + attr + " = " + attr for attr in attrs])
    code = (f"class {name}:"
    + f"\n    def __init__(self, {', '.join(attrs)}):"
    + "\n        "
    + f"{lines}")

    if debug:
        print("========== CODE ==========")
        print(code)
        print("===========================")
    exec(code)
    return locals()[name]


MyClass = create_class("MyClass", "foo", "bar", debug=True)
# ========== CODE ==========
# class X:
#     def __init__(self, foo, bar):
#         self.foo = foo
#         self.bar = bar
# ===========================
obj = MyClass(42, "hello")
print(obj.foo)
# 42
print(obj.bar)
# hello
```

As weird as this might look, this is actually used in a few places in the Python standard library, including in the definition of `collections.namedtuple` (take a look!).
As you can see, `namedtuple` basically *creates a class* on the fly.

***

This is it for today but I must confess that there will be a third (and final, I promise) part to this series of posts on interesting Python features.
Until then!