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

Metaclasses are probably the most mind-bending feature of Python that I've encountered.

To properly understand metaclasses, we need to take a step back and think about what Python classes are.
An insightful definition is the following:

> A `class` is a *callable* that creates **instances**

This begs the question: given that classes are also objects (everything is an object in Python) - which `class` is responsible for *creating* classes?

### A different way to construct classes

We are familiar with the standard class definition syntax:

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

In a nutshell, `type` (when used for class creation) takes three arguments: the class name, the class' "bases" i.e. its parents, and its namespace i.e. what will become its `__dict__` attribute.
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

Without getting into the weeds, let's notice how this sheds some light on the question I posed earlier - *which class creates classes?*.
It turns out that `type` *is* a class used to create classes i.e. `type` is a **metaclass** (in fact, it is the go-to metaclass, which controls class construction unless specified otherwise).

### Metaclasses

Basically, metaclasses are classes that control class construction.
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

This example doesn't do much more than show that we can change the class construction process. 
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

Moving on to a less complicated but still very relevant topic: how iteration really works in Python.
A for-loop in Python, like the one below:

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

To sum up, when we execute a for-loop, an iterator is created out of our iterable, and the `__next__` method is called until we reach a `StopIteration`.

## 13. Generators

Taking things one step further, let's talk about generators.

A definition I find useful is that a generator is a **piece of computation which we can step through in a iterative manner**.
Basically, a generator allows us to **iterate through computation (code)**.

We can define a generator in a very similar way to a regular Python function.
However, we will use the `yield` key word to indicate where the generator should "halt" and, if we want, to determine what should the generator return at each step.
These functions are normally referred to as *generator functions*.

When we call the generator function, we instantiate a *generator object*.
A generator is an *iterator* and can be used as such.
See the example below:

```python
# generator function
def squares(n):
    for num in range(n):
        yield num ** 2

# creating our generator object
sqrs = squares(10)
print(sqrs)
# <generator object squares at ...>

# iteration
print(next(sqrs))
# 0
print(next(sqrs))
# 1

# with a for-loop
for num in sqrs:
    print(num)
# 4
# 9
# 16
# 25
# 36
# ...

# Notice that the generator object that we enter in the for-loop
# is the same we instantiated earlier and
# it "picks up" where we left it
```

The example above is not very useful, but it illustrates the basic usage of generators.

One of the main advantages of generators is that they allow us to build iterators with significantly smaller memory footprint than if we were to create a full data container e.g. a list.

In many cases we don't need to store all our data since we might only need it for some computation.
In such situations, using generators can help us save a lot of memory.
Let's compare the memory traces of the generator and non-generator approach in a simple example in which we sum the squares of the first one hundred thousand non-negative integers.

```python
import tracemalloc


tracemalloc.start()

sqrs_lst = [x ** 2 for x in range(100_000)]
result = sum(lst)
size, peak = tracemalloc.get_traced_memory()

print(size, peak)

tracemalloc.clear_traces()
tracemalloc.start()


def squares(n):
    for num in range(n):
        yield num ** 2


sqrs_gen = squares(10)
result = sum(sqrs_gen)
size, peak = tracemalloc.get_traced_memory()

print(size, peak)
```

You will likely see a **big** difference in memory usage.
In my case, using a list has a memory trace that's almost 400 times bigger than using a generator.

By the way, we can turn our beloved list comprehensions into *generator comprehensions* to save us some lines and be more Pythonic, so instead of our generator function above we could have simply written:

```python
sqrs_gen = (x ** 2 for x in range(100_000))
```

While the memory benefits from lazy evaluation are a key advantage of generators, this is just scratching the surface of what generators can do.

