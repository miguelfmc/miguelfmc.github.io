---
layout: default
title: "A Few Crazy Python Things (Part III)"
theme: jekyll-theme-slate
---

# A Few Crazy Python Things (Part III)

I guess I couldn't leave my blogging about weird Python magic to [just]() two [parts]().

This is, I promise, the third and final post in which I humbly write about some Python features that I find equal parts powerful and mindblowing.
Let's dive in.

## 11. Metaclasses

Metaclasses are probably the most mind-bending feature of Python that I've encountered recently.

To properly understand metaclasses, we might need to take a step back and think about what classes are in Python.
An insightful definition is the following:

A `class` is a *callable* that creates **instances**

If classes are also objects (and everything is an object in Python) - which `class` is responsible for *creating* classes?

### Class definition: another way

Python offers, in many situations, two ways of doing things: one ... and another ... .

We are familiar with the standard class definition syntax

```python
class MyClass:
    def __init__(self, name):
        self.name = name
```

But classes can also be created via a call to `type`.
Thus, the code above is actually equivalent to:

```python
MyClass = type()
```

This sheds some light on the question I posed earlier and takes us straight into the topic of metaclasses.

### Metaclasses, more in-depth

...

## 12. Iteration, under the hood

...

## 13. Generators and coroutines

...

## 14. Modules

...

## 15. Circular imports

...

***

And with this, I sign off on my Python blogging for some time.
My next posts will gravitate more towards nteresting but fairly accessible Machine Learning and Data Science topics.
Stay tuned!



