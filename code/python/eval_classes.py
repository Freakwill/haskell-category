"""The tuple-with-tag representation replaced by a class hierarchy.

Run with:  python3 code/python/eval_classes.py
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass


# ANCHOR: classes
class Expr(ABC):
    @abstractmethod
    def eval(self) -> int: ...


@dataclass
class Lit(Expr):
    value: int

    def eval(self) -> int:
        return self.value


@dataclass
class Add(Expr):
    left: Expr
    right: Expr

    def eval(self) -> int:
        return self.left.eval() + self.right.eval()


@dataclass
class Neg(Expr):
    operand: Expr

    def eval(self) -> int:
        return -self.operand.eval()
# ANCHOR_END: classes


print(Add(Lit(1), Neg(Add(Lit(2), Lit(3)))).eval())        # -4

try:
    Lit(1, 2)  # type: ignore[call-arg]  # intentional: wrong arity
except TypeError as exc:
    print(f"{type(exc).__name__}: {exc}")


class Mod(Expr):            # a case the evaluator has never seen
    def eval(self) -> int:
        return 0


print(Mod().eval())         # 0: no warning, no error, no one notices
