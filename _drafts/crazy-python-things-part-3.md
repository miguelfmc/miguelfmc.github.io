---
layout: default
title: "A Few Crazy Python Things (Part III)"
theme: jekyll-theme-slate
---

# A Few Crazy Python Things (Part III)

I guess I couldn't leave my blogging about weird Python magic to [just](https://miguelfmc.github.io/2023/09/09/crazy-python-things.html) two [parts](https://miguelfmc.github.io/2023/09/26/crazy-python-things-part-2.html).

This is, I promise, the third and final post in which I humbly write about some Python features that I find equal parts powerful and mindblowing.
Let's dive in.

## 11. Metaclasses

Metaclasses are probably the most mind-bending feature of Python that I've encountered recently.

To properly understand metaclasses, we need to take a step back and think about what classes are in Python.
An insightful definition is the following:

> A `class` is a *callable* that creates **instances**

This begs the question: if classes are also objects (everything is an object in Python) - which `class` is responsible for *creating* classes?

### Class definition: another way

We are familiar with the standard class definition syntax

```python
class MyClass:
    def __init__(self, name):
        self.name = name
```

But classes can also be created in a more "dynamic" way via a call to `type`.
Thus, the code above is equivalent to:

```python
MyClass = type("MyClass", (), {"__init__": lambda self, name: setattr(self, "name", name)})
```

In a nutshell, `type` takes three arguments: the class name, the class' "bases" (aka its parents) and its namespace i.e. what will become its `__dict__` attribute.
Here is a snippet from the [Python documentation](https://docs.python.org/3/library/functions.html#type) on `type`:

> ```python
> class type(name, bases, dict, **kwds)
> ```
>
>With one argument, return the type of an object. The return value is a type object and generally the same object as returned by object.__class__.
>
>The `isinstance()` built-in function is recommended for testing the type of an object, because it takes subclasses into account.
>
>With three arguments, return a new type object. This is essentially a dynamic form of the class statement. The *name* string is the class name and becomes the `__name__` attribute. The *bases* tuple contains the base classes and becomes the `__bases__` attribute; if empty, `object`, the ultimate base of all classes, is added. The *dict* dictionary contains attribute and method definitions for the class body; it may be copied or wrapped before becoming the `__dict__` attribute.

Standard class construction is a (tricky) process involving several steps (which correspond to the `__prepare__`, `__new__` and `__init__` methods of `type`).
Put briefly, when a class is constructed the body of the class is executed in a new namespace, the class object is created and the namespace is then assigned to the object's `__dict__` attribute.
You can read more about it [here](https://docs.python.org/3/reference/datamodel.html#customizing-class-creation).

Without getting too much into the weeds, let's notice how this sheds some light on the question I posed earlier (which class creates classes).
`type` is indeed a class used to create classes i.e. `type` is a **metaclass** (in fact, it is the go-to metaclass, which controls class construction unless specified otherwise).

### Metaclasses

So, basically metaclasses are classes that control class construction.
And we can customize class construction (the process I described above) by defining our own metaclasses.
Wild, isn't it?

Let's look at a minimal example of how to use a metaclass:

```python
class Meta(type):
    def __init__(cls, name, bases, dct):
        print("Creating class!")


class User(metaclass=Meta):
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age


# The following will be printed as we define the User class:
# Creating class!


user = User("username", "user@email.com", 42)


print(type(User))
# <class '__main__.Meta'>
print(type(user))
# <class '__main__.User'>
```

This example is not very useful. 
Let's now use a metaclass for something more interesting: registering classes in a dictionary - this is a potential real-life use-case for metaclasses:

```python
registry = {}


class Meta(type):
    def __new__(meta, name, bases, dct):
        cls = super().__new__(meta, name, bases, dct)
        registry[name] = cls
        return cls


class User(metaclass=Meta):
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

    def greet(self):
        print(f"Hi, my name is {self.name}")


print(registry)
# {'User': <class '__main__.User'>}

class PremiumUser(User):
    def greet(self):
        super().greet()
        print(f"...and I'm also a premium user!")


print(registry)
# {'User': <class '__main__.User'>, 'PremiumUser': <class '__main__.PremiumUser'>}
```

Here we are modifying the metaclass' `__new__` method in order to add the class to a registry everytime a class is created.
This will apply to any class that inherits from `User` as well.

By the way, if you are confused about the difference between `__new__` and `__init__`, I recommend taking a look at this [mCoding video](https://www.youtube.com/watch?v=-zsV0_QrfTw).

Now, should we mere mortals use metaclasses?
Probably not, unless we have a solid grasp of the inner workings of this process and a very good reason to customize class creation.
That said, knowing about metaclasses helps us understand how class construction works in Python, which is very helpful.

## 12. Iteration, under the hood

Moving on to a less complicated but still very relevant topic, I believe it's important to understand how iteration really works in Python.
A for-loop in Python like the one below:

```python
for num in nums:
    print(num)
```

is actually equivalent to the following:

```python
iter_ = nums.__iter__()
while True:
    try:
        num = iter_.__next__()
        print(num)
    except StopIteration:
        break
```

This brings us to the concepts of *iterable* and *iterator* (which I always confuse!):

* We can think of an *iterable* as any target of a for-loop: anything we can iterate over i.e. some data that can be broken into parts. Iterables have an `__iter__` method
* An *iterator* is what the `__iter__` method returns. We can think of iterators as an *iterable* plus a *state*. Iterators have a `__next__` method that returns the next "element" in our iteration (until we have exhausted our data, in which case the iterator raises a `StopIteration` exception).

So, when we execute a for-loop, an iterator is created out of our iterable, and the `__next__` method is called until we reach a `StopIteration`.

## 13. Generators and coroutines

Taking things one step further, let's talk about **generators**.

A very abstract but useful definition of a generator is a **piece of computation through which we can step through in a iterative manner**.
Basically, a generator allows us to **iterate through computation (code)**.

We can define a generator in a very similar way to a regular Python function.
However, in this we will use the `yield` key word, which is an essential part of generators.
These functions are normally referred to as *generator functions*.

When we call the generator function, we instantiate a generator *object*.
A generator is an *iterator* and can be used in the same way as any other iterator.

See the example below:

```python
# generator function
def counter(n):
    for i in range(n):
        yield i

# creating our generator object
cnt = counter(10)
print(cnt)
# <generator object counter at ...>

# iteration
print(next(cnt))
# 0
print(next(cnt))
# 1
```

Generator functions allow us to build iterators with significantly smaller memory footprint than if we were to create the full data e.g. a list, from the beginning.
This is because we perform the computation step-by-step, as we iterate.

While the memory benefits from lazy evaluation are a key advantage of generators, this is just scratching the surface of what generators can do.

...

## 14. Modules

...

## 15. Circular imports

...

***

And with this, I sign off on my Python blogging for some time.
My next posts will gravitate more towards nteresting but fairly accessible Machine Learning and Data Science topics.
Stay tuned!



