hollow(X, Y, Z):- length(L), X = 2..L-2, height(H), Y = 2..H, depth(D), Z = 2..D-2.
cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D, not hollow(X, Y, Z).

mirror(0, X, Y, Z, P):- piece(X, Y, Z, P).
% x-axis mirror redundant, can be obtained from mirror about y-axis and rotation about z-axis
mirror(1, NewX, Y, Z, P):- piece(X, Y, Z, P), NewX = -X. % y-axis
% z-axis mirror redundant, can be obtained from mirror about y-axis and rotation about x-axis

rotate(0, M, X, Y, Z, P):- mirror(M, X, Y, Z, P).
rotate(A, M, X, NewY, NewZ, P):- rotate(A-1, M, X, Y, Z, P), NewY = -Z, NewZ = Y, A = 1..3. % x-axis
% y-axis rotation redundant, can be obtained from rotate about x-axis and z-axis
rotate(4, M, NewX, NewY, Z, P):- rotate(0, M, X, Y, Z, P), NewX = -Y, NewY = X. % z-axis with A = 0 from rotate 0
rotate(4 + A, M, NewX, NewY, Z, P):- rotate(A-1, M, X, Y, Z, P), NewX = -Y, NewY = X, A = 1..2. % z-axis inductively

{ block(Bid, Pid, R, X, Y, Z) : cell(X, Y, Z), rotate(R, M, 0, 0, 0, Pid) }:- Bid = 0..N, total_blocks(N).
correct_picks(Pid):- #sum{Bid : block(Bid, Pid, R, X, Y, Z)} = S, pick_times(Pid, S).
:- not correct_picks(Pid).

ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2, Z1 = Z2 + 1.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2 + 1, Z1 = Z2.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2 + 1, Y1 = Y2, Z1 = Z2.


#show piece/2.
#show placed/4.