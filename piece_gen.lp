size(5).
depth(X):- size(S), X=S/2.
height(X):- size(S), X=S/2.
length(X):- size(S), X=S/2.
cell(X, Y, Z):- length(L), X=-L..L, height(H), Y=-H..H, depth(D), Z=-D..D.

S { placed(X, Y, Z) : cell(X, Y, Z) } S:- size(S).
:- cell(0, 0, 0), not placed(0, 0, 0).

ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2, Z1 = Z2 + 1.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2 + 1, Z1 = Z2.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2 + 1, Y1 = Y2, Z1 = Z2.

path(X1, Y1, Z1, X2, Y2, Z2):- placed(X1, Y1, Z1), placed(X2, Y2, Z2), ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2).
path(X1, Y1, Z1, X2, Y2, Z2):- placed(X1, Y1, Z1), placed(X2, Y2, Z2), ortho_adjacent(X2, Y2, Z2, X1, Y1, Z1).
path(X1, Y1, Z1, X2, Y2, Z2):- path(X1, Y1, Z1, A, B, C), path(A, B, C, X2, Y2, Z2).

:- placed(A, B, C), placed(X, Y, Z), not path(A, B, C, X, Y, Z).

% removing planar polycubes
interesting(1):- placed(X, Y, Z), placed(X_prime, Y, Z), X != X_prime.
interesting(2):- placed(X, Y, Z), placed(X, Y_prime, Z), Y != Y_prime.
interesting(3):- placed(X, Y, Z), placed(X, Y, Z_prime), Z != Z_prime.
:- not interesting(1).
:- not interesting(2).
:- not interesting(3).

% removing duplicate pieces with lex-leader

mirror(0, X, Y, Z):- placed(X, Y, Z).
mirror(1, X, NewY, Z):- placed(X, Y, Z), NewY = -Y. % x-axis
mirror(2, NewX, Y, Z):- placed(X, Y, Z), NewX = -X. % y-axis
mirror(3, X, Y, NewZ):- placed(X, Y, Z), NewZ = -Z. % z-axis

rotate(0, M, X, Y, Z):- mirror(M, X, Y, Z).

rotate(A, M, X, NewY, NewZ):- rotate(A-1, M, X, Y, Z), NewY = -Z, NewZ = Y, A = 1..3. % x-axis

rotate(4, M, NewX, Y, NewZ):- rotate(0, M, X, Y, Z), NewX = Z, NewZ = -X. % y-axis
rotate(A, M, NewX, Y, NewZ):- rotate(A-1, M, X, Y, Z), NewX = Z, NewZ = -X, A = 5..6. % y-axis

rotate(7, M, NewX, NewY, Z):- rotate(0, M, X, Y, Z), NewX = -Y, NewY = X. % z-axis
rotate(A, M, NewX, NewY, Z):- rotate(A-1, M, X, Y, Z), NewX = -Y, NewY = X, A = 8..9. % z-axis



#show placed/3.