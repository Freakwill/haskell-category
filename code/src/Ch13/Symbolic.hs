-- | Chapter 13: symbolic computation -- an expression ADT with evaluation,
-- simplification and differentiation.
module Ch13.Symbolic
    ( Expr (..)
    , eval
    , simplify
    , deriv
    , exprDemo
    , derivDemo
    ) where

-- ANCHOR: expr
-- | Polynomial-like expressions with one variable.
data Expr
    = Var String
    | Lit Double
    | Add Expr Expr
    | Mul Expr Expr
    deriving (Eq, Show)

-- | Evaluate an expression under an environment.
eval :: [(String, Double)] -> Expr -> Double
eval env e =
    case e of
        Var s   -> maybe (error "unbound variable") id (lookup s env)
        Lit d   -> d
        Add a b -> eval env a + eval env b
        Mul a b -> eval env a * eval env b
-- ANCHOR_END: expr

-- ANCHOR: simplify
-- | Fold constants and apply the identities 0 + x = x, 0 * x = 0, 1 * x = x.
-- Not a full normal form: distribution and like-term collection are left out.
simplify :: Expr -> Expr
simplify (Add a b) =
    case (simplify a, simplify b) of
        (Lit 0, y)  -> y
        (x, Lit 0)  -> x
        (Lit x, Lit y) -> Lit (x + y)
        (x, y)      -> Add x y
simplify (Mul a b) =
    case (simplify a, simplify b) of
        (Lit 0, _)  -> Lit 0
        (_, Lit 0)  -> Lit 0
        (Lit 1, y)  -> y
        (x, Lit 1)  -> x
        (Lit x, Lit y) -> Lit (x * y)
        (x, y)      -> Mul x y
simplify e = e
-- ANCHOR_END: simplify

-- ANCHOR: deriv
-- | Symbolic derivative with respect to a variable.
deriv :: String -> Expr -> Expr
deriv v (Var s)
    | s == v    = Lit 1
    | otherwise = Lit 0
deriv _ (Lit _)   = Lit 0
deriv v (Add a b) = Add (deriv v a) (deriv v b)
deriv v (Mul a b) =
    Add (Mul (deriv v a) b) (Mul a (deriv v b))
-- ANCHOR_END: deriv

-- | x^2 + 3x + 2, written out.
exprDemo :: Expr
exprDemo = Add (Mul (Var "x") (Var "x")) (Add (Mul (Lit 3) (Var "x")) (Lit 2))

-- | Its derivative, simplified: x + x + 3.
derivDemo :: Expr
derivDemo = simplify (deriv "x" exprDemo)
