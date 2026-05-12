% cup
hollow(X, Y, Z):- length(L), X = 2..L-2, height(H), Y = 2..H, depth(D), Z = 2..D-2.
cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D, not hollow(X, Y, Z).

% symmetries of 3D pieces:
% https://en.wikipedia.org/wiki/Octahedral_symmetry
% "A regular octahedron has 24 rotational (or orientation-preserving) symmetries [...].
% These include transformations that combine a reflection and a rotation."
% "Take the set of all 3×3 permutation matrices and assign a + or − sign to each of the three 1s.
% There are 3! = 6 permutations and 2^3 = 8 sign combinations for a total of 48 matrices,
% giving the full octahedral group.
% 24 of these matrices have a determinant of +1; these are the rotation matrices of the chiral octahedral group.
% The other 24 matrices have a determinant of −1 and correspond to a reflection or inversion."

% signed permutation matrices (6 permutations 2^3 = 8 sign combinations)
perm(1, 2, 3,  1).  perm(2, 3, 1, 1).  perm(3, 1, 2,  1).  % even permutations (1 perm)
perm(1, 3, 2, -1).  perm(2, 1, 3, -1).  perm(3, 2, 1, -1).  % odd permutations (2 perms)
sign(1 ; -1).

% rotations (signed permutations with determinant = 1; signs must compensate permutation parity)
rot(P1, S1, P2, S2, P3, S3):- perm(P1, P2, P3, SP), sign(S1), sign(S2), sign(S3), S1 * S2 * S3 * SP = 1.

% we translate the non-zero value position number thingy into its corresponding coordinate
% e.g. perm(3, 1, 2, 1) -> NewX = Z, NewY = X, NewZ = Y
coord(1, X, Y, Z, X):- cell(X, Y, Z). coord(2, X, Y, Z, Y):- cell(X, Y, Z). coord(3, X, Y, Z, Z):- cell(X, Y, Z).

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

% we detect equivalent rotations by checking if they share all coordinates or not
not_identical_rotations(P, R1, R2):- rotate(R1, X, Y, Z, P), rotate(R2, A, B, C, P), not rotate(R2, X, Y, Z, P).
not_identical_rotations(P, R1, R2):- rotate(R2, X, Y, Z, P), rotate(R1, A, B, C, P), not rotate(R1, X, Y, Z, P).

1 { anchor(Bid, Pid, R, X, Y, Z) : cell(X, Y, Z), rotate(R, 0, 0, 0, Pid) } 1:- Bid = 0..N, total_blocks(N).
correct_picks(Pid, Times):- #count{ Bid : anchor(Bid, Pid, R, X, Y, Z) } = Times, pick_times(Pid, Times).
:- pick_times(Pid, Times), not correct_picks(Pid, Times). % we check the number of picks of a piece is correct
:- anchor(Bid, Pid, R1, X, Y, Z), rotate(R2, A, B, C, Pid), not not_identical_rotations(Pid, R1, R2), R1 < R2. % lex leader

% for each anchor cell, we place all the coordinates of the shape on the board, relative to the anchor cell.
placed(X, Y, Z, Bid):- anchor(Bid, Pid, R, A1, B1, C1), rotate(R, A2, B2, C2, Pid), X = A1 + A2, Y = B1 + B2, Z = C1 + C2.
% X, Y, Z are equal to the anchor's coordinates plus the coordinates of the shape's cell in
% its local coordinate system, for a rotation and mirroring given by the anchor.

#show placed/4.