% cup
hollow(X, Y, Z):- length(L), X = 2..L-2, height(H), Y = 2..H, depth(D), Z = 2..D-2.
cell(X, Y, Z):- length(L), X=0..L, height(H), Y=0..H, depth(D), Z=0..D..

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

:- placed(X, Y, Z, Bid), not cell(X, Y, Z). % cannot place outside valid coordinates
covered(X, Y, Z):- placed(X, Y, Z, Bid). % a cell is covered if a piece is placed on it
:- cell(X, Y, Z), not covered(X, Y, Z). % equivalence ^v :) this is just in case it makes computation faster

:- placed(X, Y, Z, Bid1), placed(X, Y, Z, Bid2), Bid1 != Bid2. % cannot place two blocks in the same cell

% cell, cell + 1 in some direction
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2, Z1 = Z2 + 1.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2, Y1 = Y2 + 1, Z1 = Z2.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2):- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2 + 1, Y1 = Y2, Z1 = Z2.

equal_size(Bid1, Bid2):- anchor(Bid1, Pid1, R1, X1, Y1, Z1), anchor(Bid2, Pid2, R2, X2, Y2, Z2), piece_size(Pid1, S), piece_size(Pid2, S).

% two blocks of equal size cannot be orthogonally adjacent
:- placed(X1, Y1, Z1, Bid1), placed(X2, Y2, Z2, Bid2), ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2), equal_size(Bid1, Bid2), Bid1 != Bid2.

% lex-leader board symmetry breaking constraints (this is just what I did for homework 3)
c_lex_idx(Id, X, Y, Z):- cell(X, Y, Z), length(L), height(H), Id = (Z * L * H) + (Y * L) + X + 1.

% board symmetries; Because we chose a pot as the 3D "board", there is actually only one symmetry
% (horizontally, so the hole doesn't move), so I use a good ol' rotation matrix, it's just easier in this case.
sym_block(0, X, Y, Z, Bid):- placed(X, Y, Z, Bid). % current placements
sym_block(Id, NewX, Y, NewZ, Bid):- sym_block(Id - 1, X, Y, Z, Bid), NewX = Z, NewZ = -X, Id = 1..3. % y-axis

% lex-leader ordering
% base case
seq_agrees(Sym, 0) :- Sym = 1..3. % tautological start: index 0 does not exist

seq_agrees(Sym, I) :- seq_agrees(Sym, I - 1), % sequence building
                     c_lex_idx(I, X, Y, Z), % current cell
                     sym_block(0, X, Y, Z, Bid), % current block
                     sym_block(Sym, X, Y, Z, Bid). % block at I if applying a certain symmetry

% we remove symmetries where the first disagreement leads to
% the current block being greater than the one obtained by applying the board symmetry
:- seq_agrees(Sym, I - 1),
   c_lex_idx(I, X, Y, Z),
   sym_block(0, X, Y, Z, Bid1),
   sym_block(Sym, X, Y, Z, Bid2),
   Bid1 > Bid2.

#show placed/4.