% cube
cell(X, Y, Z):- length(L), X=0..L-1, height(H), Y=0..H-1, depth(D), Z=0..D-1.

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
perm(1, 2, 3,  1).  perm(2, 3, 1, 1).  perm(3, 1, 2,  1).  % even permutations
perm(1, 3, 2, -1).  perm(2, 1, 3, -1).  perm(3, 2, 1, -1).  % odd permutations
sign(1 ; -1).

% rotations (signed permutations with determinant = 1; signs must compensate permutation parity)
rot(P1, S1, P2, S2, P3, S3):- perm(P1, P2, P3, SP), sign(S1), sign(S2), sign(S3), S1 * S2 * S3 * SP = 1.

piece_coord(C) :- piece(_, C, _, _).
piece_coord(C) :- piece(_, _, C, _).
piece_coord(C) :- piece(_, _, _, C).

% we translate the non-zero value position number thingy into its corresponding coordinate
% e.g. perm(3, 1, 2, 1) -> NewX = Z, NewY = X, NewZ = Y
coord(1, X, Y, Z, X) :- piece_coord(X), piece_coord(Y), piece_coord(Z).
coord(2, X, Y, Z, Y) :- piece_coord(X), piece_coord(Y), piece_coord(Z).
coord(3, X, Y, Z, Z) :- piece_coord(X), piece_coord(Y), piece_coord(Z).

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

plop(X, Y, Z):- rotate(118, X, Y, Z, _).

#show plop/3.