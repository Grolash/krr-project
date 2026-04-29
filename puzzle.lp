hollow(X, Y, Z):- length(L), X = 2..L-2, height(H), Y = 2..H, depth(D), Z = 2..D-2.
cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D, not hollow(X, Y, Z).


{id(I)}:- I = 0..250.
1 {piece(I, S) : S = 4..8} 1:- id(I).
:- piece(I, S), piece(I, T), S != T.

S {placed(I, X, Y, Z) : cell(X, Y, Z)} S:- piece(I, S).
:- placed(I, X, Y, Z), placed(J, X, Y, Z), I != J.
covered(X, Y, Z):- placed(I, X, Y, Z).
:- cell(X, Y, Z), not covered(X, Y, Z).


ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2, Z1 = Z2 + 1.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2 + 1, Z1 = Z2.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2 + 1, Y1 = Y2, Z1 = Z2.

path(X1, Y1, Z1, X2, Y2, Z2):- placed(I, X1, Y1, Z1), placed(I, X2, Y2, Z2), ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2).
path(X1, Y1, Z1, X2, Y2, Z2):- placed(I, X1, Y1, Z1), placed(I, X2, Y2, Z2), ortho_adjacent(X2, Y2, Z2, X1, Y1, Z1).
path(X1, Y1, Z1, X2, Y2, Z2):- path(X1, Y1, Z1, A, B, C), path(A, B, C, X2, Y2, Z2).

:- placed(I, X, Y, Z), placed(I, A, B, C), not path(X, Y, Z, A, B, C).

#show piece/2.
#show placed/4.