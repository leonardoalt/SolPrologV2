// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Unification.sol";
import "./Logic.sol";


contract Fixtures is TermBuilder{
	function family(bytes memory _memberName1) internal pure returns (Term memory) {
		return pred("family", atom(_memberName1));
	}

	function family(bytes memory _memberName1, bytes memory _memberName2) internal pure returns (Term memory) {
		return pred("family", atom(_memberName1), atom(_memberName2));
	}

	function family(Term memory _member1) internal pure returns (Term memory) {
		return pred("family", _member1);
	}

	function family(Term memory _member1, Term memory _member2) internal pure returns (Term memory) {
		return pred("family", _member1, _member2);
	}

	function family(Term memory _member1, Term memory _member2, Term memory _member3) internal pure returns (Term memory) {
		return pred("family", _member1, _member2, _member3);
	}
}


contract UnificationTestBase is DSTest, TermBuilder, Fixtures {
	mapping(bytes32 => Term) substitutions;

	function setUp() public {
	}

	function assertUnify(Term memory _term1, Term memory _term2) internal {
		assert(Unification.unify(_term1, _term2, substitutions));
	}

	function assertNotUnify(Term memory _term1, Term memory _term2) internal {
		assert(!Unification.unify(_term1, _term2, substitutions));
	}
}


contract LiteralUnificationTest is UnificationTestBase {
	function test_unify_should_unify_identical_atoms() public {
		// ?- adam = adam.
		assertUnify(atom("adam"), atom("adam"));
		// true.
	}

	function test_unify_should_not_unify_different_atoms() public {
		// ?- adam = eve.
		assertNotUnify(atom("adam"), atom("eve"));
		// false.
	}

	function test_unify_should_unify_identical_predicates() public {
		// ?- family(adam, paul) = family(adam, paul).
		assertUnify(family("adam", "paul"), family("adam", "paul"));
		// true.
	}

	function test_unify_should_not_unify_predicates_with_different_argument_numbers() public {
		// ?- family(adam, paul) = family(adam).
		assertNotUnify(family("adam", "paul"), family("adam"));
		// false.
	}

	function test_unify_should_not_unify_predicates_with_different_arguments() public {
		// ?- family(adam, paul) = family(adam, eve).
		assertNotUnify(family("adam", "paul"), family("adam", "eve"));
		// false.
	}

	function test_unify_should_not_unify_predicates_with_different_names() public {
		// ?- family(adam, paul) = parent(adam, paul).
		assertNotUnify(pred("family", atom("adam"), atom("eve")), pred("parent", atom("adam"), atom("eve")));
		// false.
	}

	function test_unify_should_not_unify_predicate_with_atom() public {
		// ?- family(adam) = family.
		assertNotUnify(family("adam"), atom("family"));
		// false.
	}
}


contract NumberUnificationTest is UnificationTestBase {
	function test_unify_should_unify_identical_numbers() public {
		// ?- 1 = 1.
		assertUnify(num(1), num(1));
		// true.
	}

	function test_unify_should_not_unify_number_with_a_different_number() public {
		// ?- 1 = 5.
		assertNotUnify(num(1), num(5));
		// false.
	}

	function test_unify_should_not_unify_number_with_atom() public {
		// ?- 1 = adam.
		assertNotUnify(num(1), atom("adam"));
		// false.
	}

	function test_unify_should_not_unify_number_with_atom_named_after_that_number() public {
		// ?- 1 = '1'.
		assertNotUnify(num(1), atom("1"));
		// false.
	}

	function test_unify_should_not_unify_number_with_predicate_named_after_that_number() public {
		// ?- 1 = '1'(adam).
		assertNotUnify(num(1), pred("1", atom("adam")));
		// false.

		// ?- 1 = '1'(1).
		assertNotUnify(num(1), pred("1", num(1)));
		// false.
	}

	function test_unify_should_unify_identical_numbers_inside_predicate() public {
		// ?- family(1, 2) = family(1, 2).
		assertUnify(family(num(1), num(2)), family(num(1), num(2)));
		// true.

		// ?- family(1, family(2, 3)) = family(1, family(2, 3)).
		assertUnify(family(num(1), family(num(2), num(3))), family(num(1), family(num(2), num(3))));
		// true.

		// ?- family(1, 2) = family(2, 1).
		assertNotUnify(family(num(1), num(2)), family(num(2), num(1)));
		// false.
	}
}