There are a bunch of resources to learn more about this topic.
David Beazley has a [trilogy](http://www.dabeaz.com/generators/) [of](http://www.dabeaz.com/coroutines/) [courses](http://www.dabeaz.com/finalgenerator/) on generators and coroutines, a related and even wilder concept, that I encourage you to check out!

## 14. Modules

Importing modules is the bread and butter of any non-trivial Python work, but what are modules exactly?
What happens when we import them?
What kinds of weird behavior may we encounter when doing so?

According to the official Python [documentation](https://docs.python.org/3/tutorial/modules.html):

> A module is a file containing Python definitions and statements

Let's go ahead and create a Python file like the one below, which we will name `user.py`:

```python
# user.py


print("Executing user module...")


DEFAULT_DOMAIN = "gmail.com"


class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age


def create_email(name, domain=DEFAULT_DOMAIN):
    return name.lower() + "@" + domain
```

We can then import this file from a different file or from an interactive session in the same directory with the well-known `import` syntax, for example:

```python
import user
# Executing user module...


print(type(user))
# <class 'module'>

name = "George"
email = user.create_email(name)
age = 22

usr = user.User(name, email, age)
```

What is exactly happening when we run `import user`?

First of all, Python needs to look for the module.
There is a whole process for this that I won't get into but that I recommend you [read about](https://docs.python.org/3/tutorial/modules.html#the-module-search-path).
Then, an object of type `module`, is created i.e. `user` in the example above.
The code in `user.py` gets executed **in its entirety**, as you can tell from that `print` statement.
The names of funtions, variables and classes defined in `user.py` get added to the *namespace* of the `user` module object.

As you probably know, we can also import specific definitions from a module via the `from <module> import <name>` syntax.
The module *also* gets executed in its entirety when we do this!
The only difference is that only the specified definitions get added to the current scope (and that the module itself is not added to the local namespace).

There is more: imported modules get ***cached***!
In other words, modules are imported only once.
Building on the example above, try the following from an interactive session:

```python
from user import User
# Executing user module...

import user
# you will not see the text 'Executing user module...' again!


name = "George"
email = user.create_email(name)
age = 22

usr = User(name, email, age)
```

What's happening under the hood is that the module is getting cached and added to `sys.modules` after the first import statement (feel free to import `sys` and check the `sys.modules` object yourself).
When we run the second import statement the module *is not* executed again - Python simply assigns the module to the name `user` in the local scope.

## 15. Packages

Packages are how we organize several modules in Python.
A package is basically a directory containing several modules, including an `__init__.py` module, and, potentially, sub-packages.

To better understand how packages work, try to create the following directory structure:

```
application/
├── __init__.py
├── item.py
└── user.py
```

For now, `__init__.py` will be an empty file.
The `user.py` and `item.py` modules look like this:

```python
# user.py


DEFAULT_DOMAIN = "gmail.com"


class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age


def create_email(name, domain=None):
    if domain is None:
        domain = DEFAULT_DOMAIN
    return name.lower() + "@" + domain
```

```python
# item.py


class Item:
    def __init__(self, name, quantity, category):
        self.name = name
        self.quantity = quantity
        self.category = category

```

From the same working directory, you can import the `user` and `item` modules from the `application` package.
Try the following from an interactive Python session:

```python
from application import user, item


print(user)
# <module 'application.user' from '.../application/user.py'>
print(item)
# <module 'application.item' from '.../application/item.py'>

print(user.__package__)
# application

usr = user.User("Joe", user.create_email("joe"), 42)

chair = item.Item("Chair", 20, "Furniture")
oven = item.Item("Oven", 4, "Kitchen")
```

As you can see, our package modules now have the special variable `__package__` set to `'application'` - the name of package where they are defined.

We can import `application` directly.
Importing a package is actually equivalent to importing the package's `__init__.py` module.

```python
import application


print(application)
# <module 'application' from '.../application/__init__.py'>

desk = application.item.Item("Desk", 10, "Furniture")
# you should get an
# AttributeError: module 'application' has no attribute 'item'
```

Note that we **cannot** access the package's submodules from the `application` object.
In the example above, `item` is not defined within the package's `__init__.py` module, which is what we are really importing.

We can change the `__init__.py` module to import the underlying submodules `user` and `item`.
It's important to notice that relative imports i.e. `import user` will **not** work in this case.
Instead, we need to import the `user` and `item` modules as follows:

```python
# application
# __init.__py


from . import user
from . import item
```

Now we can actually access the user and item modules as objects of the `application` "package" (aka the *special* `__init__.py` module)

```python
import application

print(application.user)
# <module 'application.user' from '.../application/user.py'>

desk = application.item.Item("Desk", 10, "Furniture")
# this should not raise any errors!
```

The `__init__.py` module can help us organize our code.
One example of this is the idea of **module splitting** and **assembly**.
We can break our code into multiple modules that we can make accessible from a top-level package directly thanks, precisely, to the `__init__.py` module.

We could rewrite our example from above as:

```python
# application
# __init.__py


from .user import User
from .item import Item
```

Even if the classes `User` and `Item` are defined in their respective modules, we can directly import them from the top-level package `application`.

```python
from application import User, Item


usr = User()
desk = Item("Desk", 10, "Furniture")
```

While this is a super simple example, you can see how module splitting can allow us to organize code into smaller files while making definitions accessible at a higher level.

There is obviously way more to say about packages, including the nightmare of circular imports and how to actually package your code into an installable Python package - but I will leave it here for now.

***

With this, I sign off on my Python blogging for some time.
My next posts will gravitate more towards interesting but fairly accessible Machine Learning and Data Science topics.
Stay tuned!



