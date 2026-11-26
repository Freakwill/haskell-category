"""第 1 章的 Python 对照：同一棵表达式树，用抽象基类 + 方法派发写。

Run: python3 code/python/eval_oop.py
The asserts at the bottom are the book's claim that this file runs.
"""

from abc import ABC, abstractmethod


class Node(ABC):
    @abstractmethod
    def eval(self) -> int: ...

class Lit(Node):
    def __init__(self, n: int) -> None: self.n = n

    def eval(self) -> int:
        return self.n

class Add(Node):
    def __init__(self, a: Node, b: Node) -> None: self.a, self.b = a, b

    def eval(self) -> int:
        return self.a.eval() + self.b.eval()

class Mul(Node):
    def __init__(self, a: Node, b: Node) -> None: self.a, self.b = a, b

    def eval(self) -> int:
        return self.a.eval() * self.b.eval()

class Neg(Node):
    def __init__(self, a: Node) -> None: self.a = a

    def eval(self) -> int:
        return -self.a.eval()

# 新增一种节点：只写这一个类，别处一行不用改。
class Div(Node):
    def __init__(self, a: Node, b: Node) -> None: self.a, self.b = a, b

    def eval(self) -> int:
        return self.a.eval() // self.b.eval()


if __name__ == "__main__":
    expr = Mul(Lit(6), Add(Lit(2), Lit(3)))
    assert expr.eval() == 30
    assert Div(Lit(7), Lit(2)).eval() == 3
    print(expr.eval())

    # 少实现一个抽象方法：实例化时就报错，而不是等到调用时。
    class Broken(Node):
        pass

    try:
        Broken()  # type: ignore[abstract]
    except TypeError as err:
        print(f"TypeError: {err}")
