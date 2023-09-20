---
layout: default
title: "A Few Crazy Python Things (Part I)"
theme: jekyll-theme-slate
---

# A Few Crazy Python Things (Part I)

I recently completed **David Beazley**'s [Python Mastery](https://github.com/dabeaz-course/python-mastery) course.
I learned *a lot* and my mind was blown several times in the process.
I thought I knew Python - I now realize I was only scratching the surface.

Here are a few of my take-aways from David's course as well as some of my favorite (and, at times, brain-melting) Python tidbits that you might not know about.

PS: There will be a part two just because there are too many things I wanted to fit into one single post

## 1. Memory

This one might seem obvious for someone with a proper Computer Science background, but it was a bit of a surprise to me.
Different Python containers have varying degrees of **memory** overhead.
I'm not referring to the data stored in the containers, I mean the data structures *themselves*.

Python dictionaries, for example, require a significant amount of memory.
You can see this for yourself by checking the size of an empty dictionary with `sys.getsizeof()`.

An empty dictionary requires some minimum memory, which in most systems is 240 bytes.
As we add more elements to it, extra memory gets allocated (by the way, this dynamic allocation also takes place with other containers, such as lists).

```python
import sys


my_dict = {}

print(sys.getsizeof(my_dict))
# you should see probably 240 (bytes)
# for some reason I get 248 in my system

my_dict["a"] = 1
my_dict["b"] = 2
my_dict["c"] = 3

print(sys.getsizeof(my_dict))
# you should still see the same result as above

my_dict["d"] = 4
my_dict["e"] = 5
my_dict["f"] = 6

print(sys.getsizeof(my_dict))
# the size of the dictionary should increase now that
# we have more than 5 keys
```

Compare this with the size of a `namedtuple` or of an instance of a class with `__slots__` (more details on `__slots__` later).

```python
import sys
from collections import namedtuple


MyTuple = namedtuple("MyTuple", ("a", "b", "c"))
my_tup = MyTuple(1, 2, 3)

print(sys.getsizeof(my_tup))
# 80 bytes


class MyClass:
    __slots__ = ("a", "b", "c")
    def __init__(self, a, b, c):
        self.a = a
        self.b = b
        self.c = c


my_obj = MyClass(1, 2, 3)

print(sys.getsizeof(my_obj))
# 64 bytes
```

While 240 bytes might not sound like a lot, think about the memory overhead of loading several thousand CSV rows, each as one separate dictionary.

I still need to investigate exactly *why* dictionaries require that much memory while other data structures don't.
From what I understand, Python allocates an initial set of memory slots when you initialize a dictionary.

