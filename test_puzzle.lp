perm(1, 2, 3,  1).  perm(2, 3, 1, 1).  perm(3, 1, 2,  1).  % even permutations (1 perm)
perm(1, 3, 2, -1).  perm(2, 1, 3, -1).  perm(3, 2, 1, -1).  % odd permutations (2 perms)
sign(1 ; -1).

cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D.

1 { anchor(Bid, Pid, R, X, Y, Z) : cell(X, Y, Z), rotate(R, 0, 0, 0, Pid) } 1:- Bid = 0..N, total_blocks(N).

rot(P1, S1, P2, S2, P3, S3):- perm(P1, P2, P3, SP), sign(S1), sign(S2), sign(S3), S1 * S2 * S3 * SP = 1.

% let's not use entire 6-tuples as Ids... Rotation Id = mixed radix encoding
% P values in {1, 2, 3}
% S values in {0, 1}
% max digit multiplier = 2×3×2×3×2 = 72
rotate(R, NewX, NewY, NewZ, Id):- piece(Id, X, Y, Z), rot(P1, S1, P2, S2, P3, S3),
                                    R = (P1 - 1) * 72 + (S1 + 1) / 2 * 36 + (P2 - 1) * 12
                                    + (S2 + 1) / 2 * 6 + (P3 - 1) * 2  + (S3 + 1) / 2,
                                    coord(P1, X, Y, Z, V1), NewX = S1 * V1,
                                    coord(P2, X, Y, Z, V2), NewY = S2 * V2,
                                    coord(P3, X, Y, Z, V3), NewZ = S3 * V3.

coord(1, X, Y, Z, X):- cell(X, Y, Z). coord(2, X, Y, Z, Y):- cell(X, Y, Z). coord(3, X, Y, Z, Z):- cell(X, Y, Z).

placed(X, Y, Z, Bid):- anchor(Bid, Pid, R, A1, B1, C1), rotate(R, A2, B2, C2, Pid), X = A1 + A2, Y = B1 + B2, Z = C1 + C2.


#show placed/4.