

% signed permutation matrices
perm(1, 2, 3,  1).  perm(2, 3, 1, 1).  perm(3, 1, 2,  1).
perm(1, 3, 2, -1).  perm(2, 1, 3, -1).  perm(3, 2, 1, -1).
sign(1 ; -1).

rot(P1, S1, P2, S2, P3, S3) :- perm(P1, P2, P3, SP), sign(S1), sign(S2), sign(S3), S1 * S2 * S3 * SP = 1.

% Domaine de coordonnées indépendant de cell
piece_coord(C) :- piece(_, C, _, _).
piece_coord(C) :- piece(_, _, C, _).
piece_coord(C) :- piece(_, _, _, C).

coord_val(1, X, Y, Z, X) :- piece_coord(X), piece_coord(Y), piece_coord(Z).
coord_val(2, X, Y, Z, Y) :- piece_coord(X), piece_coord(Y), piece_coord(Z).
coord_val(3, X, Y, Z, Z) :- piece_coord(X), piece_coord(Y), piece_coord(Z).

% Rotation sans dépendance à cell
rotate(R, NewX, NewY, NewZ, Pid) :-
    piece(Pid, X, Y, Z),
    rot(P1, S1, P2, S2, P3, S3),
    R = (P1-1)*72 + (S1+1)/2*36 + (P2-1)*12 + (S2+1)/2*6 + (P3-1)*2 + (S3+1)/2,
    coord_val(P1, X, Y, Z, V1), NewX = S1 * V1,
    coord_val(P2, X, Y, Z, V2), NewY = S2 * V2,
    coord_val(P3, X, Y, Z, V3), NewZ = S3 * V3.

% Normalisation
min_x(R, Pid, MX) :- rotate(R, _, _, _, Pid), MX = #min{ X : rotate(R, X, _, _, Pid) }.
min_y(R, Pid, MY) :- rotate(R, _, _, _, Pid), MY = #min{ Y : rotate(R, _, Y, _, Pid) }.
min_z(R, Pid, MZ) :- rotate(R, _, _, _, Pid), MZ = #min{ Z : rotate(R, _, _, Z, Pid) }.

rotate_norm(R, NX, NY, NZ, Pid) :-
    rotate(R, X, Y, Z, Pid),
    min_x(R, Pid, MX), min_y(R, Pid, MY), min_z(R, Pid, MZ),
    NX = X - MX, NY = Y - MY, NZ = Z - MZ.

% Rotations canoniques via hash
rot_hash(R, Pid, H) :-
    rotate_norm(R, _, _, _, Pid),
    H = #sum{ NX*10000 + NY*100 + NZ, NX, NY, NZ : rotate_norm(R, NX, NY, NZ, Pid) }.

dominated_rot(Pid, R) :-
    rot_hash(R, Pid, H),
    rot_hash(R2, Pid, H),
    R2 < R.

canonical_rot(Pid, R) :-
    rotate_norm(R, _, _, _, Pid),
    not dominated_rot(Pid, R).

% Cellules valides
cell(X, Y, Z) :- length(L), height(H), depth(D), X = 0..L, Y = 0..H, Z = 0..D.

% Index lexicographique des cellules
c_lex_idx(Id, X, Y, Z) :- cell(X, Y, Z), length(L), height(H), Id = (Z * (L+1) * (H+1)) + (Y * (L+1)) + X + 1.

% Choix d'ancre parmi les rotations canoniques
1 { anchor(Bid, Pid, R, X, Y, Z) : cell(X, Y, Z), canonical_rot(Pid, R) } 1
    :- Bid = 0..N, total_blocks(N).

% Contrainte pick_times
correct_picks(Pid, Times) :- #count{ Bid : anchor(Bid, Pid, R, X, Y, Z) } = Times, pick_times(Pid, Times).
:- pick_times(Pid, Times), not correct_picks(Pid, Times).

% Placement
placed(X, Y, Z, Bid) :-
    anchor(Bid, Pid, R, A1, B1, C1),
    rotate_norm(R, A2, B2, C2, Pid),
    X = A1 + A2, Y = B1 + B2, Z = C1 + C2.

% L'ancre doit être la cellule lex-minimale de la pièce placée
:- anchor(Bid, Pid, R, AX, AY, AZ),
   placed(X, Y, Z, Bid),
   c_lex_idx(IA, AX, AY, AZ),
   c_lex_idx(IP, X, Y, Z),
   IP < IA.

% Contraintes de placement
:- placed(X, Y, Z, Bid), not cell(X, Y, Z).
covered(X, Y, Z) :- placed(X, Y, Z, _).
:- cell(X, Y, Z), not covered(X, Y, Z).
:- placed(X, Y, Z, Bid1), placed(X, Y, Z, Bid2), Bid1 != Bid2.

% Adjacence orthogonale
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2) :- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2,     Y1 = Y2,     Z1 = Z2 + 1.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2) :- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2,     Y1 = Y2 + 1, Z1 = Z2.
ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2) :- cell(X1, Y1, Z1), cell(X2, Y2, Z2), X1 = X2 + 1, Y1 = Y2,     Z1 = Z2.

% Deux blocs de même taille ne peuvent pas être orthogonalement adjacents
equal_size(Bid1, Bid2) :-
    anchor(Bid1, Pid1, _, _, _, _),
    anchor(Bid2, Pid2, _, _, _, _),
    piece_size(Pid1, S), piece_size(Pid2, S).

:- placed(X1, Y1, Z1, Bid1), placed(X2, Y2, Z2, Bid2),
   ortho_adjacent(X1, Y1, Z1, X2, Y2, Z2),
   equal_size(Bid1, Bid2), Bid1 != Bid2.

% Symétrie du plateau (rotation Y)
sym_block(0, X, Y, Z, Bid) :- placed(X, Y, Z, Bid).
sym_block(Id, NewX, Y, NewZ, Bid) :-
    sym_block(Id-1, X, Y, Z, Bid),
    length(L), NewX = Z, NewZ = L - X,
    Id = 1..3.

seq_agrees(Sym, 0) :- Sym = 1..3.
seq_agrees(Sym, I) :-
    seq_agrees(Sym, I-1),
    c_lex_idx(I, X, Y, Z),
    sym_block(0, X, Y, Z, Bid),
    sym_block(Sym, X, Y, Z, Bid).

:- seq_agrees(Sym, I-1),
   c_lex_idx(I, X, Y, Z),
   sym_block(0, X, Y, Z, Bid1),
   sym_block(Sym, X, Y, Z, Bid2),
   Bid1 > Bid2.

#show placed/4.