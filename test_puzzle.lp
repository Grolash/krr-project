perm(1, 2, 3,  1).  perm(2, 3, 1, 1).  perm(3, 1, 2,  1).  % even permutations (1 perm)
perm(1, 3, 2, -1).  perm(2, 1, 3, -1).  perm(3, 2, 1, -1).  % odd permutations (2 perms)
sign(1 ; -1).

rotation(0..2).

cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D.

1 { anchor(Bid, Pid, R, X, Y, Z) : cell(X, Y, Z), rotate(R, 0, 0, 0, Pid) } 1:- Bid = 0..N, total_blocks(N).

rot(P1, S1, P2, S2, P3, S3):- perm(P1, P2, P3, SP), sign(S1), sign(S2), sign(S3), S1 * S2 * S3 * SP = 1.


coord(1, X, Y, Z, X):- cell(X, Y, Z). coord(2, X, Y, Z, Y):- cell(X, Y, Z). coord(3, X, Y, Z, Z):- cell(X, Y, Z).

placed(Bid, X, Y, Z):- anchor(Bid, Pid, R, A1, B1, C1), piece(Pid, A2, B2, C2), X = A1 + A2, Y = B1 + B2, Z = C1 + C2.

:- placed(X, Y, Z, Bid), not cell(X, Y, Z). % cannot place outside valid coordinates
covered(X, Y, Z):- placed(X, Y, Z, Bid). % a cell is covered if a piece is placed on it
:- cell(X, Y, Z), not covered(X, Y, Z). % equivalence ^v :) this is just in case it makes computation faster

#show placed/4.
%#show anchor/6.