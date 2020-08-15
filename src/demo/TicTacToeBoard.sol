// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import '../Builder.sol';
import '../Logic.sol';

contract TicTacToeBoard is TermBuilder {
	using Logic for Term;

	enum Field {
		Blank,
		X,
		O
	}

	function isFieldLiteral(Term memory _field) internal pure returns (bool) {
		return _field.equalsMemory(atom("x")) || _field.equalsMemory(atom("o")) || _field.equalsMemory(atom("."));
	}

	function isRowLiteral(Term memory _row) internal pure returns (bool) {
		_row.validate();

		return _row.kind == TermKind.List &&
			_row.arguments.length == 3 &&
			isFieldLiteral(_row.arguments[0]) &&
			isFieldLiteral(_row.arguments[1]) &&
			isFieldLiteral(_row.arguments[2]);
	}

	function isBoardLiteral(Term memory _board) internal pure returns (bool) {
		_board.validate();

		return _board.kind == TermKind.List &&
			_board.arguments.length == 3 &&
			isRowLiteral(_board.arguments[0]) &&
			isRowLiteral(_board.arguments[1]) &&
			isRowLiteral(_board.arguments[2]);
	}

	function fieldToAtom(Field _field) internal pure returns (Term memory) {
		if (_field == Field.X)
			return atom("x");
		else if (_field == Field.O)
			return atom("o");
		else if (_field == Field.Blank)
			return atom(".");
		else
			assert(false);
	}

	function atomToField(Term memory _field) internal pure returns (Field) {
		if (_field.equalsMemory(atom("x")))
			return Field.X;
		else if (_field.equalsMemory(atom("o")))
			return Field.O;
		else if (_field.equalsMemory(atom(".")))
			return Field.Blank;
		else
			assert(false);
	}

	function boardToTerm(Field[3][3] memory _boardState) internal pure returns (Term memory) {
		return list(
			list(fieldToAtom(_boardState[0][0]), fieldToAtom(_boardState[0][1]), fieldToAtom(_boardState[0][2])),
			list(fieldToAtom(_boardState[1][0]), fieldToAtom(_boardState[1][1]), fieldToAtom(_boardState[1][2])),
			list(fieldToAtom(_boardState[2][0]), fieldToAtom(_boardState[2][1]), fieldToAtom(_boardState[2][2]))
		);
	}

	function emptyBoard() internal pure returns (Field[3][3] memory) {
		return [
			[Field.Blank, Field.Blank, Field.Blank],
			[Field.Blank, Field.Blank, Field.Blank],
			[Field.Blank, Field.Blank, Field.Blank]
		];
	}
}

