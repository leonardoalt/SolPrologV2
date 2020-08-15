// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../Substitution.sol";
import "../Prolog.sol";
import "./TicTacToeRules.sol";
import "ds-test/test.sol";


contract TicTacToeRulesTestBase is DSTest, TicTacToeRules {
	Rule[] rules;
	Substitution.Info substitutions;

	function assertGoal(Term memory _term) internal {
		assert(Prolog.query(_term, rules, substitutions));
	}

	function assertRefute(Term memory _term) internal {
		assert(!Prolog.query(_term, rules, substitutions));
	}
}


contract TicTacToeMoveRulesTest is TicTacToeRulesTestBase {
	function setUp() public {
		loadMoveRules(rules);
	}

	function test_field_predicate() public {
		assertGoal(pred("field", atom("x")));
	}

	function test_row_predicate() public {
		assertGoal(pred("row", list(atom("x"), atom("x"), atom("o"))));
	}

	function test_board_predicate() public {
		assertGoal(pred("board", list(
			list(atom('x'), atom('o'), atom('.')),
			list(atom('o'), atom('.'), atom('x')),
			list(atom('.'), atom('x'), atom('o'))
		)));
	}

	function test_same_predicate() public {
		assertGoal(pred(
			"same",
			list(
				list(atom('x'), atom('o'), atom('.')),
				list(atom('o'), atom('.'), atom('x')),
				list(atom('.'), atom('x'), atom('o'))
			),
			list(
				list(atom('x'), atom('o'), atom('.')),
				list(atom('o'), atom('.'), atom('x')),
				list(atom('.'), atom('x'), atom('o'))
			)
		));
	}

	function test_single_new_x_predicate_with_rows() public {
		assertGoal(pred(
			"single-new-x",
			list(atom('.'), atom('.'), atom('.')),
			list(atom('.'), atom('.'), atom('x'))
		));
	}

	function test_single_new_x_predicate_with_boards() public {
		assertGoal(pred(
			"single-new-x",
			list(
				list(atom('.'), atom('.'), atom('.')),
				list(atom('.'), atom('.'), atom('.')),
				list(atom('.'), atom('.'), atom('.'))
			),
			list(
				list(atom('.'), atom('.'), atom('.')),
				list(atom('.'), atom('x'), atom('.')),
				list(atom('.'), atom('.'), atom('.'))
			)
		));
	}

	function test_move_predicate_should_allow_correct_move() public {
		assertGoal(pred(
			"move",
			atom("o"),
			list(
				list(atom('.'), atom('o'), atom('x')),
				list(atom('x'), atom('x'), atom('.')),
				list(atom('o'), atom('.'), atom('.'))
			),
			list(
				list(atom('.'), atom('o'), atom('x')),
				list(atom('x'), atom('x'), atom('o')),
				list(atom('o'), atom('.'), atom('.'))
			)
		));
	}

	function test_move_predicate_should_not_allow_move_by_the_wrong_player() public {
		assertGoal(pred(
			"move",
			atom("x"),
			list(
				list(atom('.'), atom('o'), atom('x')),
				list(atom('x'), atom('x'), atom('.')),
				list(atom('o'), atom('.'), atom('.'))
			),
			list(
				list(atom('.'), atom('o'), atom('x')),
				list(atom('x'), atom('x'), atom('o')),
				list(atom('o'), atom('.'), atom('.'))
			)
		));
	}
}
