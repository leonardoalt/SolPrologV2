# TicTacToe demo for SolPrologV2

This directory contains an example contract that demonstrates the usage of SolPrologV2.

## `TicTacToe` contract usage
The contract is a simple blockchain game of [tic tac toe](https://en.wikipedia.org/wiki/Tic-tac-toe).

One of the players intiates the game by calling `TicTacToe.newGame()` along with address of the opponent and some ether.
The opponent must respond by calling the same method with the address of the other player and some more ether.
The game is from now on uniquely identified by this pair of addresses.

Players in turn call `TicTacToe.move()` and give it a 3x3 array containing the new state of the board.
`TicTacToe.move()` reverts unless the move is correct.

`TicTacToe.gameState()` and `TicTacToe.winner()` are query methods that allow inspecting the state of the board and checking if there's a winner.

When one of the players wins, `TicTacToe.payOut()` method can be called by him to get all the ether paid in earlier by both players.
If there's a draw, one of the players must call `TicTacToe.withdraw()` and the contract sends each player his own stake.

There can be only one game at a time between any given two players but the contract can handle multiple ongoing games between different pairs.

## Prolog implementation
The game uses Prolog intepreter with two sets of clauses.

### Move set
The first set is used for two different purposes: validating moves against the rules of the game and checking if another move is still possible.
```prolog
field(x).
field(o).
field(.).
row([Field1, Field2, Field3]) :- field(Field1), field(Field2), field(Field3).
board([Row1, Row2, Row3]) :- row(Row1), row(Row2), row(Row3).

same(., .).
same(x, x).
same(o, o).
same([], []).
same([H1|T1], [H2|T2]) :- same(H1, H2), same(T1, T2).

single-new-x(., x).
single-new-o(., o).
single-new-x([A|TA], [B|TB]) :- single-new-x(A, B), same(TA, TB).
single-new-x([A|TA], [B|TB]) :- same(A, B), single-new-x(TA, TB).
single-new-o([A|TA], [B|TB]) :- single-new-o(A, B), same(TA, TB).
single-new-o([A|TA], [B|TB]) :- same(A, B), single-new-o(TA, TB).
move(x, BoardBefore, BoardAfter) :- board(BoardBefore), board(BoardAfter), single-new-x(BoardBefore, BoardAfter).
move(o, BoardBefore, BoardAfter) :- board(BoardBefore), board(BoardAfter), single-new-o(BoardBefore, BoardAfter).
```

Given these rules, move validation is very simple: the contact tries to satisfy a literal goal using `move/3` predicate.
The third argument comes from the caller and the first and the second one represent the current state of the game:

```prolog
?- move(x, [[., ., .], [., ., .], [., ., .]], [[., ., .], [., x, .], [., ., .]]).
true.
```

The goal won't be satisfied if the new state of the board does not add a single valid move:

```prolog
?- move(x, [[., ., .], [., ., .], [., ., .]], [[x, ., .], [., x, .], [., ., x]]).
false.
```

Checking if another move is still possible is more interesting and shows the flexibility of Prolog.
We can use the exact same predicate but instead of specifying the next move and the current player ourselves we put in placeholder variables and let the Prolog engine to find anything that fits:

``` prolog
?- move(P, [[x, o, o], [o, x, .], [., x, x]], BoardAfter).
P = x,
BoardAfter = [[x, o, o], [o, x, x], [., x, x]] ;
P = x,
BoardAfter = [[x, o, o], [o, x, .], [x, x, x]] ;
P = o,
BoardAfter = [[x, o, o], [o, x, o], [., x, x]] ;
P = o,
BoardAfter = [[x, o, o], [o, x, .], [o, x, x]] ;
```

If there's anything that satisfies the goal, we know that moves are still possible.

### Winner set
The second set of clauses is used to check who won:
```prolog
player(x).
player(o).
winner(P, [P, P, P]) :- player(P).
winner(P, [H|_]) :- winner(P, H).
winner(P, [_|T]) :- winner(P, T).
winner(P, [
    [P|_],
    [P|_],
    [P|_]
]) :- player(P).
winner(P, [
    [_|T1],
    [_|T2],
    [_|T3]
]) :- winner(P, [T1, T2, T3]).
winner(P, [
    [P, _, _],
    [_, P, _],
    [_, _, P]
]) :- player(P).
winner(P, [
    [_, _, P],
    [_, P, _],
    [P, _, _]
]) :- player(P).
```

`TicTacToe.winner()` specifies the state of the board and lets the engine find all the players who match variable `P`:

```prolog
?- winner(P, [
    [x, o, o],
    [o, x, .],
    [., x, x]
]).
P = x.
```

**NOTE**: It's possible to construct a board state where there are two winners and the rules above can even handle that (though move validation won't let players ever reach such a state in practice):
```prolog
?- winner(P, [
    [x, o, x],
    [., o, x],
    [., o, x]
]).
P = o ;
P = x.
```
