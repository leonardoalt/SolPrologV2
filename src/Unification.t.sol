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

	function assertSubstitution(Term memory _to, Term memory _from) internal view {
		require(_to.kind == TermKind.Variable);
		Logic.validate(_to);
		Logic.validate(_from);

		assert(Logic.termsEqualInStorage(substitutions[Logic.hash(_to)], _from));
	}

	function assertNoSubstitution(Term memory _to) internal view {
		require(_to.kind == TermKind.Variable);
		Logic.validate(_to);

		assert(Logic.isEmptyStorage(substitutions[Logic.hash(_to)]));
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


contract VariableUnificationTest is UnificationTestBase {
	function test_unify_should_unify_variable_with_atom() public {
		// ?- X = adam.
		assertUnify(Var("X"), atom("adam"));
		// X = adam.
		assertSubstitution(Var("X"), atom("adam"));
	}

	function test_unify_should_unify_atom_with_variable() public {
		// ?- adam = X.
		assertUnify(atom("adam"), Var("X"));
		// X = adam.
		assertSubstitution(Var("X"), atom("adam"));
	}

	function test_unify_should_unify_variable_with_variable() public {
		// ?- X = Y.
		assertUnify(Var("X"), Var("Y"));
		// X = Y.
		assertSubstitution(Var("X"), Var("Y"));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_variable_with_predicate() public {
		// ?- X = family(adam, paul).
		assertUnify(Var("X"), family("adam", "paul"));
		// X = family(adam, paul).
		assertSubstitution(Var("X"), family("adam", "paul"));
	}

	function test_unify_should_unify_variable_with_predicate_containing_variable() public {
		// ?- X = family(adam, Y).
		assertUnify(Var("X"), family(atom("adam"), Var("Y")));
		// X = family(adam, Y).
		assertSubstitution(Var("X"), family(atom("adam"), Var("Y")));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_variable_with_nested_predicate() public {
		// ?- X = family(family(adam, paul), family(adam, eve)).
		assertUnify(Var("X"), family(family("adam", "paul"), family("adam", "eve")));
		// X = family(family(adam, paul), family(adam, eve)).
		assertSubstitution(Var("X"), family(family("adam", "paul"), family("adam", "eve")));
	}

	function test_unify_should_unify_variable_inside_predicate() public {
		// ?- family(X, paul) = family(adam, paul).
		assertUnify(family(Var("X"), atom("paul")), family("adam", "paul"));
		// X = adam.
		assertSubstitution(Var("X"), atom("adam"));
	}

	function test_unify_should_find_substitutions_for_variables_on_both_sides() public {
		// ?- family(X, paul) = family(adam, Y).
		assertUnify(family(Var("X"), atom("paul")), family(atom("adam"), Var("Y")));
		// X = adam.
		// Y = paul.
		assertSubstitution(Var("X"), atom("adam"));
		assertSubstitution(Var("Y"), atom("paul"));
	}

	function test_unify_should_unify_nested_variable_with_nested_predicate() public {
		// ?- family(X, paul) = family(family(paul, eve), paul).
		assertUnify(family(Var("X"), atom("paul")), family(family("paul", "eve"), atom("paul")));
		// X = family(paul, eve).
		assertSubstitution(Var("X"), family("paul", "eve"));
	}

	function test_unify_should_unify_multiple_variables_inside_predicate() public {
		// ?- family(X, Y) = family(adam, paul).
		assertUnify(family(Var("X"), Var("Y")), family("adam", "paul"));
		// X = adam,
		// Y = paul.
		assertSubstitution(Var("X"), atom("adam"));
		assertSubstitution(Var("Y"), atom("paul"));
	}

	function test_unify_should_unify_same_variable_with_multiple_instances_of_same_atom() public {
		// ?- family(X, X) = family(adam, adam).
		assertUnify(family(Var("X"), Var("X")), family("adam", "adam"));
		// X = adam.
		assertSubstitution(Var("X"), atom("adam"));
	}

	function test_unify_should_not_unify_same_variable_with_different_atoms() public {
		// ?- family(X, X) = family(adam, paul).
		assertNotUnify(family(Var("X"), Var("X")), family("adam", "paul"));
		// false.
	}

	function test_unify_should_unify_multiple_instances_of_same_variable_pair() public {
		// ?- family(X, Y) = family(Y, X).
		assertUnify(family(Var("X"), Var("Y")), family(Var("Y"), Var("X")));
		// X = Y.
		assertSubstitution(Var("X"), Var("Y"));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_not_create_substitution_cycles() public {
		// ?- family(X, Y, Z) = family(Y, Z, X).
		assertUnify(family(Var("X"), Var("Y"), Var("Z")), family(Var("Y"), Var("Z"), Var("X")));
		// X = Y,
		// Y = Z.
		assertSubstitution(Var("X"), Var("Y"));
		assertSubstitution(Var("Y"), Var("Z"));
		assertNoSubstitution(Var("Z"));
	}

	function test_unify_should_unify_variable_with_multiple_variables() public {
		// ?- family(X, Y) = family(Y, Z).
		assertUnify(family(Var("X"), Var("Y")), family(Var("Y"), Var("Z")));
		// X = Y,
		// Y = Z.
		assertSubstitution(Var("X"), Var("Y"));
		assertSubstitution(Var("Y"), Var("Z"));
		assertNoSubstitution(Var("Z"));
	}

	function test_unify_should_unify_variable_with_variable_that_already_has_substitution() public {
		// ?- family(Y, X) = family(Z, Y).
		assertUnify(family(Var("Y"), Var("X")), family(Var("Z"), Var("Y")));
		// Y = Z,
		// X = Y.
		// NOTE: SWI Prolog answers Y = X, X = Z.
		assertSubstitution(Var("Y"), Var("Z"));
		assertSubstitution(Var("X"), Var("Y"));
		assertNoSubstitution(Var("Z"));
	}

	function test_unify_should_unify_variables_that_already_have_substitutions_with_other_variables() public {
		// ?- family(X, Y, X) = family(W, V, V).
		assertUnify(family(Var("X"), Var("Y"), Var("X")), family(Var("W"), Var("V"), Var("V")));
		// X = W,
		// Y = V,
		// W = V,
		// NOTE: SWI Prolog answers X = Y, Y = W, W = V.
		assertSubstitution(Var("X"), Var("W"));
		assertSubstitution(Var("Y"), Var("V"));
		assertSubstitution(Var("W"), Var("V"));
		assertNoSubstitution(Var("V"));
	}

	function test_unify_should_unify_nested_variable_with_both_variable_and_atom() public {
		// ?- family(X, Y) = family(Y, adam).
		assertUnify(family(Var("X"), Var("Y")), family(Var("Y"), atom("adam")));
		// X = Y,
		// Y = adam.
		assertSubstitution(Var("X"), Var("Y"));
		assertSubstitution(Var("Y"), atom("adam"));
	}

	function test_unify_should_unify_variable_with_predicate_containing_that_variable() public {
		// ?- X = family(adam, X).
		assertUnify(Var("X"), family(atom("adam"), Var("X")));
		// X = family(adam, X).
		assertSubstitution(Var("X"), family(atom("adam"), Var("X")));
	}

	function test_unify_should_unify_nested_variable_with_nested_predicate_containing_variable() public {
		// ?- family(X) = family(family(Y)).
		assertUnify(family(Var("X")), family(family(Var("Y"))));
		// X = family(Y).
		assertSubstitution(Var("X"), family(Var("Y")));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_variables_with_predicates_that_contain_cycles() public {
		// ?- family(X, Y) = family(family(Y), family(X)).
		assertUnify(family(Var("X"), Var("Y")), family(family(Var("Y")), family(Var("X"))));
		// X = family(Y),
		// Y = family(X).
		// NOTE: SWI Prolog answers X = Y, Y = family(family(Y)).
		assertSubstitution(Var("X"), family(Var("Y")));
		assertSubstitution(Var("Y"), family(Var("X")));
	}

	function test_unify_should_unify_variables_with_predicates_that_contain_mutually_dependent_cycles() public {
		// ?- family(X, Y) = family(family(X, Y), family(X, Y)).
		assertUnify(family(Var("X"), Var("Y")), family(family(Var("X"), Var("Y")), family(Var("X"), Var("Y"))));
		// X = family(X, Y),
		// Y = family(X, Y).
		// NOTE: SWI Prolog answers X = Y, Y = _S2, % where
		//     _S1 = family(_S1, _S2),
		//     _S2 = family(_S1, _S2).
		assertSubstitution(Var("X"), family(Var("X"), Var("Y")));
		assertSubstitution(Var("Y"), family(Var("X"), Var("Y")));
	}

	function test_unify_should_capture_substitutions_resulting_from_unifying_multiple_values_of_the_same_variable() public {
		// ?- family(X, X, Y) = family(family(Y), family(adam), Z).
		assertUnify(family(Var("X"), Var("X"), Var("Y")), family(family(Var("Y")), family("adam"), Var("Z")));
		// X = family(Y),
		// Y = adam,
		// Z = adam.
		// NOTE: SWI Prolog answers X = family(adam), Y = Z, Z = adam.
		assertSubstitution(Var("X"), family(Var("Y")));
		assertSubstitution(Var("Y"), atom("adam"));
		assertSubstitution(Var("Z"), atom("adam"));
	}
}
