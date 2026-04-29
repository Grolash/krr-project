hollow(X, Y, Z):- length(L), X = 2..L-2, height(H), Y = 2..H, depth(D), Z = 2..D-2.
cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D, not hollow(X, Y, Z).

total_pieces(N):- #sum{X :  pick_times(Id, X) } = N, Id = 0..250.

1 {piece(I, S) : S = 4..8} 1:- id(I).
:- piece(I, S), piece(I, T), S != T.

S {placed(I, X, Y, Z) : cell(X, Y, Z)} S:- piece(I, S).
:- placed(I, X, Y, Z), placed(J, X, Y, Z), I != J.
covered(X, Y, Z):- placed(I, X, Y, Z).
:- cell(X, Y, Z), not covered(X, Y, Z).


ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2, Z1 = Z2 + 1.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2 + 1, Z1 = Z2.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2 + 1, Y1 = Y2, Z1 = Z2.

:- placed(I, X, Y, Z), placed(I, A, B, C), not path(X, Y, Z, A, B, C).

mirror(0, X, Y, Z):- placed(X, Y, Z).
% x-axis mirror redundant, can be obtained from mirror about y-axis and rotation about z-axis
mirror(1, NewX, Y, Z):- placed(X, Y, Z), NewX = -X. % y-axis
% z-axis mirror redundant, can be obtained from mirror about y-axis and rotation about x-axis


rotate(0, M, X, Y, Z):- mirror(M, X, Y, Z).
rotate(A, M, X, NewY, NewZ):- rotate(A-1, M, X, Y, Z), NewY = -Z, NewZ = Y, A = 1..3. % x-axis
% y-axis rotation redundant, can be obtained from rotate about x-axis and z-axis
rotate(4, M, NewX, NewY, Z):- rotate(0, M, X, Y, Z), NewX = -Y, NewY = X. % z-axis with A = 0 from rotate 0
rotate(4 + A, M, NewX, NewY, Z):- rotate(A-1, M, X, Y, Z), NewX = -Y, NewY = X, A = 1..2. % z-axis inductively


#show piece/2.
#show placed/4.