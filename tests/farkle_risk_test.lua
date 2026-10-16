local D=require('src.features.farkle.dice')
-- Remaining bust counts are permutations of (2,2,1,1) over {2,3,4,6}:
-- C(4,2) * 6!/(2!*2!) = 6 * 180 = 1080 ordered throws.
assert(math.abs(D.risk('normal',{1,2,3,4,5,6})-1080/46656)<1e-12,'three pairs must be excluded from theoretical Farkle')
print('PASS six-die theoretical Farkle excludes three pairs')
