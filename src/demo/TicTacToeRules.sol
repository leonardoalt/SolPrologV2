// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import '../Builder.sol';

contract TicTacToeRules is TermBuilder {
	using RuleBuilder for Rule[];

	function loadMoveRules(Rule[] storage io_rules) internal {
		// field(x).
		// field(o).
		// field(.).
		io_rules.add(pred("field", atom("x")));
		io_rules.add(pred("field", atom("o")));
		io_rules.add(pred("field", atom(".")));

		// row([Field1, Field2, Field3]) :- field(Field1), field(Field2), field(Field3).
		io_rules.add(
			pred("row", list(Var("Field1"), Var("Field2"), Var("Field3"))),
			pred("field", Var("Field1")),
			pred("field", Var("Field2")),
			pred("field", Var("Field3"))
		);

		// board([Row1, Row2, Row3]) :- row(Row1), row(Row2), row(Row3).
		io_rules.add(
			pred("board", list(Var("Row1"), Var("Row2"), Var("Row3"))),
			pred("row", Var("Row1")),
			pred("row", Var("Row2")),
			pred("row", Var("Row3"))
		);

		// same(., .).
		// same(x, x).
		// same(o, o).
		// same([], []).
		io_rules.add(pred("same", atom("."), atom(".")));
		io_rules.add(pred("same", atom("x"), atom("x")));
		io_rules.add(pred("same", atom("o"), atom("o")));
		io_rules.add(pred("same", list(), list()));

		// same([H1|T1], [H2|T2]) :- same(H1, H2), same(T1, T2).
		io_rules.add(
			pred("same", listHT(Var("H1"), Var("T1")), listHT(Var("H2"), Var("T2"))),
			pred("same", Var("H1"), Var("H2")),
			pred("same", Var("T1"), Var("T2"))
		);

		// single-new-x(., x).
		// single-new-o(., o).
		io_rules.add(pred("single-new-x", atom("."), atom("x")));
		io_rules.add(pred("single-new-o", atom("."), atom("o")));

		// single-new-x([A|TA], [B|TB]) :- single-new-x(A, B), same(TA, TB).
		// single-new-x([A|TA], [B|TB]) :- same(A, B), single-new-x(TA, TB).
		// single-new-o([A|TA], [B|TB]) :- single-new-o(A, B), same(TA, TB).
		// single-new-o([A|TA], [B|TB]) :- same(A, B), single-new-o(TA, TB).
		io_rules.add(
			pred("single-new-x", listHT(Var("A"), Var("TA")), listHT(Var("B"), Var("TB"))),
			pred("single-new-x", Var("A"), Var("B")),
			pred("same", Var("TA"), Var("TB"))
		);
		io_rules.add(
			pred("single-new-x", listHT(Var("A"), Var("TA")), listHT(Var("B"), Var("TB"))),
			pred("same", Var("A"), Var("B")),
			pred("single-new-x", Var("TA"), Var("TB"))
		);
		io_rules.add(
			pred("single-new-o", listHT(Var("A"), Var("TA")), listHT(Var("B"), Var("TB"))),
			pred("single-new-o", Var("A"), Var("B")),
			pred("same", Var("TA"), Var("TB"))
		);
		io_rules.add(
			pred("single-new-o", listHT(Var("A"), Var("TA")), listHT(Var("B"), Var("TB"))),
			pred("same", Var("A"), Var("B")),
			pred("single-new-o", Var("TA"), Var("TB"))
		);

		// move(x, BoardBefore, BoardAfter) :- board(BoardBefore), board(BoardAfter), single-new-x(BoardBefore, BoardAfter).
		// move(o, BoardBefore, BoardAfter) :- board(BoardBefore), board(BoardAfter), single-new-o(BoardBefore, BoardAfter).
		io_rules.add(
			pred("move", atom("x"), Var("BoardBefore"), Var("BoardAfter")),
			pred("board", Var("BoardBefore")),
			pred("board", Var("BoardAfter")),
			pred("single-new-x", Var("BoardBefore"), Var("BoardAfter"))
		);
		io_rules.add(
			pred("move", atom("o"), Var("BoardBefore"), Var("BoardAfter")),
			pred("board", Var("BoardBefore")),
			pred("board", Var("BoardAfter")),
			pred("single-new-o", Var("BoardBefore"), Var("BoardAfter"))
		);
	}

	function loadWinnerRules(Rule[] storage io_rules) internal {
		// player(x).
		// player(o).
		io_rules.add(pred("player", atom("x")));
		io_rules.add(pred("player", atom("o")));

		// winner(P, [P, P, P]) :- player(P).
		io_rules.add(
			pred("winner", Var("P"), list(Var("P"), Var("P"), Var("P"))),
			pred("player", Var("P"))
		);

		// winner(P, [H|_]) :- winner(P, H).
		// winner(P, [_|T]) :- winner(P, T).
		io_rules.add(
			pred("winner", Var("P"), listHT(Var("H"), ignore())),
			pred("winner", Var("P"), Var("H"))
		);
		io_rules.add(
			pred("winner", Var("P"), listHT(ignore(), Var("T"))),
			pred("winner", Var("P"), Var("T"))
		);

		// winner(P, [
		//     [P|_],
		//     [P|_],
		//     [P|_]
		// ]) :- player(P).
		io_rules.add(
			pred("winner", Var("P"), list(
				listHT(Var("P"), ignore()),
				listHT(Var("P"), ignore()),
				listHT(Var("P"), ignore())
			)),
			pred("player", Var("P"))
		);

		// winner(P, [
		//     [_|T1],
		//     [_|T2],
		//     [_|T3]
		// ]) :- winner(P, [T1, T2, T3]).
		io_rules.add(
			pred("winner", Var("P"), list(
				listHT(ignore(), Var("T")),
				listHT(ignore(), Var("T")),
				listHT(ignore(), Var("T"))
			)),
			pred("winner", Var("P"), list(Var("T1"), Var("T2"), Var("T3")))
		);

		// winner(P, [
		//     [P, _, _],
		//     [_, P, _],
		//     [_, _, P]
		// ]) :- player(P).
		io_rules.add(
			pred("winner", Var("P"), list(
				list(Var("P"), ignore(), ignore()),
				list(ignore(), Var("P"), ignore()),
				list(ignore(), ignore(), Var("P"))
			)),
			pred("player", Var("P"))
		);

		// winner(P, [
		//     [_, _, P],
		//     [_, P, _],
		//     [P, _, _]
		// ]) :- player(P).
		io_rules.add(
			pred("winner", Var("P"), list(
				list(ignore(), ignore(), Var("P")),
				list(ignore(), Var("P"), ignore()),
				list(Var("P"), ignore(), ignore())
			)),
			pred("player", Var("P"))
		);
	}
}
