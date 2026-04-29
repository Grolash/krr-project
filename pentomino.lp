c(X, Y):- X = 0..3, Y = 0..7. % cells domain
hole(0, 3, 3). hole(0, 3, 4). hole(1, 0, 3). hole(1, 0, 4). % center hole coordinates

mirror(S, NewX, Y):- shape(X, Y, S), NewX = -X. % we flippy

rotation(0, S, X, Y):- shape(X, Y, S). % we apply rotation matrices to the shape
rotation(1, S, NewX, NewY):- shape(X, Y, S), NewX = -Y, NewY = X.
rotation(2, S, NewX, NewY):- shape(X, Y, S), NewX = -X, NewY = -Y.
rotation(3, S, NewX, NewY):- shape(X, Y, S), NewX = Y, NewY = -X.

rotation(4, S, X, Y):- mirror(S, X, Y). % and its mirror
rotation(5, S, NewX, NewY):- mirror(S, X, Y), NewX = -Y, NewY = X.
rotation(6, S, NewX, NewY):- mirror(S, X, Y), NewX = -X, NewY = -Y.
rotation(7, S, NewX, NewY):- mirror(S, X, Y), NewX = Y, NewY = -X.

% the cell with coordinates (0, 0) in the shape's LOCAL coordinate system is the anchor cell
1 { anchor(H, X, Y, R, S) : c(X, Y), rotation(R, S, 0, 0), H = 0..1 } 1 :- S = 1..12.
% it must be on the board, and one per shape among all the placements, rotations, and board halves

not_identical_rotations(S, R1, R2):- rotation(R1, S, X, Y), rotation(R2, S, A, B), not rotation(R2, S, X, Y), R1 != R2.
not_identical_rotations(S, R1, R2):- rotation(R2, S, X, Y), rotation(R1, S, A, B), not rotation(R1, S, X, Y), R1 != R2.
% there exists two rotations such that they differ in at least one cell
:- anchor(H, X, Y, R2, S), rotation(R1, S, A, B), not not_identical_rotations(S, R1, R2), R1 < R2.
% if two rotations are identical, prefer the lexicographically smaller one to avoid redundancy

% for each anchor cell, we place all the coordinates of the shape on the board, relative to the anchor cell.
placed(H, X, Y, S):- anchor(H, A, B, R, S), rotation(R, S, C, D), X = A + C, Y = B + D.
% X, Y are equal to the anchor's coordinates plus the coordinates of the shape's cell in
% its local coordinate system, for a rotation and mirroring given by the anchor.

:- placed(H, X, Y, S), not c(X, Y). % cannot place outside valid coordinates
:- placed(H, X, Y, S), hole(H, X, Y). % cannot place on hole
:- placed(H, X, Y, S), placed(H, X, Y, T), S != T. % cannot place two shapes on the same coordinates on the same half,
% preventing overlap of shapes

covered(H, X, Y):- placed(H, X, Y, S). % a cell is covered if a shape is placed on it
covered(H, X, Y):- hole(H, X, Y). % or if it is the hole
:- c(X, Y), not covered(0, X, Y).
:- c(X, Y), not covered(1, X, Y).

% lex-leader board symmetry breaking constraints
c_lex_idx(I, H, X, Y) :- c(X, Y), H = 0..1, I = H * 32 + X * 8 + Y + 1.

% board symmetries
sym_shape(0, H, X, Y, S) :- placed(H, X, Y, S). % current placements
sym_shape(0, H, X, Y, 0) :- hole(H, X, Y). % diggy diggy hole
sym_shape(1, H, X, NewY, S) :- sym_shape(0, H, X, Y, S), NewY = 7-Y. % vertical symmetry
sym_shape(2, NewH, NewX, Y, S) :- sym_shape(0, H, X, Y, S), NewH = 1-H, NewX = 3-X. % horizontal symmetry
sym_shape(3, NewH, NewX, NewY, S) :- sym_shape(0, H, X, Y, S), NewH = 1-H, NewX = 3-X, NewY = 7-Y. % both

% lex-leader ordering
% base case
seq_agrees(Sym, 0) :- Sym = 1..3. % tautological start: index 0 does not exist

seq_agrees(Sym, I) :- seq_agrees(Sym, I-1), % sequence building
                   c_lex_idx(I, H, X, Y), % current cell
                   sym_shape(0, H, X, Y, S), % current shape
                   sym_shape(Sym, H, X, Y, S). % shape at I if applying a certain symmetry

% we remove symmetries where the first disagreement leads to
% the current shape being greater than the one obtained by applying the board symmetry
:- seq_agrees(Sym, I-1),
   c_lex_idx(I, H, X, Y),
   sym_shape(0, H, X, Y, S1),
   sym_shape(Sym, H, X, Y, S2),
   S1 > S2.

#show placed/4.