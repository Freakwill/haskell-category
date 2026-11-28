-- | Chapter 13: linear regression -- least squares, gradient descent and
-- their agreement.
module Ch13.Regression
    ( mse
    , gradMse
    , descend
    , ols
    , lrDemo
    ) where

-- ANCHOR: mse
-- | Mean squared error of the line y = a + b x over the points.
mse :: (Double, Double) -> [(Double, Double)] -> Double
mse (a, b) pts =
    sum [ (y - (a + b * x)) ^ (2 :: Int) | (x, y) <- pts ]
        / fromIntegral (length pts)

-- | Gradient of the mean squared error with respect to (a, b).
gradMse :: [(Double, Double)] -> (Double, Double) -> (Double, Double)
gradMse pts (a, b) =
    ( sum [ -2 * (y - (a + b * x)) / fromIntegral (length pts) | (x, y) <- pts ]
    , sum [ -2 * x * (y - (a + b * x)) / fromIntegral (length pts) | (x, y) <- pts ]
    )
-- ANCHOR_END: mse

-- ANCHOR: descend
-- | One gradient descent step with learning rate lr.
step :: Double -> [(Double, Double)] -> (Double, Double) -> (Double, Double)
step lr pts (a, b) =
    let (ga, gb) = gradMse pts (a, b)
    in (a - lr * ga, b - lr * gb)

-- | Iterate gradient descent from (a0, b0) and return the path.
descend :: Double -> [(Double, Double)] -> (Double, Double) -> [(Double, Double)]
descend lr pts p0 = iterate (step lr pts) p0
-- ANCHOR_END: descend

-- ANCHOR: ols
-- | Closed form: b = Sxy / Sxx, a = ybar - b * xbar.
ols :: [(Double, Double)] -> (Double, Double)
ols pts =
    let n = fromIntegral (length pts)
        xbar = sum [ x | (x, _) <- pts ] / n
        ybar = sum [ y | (_, y) <- pts ] / n
        sxy = sum [ (x - xbar) * (y - ybar) | (x, y) <- pts ]
        sxx = sum [ (x - xbar) ^ (2 :: Int) | (x, _) <- pts ]
        b = sxy / sxx
        a = ybar - b * xbar
    in (a, b)

-- | Points on the line y = 1 + 2x with no noise: descent must find
-- (a, b) = (1, 2) exactly in the limit, and ols finds it at once.
lrDemo :: [(Double, Double)]
lrDemo = [(x, 1 + 2 * x) | x <- [0 .. 5]]
-- ANCHOR_END: ols
