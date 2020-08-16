// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./TicTacToeBoard.sol";
import "ds-test/test.sol";


contract TicTacToeBoardTest is DSTest, TicTacToeBoard {
	using Logic for Term;

	TicTacToeBoard.Field constant X = TicTacToeBoard.Field.X;
	TicTacToeBoard.Field constant O = TicTacToeBoard.Field.O;
	TicTacToeBoard.Field constant B = TicTacToeBoard.Field.Blank;

	function setUp() public {
	}

	function assertEq(TicTacToeBoard.Field _expectedValue, TicTacToeBoard.Field _actualValue) internal {
		assertEq(uint(_expectedValue), uint(_actualValue));
	}

	function test_is_field_literal() public pure {
		assert(isFieldLiteral(atom('x')));
		assert(isFieldLiteral(atom('o')));
		assert(isFieldLiteral(atom('.')));

		assert(!isFieldLiteral(atom('b')));
		assert(!isFieldLiteral(list()));
	}

	function test_is_row_literal() public pure {
		assert(isRowLiteral(list(atom('x'), atom('o'), atom('.'))));

		assert(!isRowLiteral(list()));
		assert(!isRowLiteral(atom('b')));
		assert(!isRowLiteral(list(
			list(atom('x'), atom('o'), atom('.')),
			list(atom('x'), atom('o'), atom('.')),
			list(atom('x'), atom('o'), atom('.'))
		)));
	}

	function test_is_board_literal() public pure {
		assert(isBoardLiteral(list(
			list(atom('x'), atom('o'), atom('.')),
			list(atom('x'), atom('o'), atom('.')),
			list(atom('x'), atom('o'), atom('.'))
		)));

		assert(!isBoardLiteral(atom('x')));
		assert(!isBoardLiteral(atom('b')));
		assert(!isBoardLiteral(list(atom('x'), atom('o'), atom('.'))));
		assert(!isBoardLiteral(list()));
	}

	function test_field_to_atom() public pure {
		assert(TicTacToeBoard.fieldToAtom(X).equalsMemory(atom('x')));
		assert(TicTacToeBoard.fieldToAtom(O).equalsMemory(atom('o')));
		assert(TicTacToeBoard.fieldToAtom(B).equalsMemory(atom('.')));
	}

	function testFail_field_to_atom_should_fail_if_field_is_invalid() public pure {
		TicTacToeBoard.fieldToAtom(TicTacToeBoard.Field(100));
	}

	function test_atom_to_field() public {
		assertEq(TicTacToeBoard.atomToField(atom('x')), X);
		assertEq(TicTacToeBoard.atomToField(atom('o')), O);
		assertEq(TicTacToeBoard.atomToField(atom('.')), B);
	}

	function testFail_atom_to_field_should_fail_if_atom_is_not_field() public pure {
		TicTacToeBoard.atomToField(atom('b'));
	}

	function test_board_to_term() public pure {
		TicTacToeBoard.Field[3][3] memory board = [
			[X, O, B],
			[O, B, X],
			[B, X, O]
		];
		Term memory expectedTerm = list(
			list(atom('x'), atom('o'), atom('.')),
			list(atom('o'), atom('.'), atom('x')),
			list(atom('.'), atom('x'), atom('o'))
		);

		assert(TicTacToeBoard.boardToTerm(board).equalsMemory(expectedTerm));
	}

	function test_empty_board_should_produce_list_convertible_to_board_literal() public pure {
		assert(isBoardLiteral(TicTacToeBoard.boardToTerm(TicTacToeBoard.emptyBoard())));
	}
}