For more info on this topic, this [post](https://lerner.co.il/2019/05/12/python-dicts-and-memory-usage/) seems to cover it pretty well.


## 2. `__slots__`

Most of us Python beginners are familiar with  standard class definition, and attribute setting/getting.
A very basic example:

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age
```

That said, it's possible to define a class with a special `__slots__` class variable, as I briefly showed in the section on dictionaries and memory above.
`__slots__` allows us to **pre-specify** which attributes the instances of this class will have, via a tuple of strings.
This leads to significant memory savings.

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age


class SlottedUser:
    __slots__ = ("name", "email", "age")
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age


user = User("John Doe", "john@doe.com", 23)
suser = SlottedUser("John Doe", "john@doe.com", 23)
```

On top of that, "slotted" classes prevent the creation of attributes that aren't defined on `__slots__`.
Using the example above:

```python
# we can easily do this
user.city = "San Francisco"

# but we can't do this
suser.city = "San Francisco"
# you should get an AttributeError
```

For a deeper dive into the inner workings of `__slots__` and how "slotted" classes differ from your standard classes, check out this [mCoding video](https://www.youtube.com/watch?v=Iwf17zsDAnY).


## 3. Dictionaries everywhere

It turns out that Python uses the dictionary data structure for many, many things.

One key use-case, which relates to the `__slots__` example above, is in classes and instances.
Instances of a class have a `__dict__` attribute which stores the object's attributes.
Importantly, if a class defines a `__slots__` variable, its instances **will not** have this `__dict__` attribute.

Similarly, a **class** (not its instances) has its own `__dict__` attribute which stores methods and class attributes.

We can actually access and modify the contents of these variables as we like.

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

    def greet(self):
        print(f"Hi, my name is {self.name}")


user = User("John Doe", "john@doe.com", 23)

# take a look at the object's __dict__
print(user.__dict__)

# setting an attribute
user.__dict__["city"] = "San Francisco"

# we can now access it
print(user.__dict__["city"])
print(user.city)

# now look at the class __dict__
print(User.__dict__)
```

Attribute and method look-up basically rely on these dictionaries, as well as on some Python magic known as the **descriptor protocol**, which I will talk about later.
In other words, and simplifying quite a bit, when we look up an object's attribute,  Python will look in the object's `__dict__`.
If it can't be found there, it will use the class' `__dict__`.


## 4. Inheritance, the MRO and `super()`

**Inheritance** is a well-known concept in object-oriented programming.
In plain words, inheritance refers to the process of creating classes based on existing classes, so that the "child" class keeps most or all of the parent's functionality.

In Python, we can inherit from an existing class as follows:

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

    def greet(self):
        print(f"Hi, my name is {self.name}")


class PremiumUser(User):
    def greet(self):
        print(f"Hi, my name is {self.name} and I'm a premium user!")


mike = User("Mike", "mike@mail.com", 30)
john = PremiumUser("John", "john@mail.com", 32)

mike.greet()
# Hi, my name is Mike

john.greet()
# Hi, my name is John and I'm a premium user!
```

In the example above, we override the `greet()` method, but our child class keeps the `__init__` method from the parent.

Normally, we use `super()` in a class' method to call the method from the superclass. We can rewrite the previous example as follows:

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

    def greet(self):
        print(f"Hi, my name is {self.name}")


class PremiumUser(User):
    def greet(self):
        super().greet()
        print(f"...and I'm also a premium user!")


mike = User("Mike", "mike@mail.com", 30)
john = PremiumUser("John", "john@mail.com", 32)

mike.greet()
# Hi, my name is Mike

john.greet()
# Hi, my name is John
# ...and I'm also a premium user!
```

You can experiment to see what happens if you don't include the `super().greet()` statement in the subclass' method (or if you place it after the print statement).

This is reasonably easy to grasp - so far so good.
Something a bit more interesting happens when using **multiple inheritance**, that is, when we define a class with more than one parent.

Let's take a look at the following example, in which we define a few "user" classes, one of which inherits from multiple parents.

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

    def greet(self):
        print(f"Hi, my name is {self.name}")


class PremiumUser(User):
    def greet(self):
        super().greet()
        print(f"...and I'm also a premium user!")


class BusinessUser(User):
    def greet(self):
        super().greet()
        print("This is a business account")


class BusinessPremiumUser(PremiumUser, BusinessUser):
    def greet(self):
        super().greet()


user = BusinessPremiumUser("Johnny's Cafe", "johnny@cafe.com", 45)

user.greet()
# what do you expect to see printed out???
```

We might (reasonably) expect the `super` statement in `BusinessPremiumUser.greet()` to call the first parent's method i.e. `PremiumUser.greet()`.
Then, when we call `super().greet()` from `PremiumUser.greet()` we might expect it to call its parent's method i.e. `User.greet()`.
Where does that leave `BusinessUser`, though?

Watch what actually happens when we call `greet()` from an instance of `BusinessPremiumUser`.
We see the following text printed out, in this order:

1. The message from `User.greet()` i.e. "Hi, my name is Johnny's Cafe"
2. The message from ` BusinessUser.greet()` i.e. "This is a business account"
3. The message from `PremiumUser.greet()` i.e. "...and I'm also a premium user!"

What is `super()` *really* doing here?

The key insight is that the `super().greet()` call from `PremiumUser.greet()` **does not** call `User.greet()` but instead `BusinessUser.greet()`.
We are going *sideways*, following this order:

    BusinessPremiumUser -> PremiumUser -> BusinessUser -> User

Since we placed the `super()` calls as the first statement within the method body, things might look a bit confusing.
Experiment swapping the print statement with the `super().greet()` statement. You should see something like this, which shows more clearly the hierarchy above:

    ...and I'm also a premium user!
    This is a business account
    Hi, my name is Johnny's Cafe

To understand all of this, let me introduce the concept of the **method resolution order** or **MRO**.
The MRO of a class defines the order in which its methods or attributes should be looked-up in its superclasses.

What `super()` does is **delegate** to the next class in the MRO, and this can lead to unintuitive behavior, like we just saw.

How is the MRO constructed?
Put very crudely, it's a "bottom-to-top, left-to-right" structure, and follows these rules:

* **Children go before parents**
    * If several classes share a parent, they should *all appear before the parent* in the MRO. This is what happens in our example, since `PremiumUser` and `BusinessUser` both inherit from `User`
* **Parents go in order**

You can check out a class' MRO through its `__mro__` attribute:

```python
print(BusinessPremiumUser.__mro__)
# (<class '__main__.BusinessPremiumUser'>, <class '__main__.PremiumUser'>, <class '__main__.BusinessUser'>, <class '__main__.User'>, <class 'object'>)
# this matches the behavior we saw earlier!
```

Imagine now that instead of a `BusinessUser` class we have a `Business` class that doesn't inherit from `User`.
Look at how things would change:

```python
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

    def greet(self):
        print(f"Hi, my name is {self.name}")


class PremiumUser(User):
    def greet(self):
        super().greet()
        print(f"...and I'm also a premium user!")


class Business:
    def greet(self):
        print("This is a business account")


class BusinessPremiumUser(PremiumUser, Business):
    def greet(self):
        super().greet()


user = BusinessPremiumUser("Johnny's Cafe", "johnny@cafe.com", 45)

user.greet()
# Hi, my name is Johnny's Cafe
# ...and I'm a premium user!
```

The MRO in this case is:

```python
print(BusinessPremiumUser.__mro__)
# (<class '__main__.BusinessPremiumUser'>, <class '__main__.PremiumUser'>, <class '__main__.User'>, <class '__main__.Business'>, <class 'object'>)
```

In this case, the `greet()` method from the `Business` class is not getting called.
For that to happen, we would need a `super()` statement in the `User.greet()` method, but would that make sense?
This shows not only how *sneaky* multiple inheritance is, but the importance of *properly desigining* your classes when working with it.

Things can get even trickier with multiple inheritance and the MRO, and my explanations are pretty crude.
For more details, check out yet another [video](https://www.youtube.com/watch?v=X1PQ7zzltz4&pp=ygUNbWNvZGluZyBzdXBlcg%3D%3D) from mCoding.

## 5. Descriptors

This one is complicated, and I'm not sure I'm fully qualified to explain it, but here we go.

A **descriptor** is any object with `__set__`, `__get__` and/or `__delete__` methods.
These methods get called when the **descriptor** object gets accessed, set or deleted via the standard attribute getting, setting and deleting syntax, respectively.

Let's say we have an object `my_obj`, that has an attribute `a`, which is a descriptor.
In such a case:

* `a.__get__()` gets called when performing attribute getting i.e. `my_obj.a`
* `a.__set__()` gets called when performing attrbiute setting i.e. `my_obj.a = 23`

We can actually code this up to better understand what's going on.
The example below tries to recreate what happens with your vanilla attribute getting and setting, while adding some print statements.

```python
class Descriptor:
    def __init__(self, name):
        self.name = name

    def __get__(self, obj, objtype=None):
        print("In __get__")
        return obj.__dict__[self.name]
        
    def __set__(self, obj, value):
        print("In __set__")
        obj.__dict__[self.name] = value


class MyClass:
    a = Descriptor("a")

    def __init__(self, a):
        self.a = a


my_obj = MyClass(42)
# In __set__
print(my_obj.a)
# In __get__
# 42
my_obj.a = 13
# In __set__
```

Keep in mind that the **attribute itself is the descriptor**.
Its methods are called passing them `self` (the descriptor object) plus `instance` (the object to which they "belong").
For this reason, some people refer to descriptors and the descriptor protocol as *owning the dot*.

It turns out that a lot of everyday Python objects *are* descriptors: properties, instance methods, class methods, etc.

Why might we want to implement our own descriptor?
Quite honestly, I don't really know.
But David Beazley gives the example of **data validation** in attribute setting as a potential use-case.
Rewriting the example above:

```python
class IntegerDescriptor:
    def __init__(self, name):
         self.name = name

    def __get__(self, obj, objtype=None):
        print("In __get__")
        return obj.__dict__[self.name]

    def __set__(self, obj, value):
        """Check that value is of the right type i.e. integer"""
        print("In __set__")
        if isinstance(value, int):
            obj.__dict__[self.name] = value
        else:
            raise TypeError("Value should be int!")

my_obj = MyClass(42)
# In __set__
my_obj.a = 4.2
# In __set__
# ...
# TypeError: Value should be int!
```

If you want to know more, the [Descriptor HowToGuide](https://docs.python.org/3/howto/descriptor.html#simple-example-a-descriptor-that-returns-a-constant) provides some helpful info on all things descriptors.