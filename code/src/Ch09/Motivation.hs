-- | Chapter 9: the same pipeline in three effects, written by hand first,
-- then unified by the shape @m a -> (a -> m b) -> m b@.
module Ch09.Motivation
    ( Table
    , personTable
    , checkRange
    , pipelineManual
    , pipelineBind
    , chooseManual
    , chooseBind
    , step
    , threadManual
    ) where

-- | A name-to-age lookup table.
type Table = [(String, Int)]

personTable :: Table
personTable = [("ann", 34), ("cy", 7), ("dee", 190)]

-- | Reject ages outside [0, 150].
checkRange :: Int -> Maybe Int
checkRange n
    | n < 0 || n > 150 = Nothing
    | otherwise        = Just n

-- ANCHOR: maybe-manual
-- | Look up an age, then check the range, with a nested case for every step.
pipelineManual :: Table -> String -> Maybe Int
pipelineManual t name =
    case lookup name t of
        Nothing  -> Nothing
        Just n   -> case checkRange n of
            Nothing -> Nothing
            Just m  -> Just (m + 1)
-- ANCHOR_END: maybe-manual

-- ANCHOR: maybe-bind
-- | The same pipeline with (>>=): each case is one line, failure is implicit.
pipelineBind :: Table -> String -> Maybe Int
pipelineBind t name =
    lookup name t >>= \n ->
    checkRange n >>= \m ->
    Just (m + 1)
-- ANCHOR_END: maybe-bind

-- ANCHOR: list-manual
-- | All pairs summing to 10, via nested concatMap.
chooseManual :: [Int] -> [(Int, Int)]
chooseManual xs =
    concatMap (\x ->
        concatMap (\y ->
            if x + y == 10 then [(x, y)] else []) xs) xs
-- ANCHOR_END: list-manual

-- ANCHOR: list-bind
-- | The same search via (>>=): the nesting disappears.
chooseBind :: [Int] -> [(Int, Int)]
chooseBind xs =
    xs >>= \x ->
    xs >>= \y ->
    if x + y == 10 then [(x, y)] else []
-- ANCHOR_END: list-bind

-- ANCHOR: state-manual
-- | A counter step, as a function @s -> (a, s)@: take a state, give back
-- a value and the new state.
step :: Int -> (String, Int)
step n = ("v", n + 1)

-- | Two steps, threading the counter by hand.
threadManual :: Int -> (String, Int)
threadManual n =
    let (a, n1) = step n
        (b, n2) = step n1
    in (a ++ b, n2)
-- ANCHOR_END: state-manual
