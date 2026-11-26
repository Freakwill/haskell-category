"""第 1 章的 Python 对照（第一种写法）：节点是哑的，一个函数用 isinstance 认形状。

Run: python3 code/python/eval_naive.py
"""

class Lit:
    def __init__(self, n: int) -> None:
        self.n = n

class Add:
    def __init__(self, a, b) -> None:
        self.a, self.b = a, b

class Mul:
    def __init__(self, a, b) -> None:
        self.a, self.b = a, b

class Neg:
    def __init__(self, a) -> None:
        self.a = a

def evaluate(e) -> int:
    if isinstance(e, Lit): return e.n
    if isinstance(e, Add): return evaluate(e.a) + evaluate(e.b)
    if isinstance(e, Mul): return evaluate(e.a) * evaluate(e.b)
    if isinstance(e, Neg): return -evaluate(e.a)
    raise TypeError(f"unknown expression: {e!r}")

if __name__ == "__main__":
    assert evaluate(Mul(Lit(6), Add(Lit(2), Lit(3)))) == 30
    print(evaluate(Mul(Lit(6), Add(Lit(2), Lit(3)))))
