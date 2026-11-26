"""Three ways Python expresses ad-hoc polymorphism.

Run with:  python3 code/python/describe_dispatch.py
"""

from functools import singledispatch
from typing import Protocol


# ANCHOR: protocol
class Describable(Protocol):
    def describe(self) -> str: ...
# ANCHOR_END: protocol


# ANCHOR: duck
def describe_duck(x) -> str:
    return x.describe()          # 签名里没有任何信息说明 x 必须是什么


# ANCHOR_END: duck


# ANCHOR: dispatch
@singledispatch
def describe(x) -> str:
    raise TypeError(f"no description for {type(x).__name__}")


@describe.register
def _(x: bool) -> str:
    return "true" if x else "false"


@describe.register
def _(x: list) -> str:
    return "[" + ", ".join(describe(v) for v in x) + "]"


# ANCHOR_END: dispatch


class WithDescribe:
    def describe(self) -> str:
        return "ok"


class WithoutDescribe:
    pass


print(describe(True))
print(describe([True, False]))

try:
    describe(3)
except TypeError as exc:
    print(f"{type(exc).__name__}: {exc}")

print(describe_duck(WithDescribe()))

try:
    describe_duck(WithoutDescribe())
except AttributeError as exc:
    print(f"{type(exc).__name__}: {exc}")
