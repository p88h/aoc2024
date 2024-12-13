import numpy as np;
import re;

def day13(s, *, part2=False):
  values = np.array(
      [[re.findall(r'\d+', line) for line in s2.splitlines()] for s2 in s.split('\n\n')], int
  )
  b = values[:, 2][..., None] + (10_000_000_000_000 if part2 else 0)
  matrix = np.moveaxis(values[:, :2], 1, 2)
  x = np.linalg.solve(matrix, b)
  rounded = (x + 0.5).astype(int)
  solved = (matrix @ rounded == b).all(1)[:, 0]
  return np.sum(rounded[solved][..., 0] @ [3, 1])

s = open("input/day13.txt").read()
print(day13(s))
print(day13(s, part2=True))


###
a * x1 + b * x2 = x3 / * y2
a * y1 + b * y2 = y3 / * x2

a * x1 * y2 + b * x2 * y2 = x3 * y2
a * y1 * x2 + b * y2 * x2 = y3 * x2 / --
a * x1 * y2 - a * y1 * x2 = x3 * y2 - y3 * x2
a * (x1 * y2 - y1 * x2) = x3 * y2 - y3 * x2
a = (x3 * y2 - y3 * x2) / (x1 * y2 - y1 * x2)
b = (x3 - a * x1) / x2

