"""Chapter 8: the two pairing semantics, in Python.

List applicative = cartesian product (itertools.product).
ZipList applicative = zip, truncated to the shorter input.
zip_longest pads the shorter input instead of truncating.
"""

# ANCHOR: zip-vs-product
from itertools import product, zip_longest

# 列表的「应用函子」语义：笛卡尔积
print(list(product([1, 2], ['a', 'b'])))

# zip：截断到较短的那个
print(list(zip([1, 2, 3], "ab")))

# zip_longest：把缺的补成 None，而不是截断
print(list(zip_longest([1, 2, 3], "ab")))
# ANCHOR_END: zip-vs-product
