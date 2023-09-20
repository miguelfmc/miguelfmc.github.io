---
layout: default
title: "A Few Crazy Python Things (Part II)"
theme: jekyll-theme-slate
---

# A Few Crazy Python Things (Part II)

This is a *sequel* to [my first post](https://miguelfmc.github.io/2023/09/09/crazy-python-things.html) on a few really interesting things that I recently learned about Python, mostly thanks to David Beazley's [Python Mastery](https://github.com/dabeaz-course/python-mastery) course.

It turns out that I had too many Python tidbits to fit in one post, so, after learning about things like `__slots__` or descriptors in the last post, here come another five Python features which either I didn't know about or I completely re-discovered.

## 6. `*args` and `**kwargs`

This one is probably well-known by most Pythonistas, but I still wanted to include it in the post.

Python allows us to define functions that take in a variable number of positional and/or keyword arguments via the `*args` and `**kwargs` arguments.

`args` will be a tuple containing all variable positional arguments and `kwargs` will be a dictionary containing keys (the keyword argument names) and values (the argument values).

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

On top of this, we can expand a tuple of variables as parameters to a function using the `*args` syntax.
Similarly, we can pass the items of a dictionary as keyword arguments to a function using the `**kwargs` syntax.
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

In Python, functions are objects.
As objects, they have attributes, including the ubiqituous `__dict__` (!).

We can do strange things like setting arbitrary attributes of our functions:

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

Somehow, it seems like the function is keeping track of the variable `x` which was defined in the scope of the `outer` function.

You can check this out by looking at the `__closure__` attribute of the function returned by the call to `outer`.

```python
fcn.__closure__
# (<cell at 0x7f3c466563e0: int object at 0x7f3c468300f0>,)
fcn.__closure__[0].cell_contents
# 1
```

Note that the closure is only keeping track of the variable it needs (`x` i.e. the first argument to `outer`), but the second argument to `outer` i.e. `y` is not bound to our `fcn` function.

I think this is a very interesting feature that speaks to the concept of scopes and nested scopes.

Closures can be utilized as objects, since they keep an internal state (closure variables), which is *mutable*.
David Beazley gives a very interesing example similar to the following:

```python
# TODO
```

## 9. `globals()` and `locals()`

## 10. Executing code with `exec()`

## Bonus mindblow: Metaclasses