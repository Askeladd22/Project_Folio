"""Exact capped-count DP: four sessions banking only the first four-die roll."""
from collections import defaultdict
from fractions import Fraction

# Both folios have one repeated pigment and four single pigments; one is unused.
goal = (2, 1, 1, 1, 1)
states = {(0, 0, 0, 0, 0): 1}
for _ in range(16):
    following = defaultdict(int)
    for state, multiplicity in states.items():
        for color in range(6):
            new = list(state)
            if color < 5:
                new[color] = min(goal[color], new[color] + 1)
            following[tuple(new)] += multiplicity
    states = following
result = Fraction(states[goal], 6 ** 16)
assert result == Fraction(3888316705, 6530347008)
print(f'Bank-only baseline, one folio in four sessions: {result} = {float(result):.9%}')
print('Exact independent uniform-die model, not physical samples or a simulation of player behavior.')
