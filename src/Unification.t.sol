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

	function list(Term memory _element1) internal pure returns (Term memory) {
		Term memory l = list();
		l.arguments = new Term[](1);
		l.arguments[0] = _element1;
		return l;
	}

	function list(Term memory _element1, Term memory _element2) internal pure returns (Term memory) {
		Term memory l = list();
		l.arguments = new Term[](2);
		l.arguments[0] = _element1;
		l.arguments[1] = _element2;
		return l;
	}

	function list(Term memory _element1, Term memory _element2, Term memory _element3) internal pure returns (Term memory) {
		Term memory l = list();
		l.arguments = new Term[](3);
		l.arguments[0] = _element1;
		l.arguments[1] = _element2;
		l.arguments[2] = _element3;
		return l;
	}

	function list(uint _element1) internal pure returns (Term memory) {
		return list(num(_element1));
	}

	function list(uint _element1, uint _element2) internal pure returns (Term memory) {
		return list(num(_element1), num(_element2));
	}

	function list(uint _element1, uint _element2, uint _element3) internal pure returns (Term memory) {
		return list(num(_element1), num(_element2), num(_element3));
	}

	function listHT(Term memory _headElement1, Term memory _tail) internal pure returns (Term memory) {
		Term memory l = listHT(1, _tail);
		l.arguments[0] = _headElement1;
		return l;
	}

	function listHT(Term memory _headElement1, Term memory _headElement2, Term memory _tail) internal pure returns (Term memory) {
		Term memory l = listHT(2, _tail);
		l.arguments[0] = _headElement1;
		l.arguments[1] = _headElement2;
		return l;
	}

	function listHT(Term memory _headElement1, Term memory _headElement2, Term memory _headElement3, Term memory _tail) internal pure returns (Term memory) {
		Term memory l = listHT(3, _tail);
		l.arguments[0] = _headElement1;
		l.arguments[1] = _headElement2;
		l.arguments[2] = _headElement3;
		return l;
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


contract IgnoreUnificationTest is UnificationTestBase {
	function test_unify_should_unify_ignore_with_ignore() public {
		// ?- _ = _.
		assertUnify(ignore(), ignore());
	}

	function test_unify_should_unify_ignore_with_any_literal() public {
		// ?- _ = adam.
		assertUnify(ignore(), atom("adam"));
		// true.

		// ?- adam = _.
		assertUnify(atom("adam"), ignore());
		// true.

		// ?- _ = 1.
		assertUnify(ignore(), num(1));
		// true.

		// ?- _ = family(adam, paul).
		assertUnify(ignore(), family("adam", "paul"));
		// true.
	}

	function test_unify_should_not_unify_ignore_in_different_predicates() public {
		// ?- family(_) = man(_).
		assertNotUnify(pred("family", ignore()), pred("man", ignore()));
		// false.
	}

	function test_unify_should_unify_ignore_with_variable() public {
		// ?- _ = X.
		assertUnify(ignore(), Var("X"));
		// true.
		assertNoSubstitution(Var("X"));
	}

	function test_unify_should_unify_ignore_with_predicate_containing_variable() public {
		// ?- _ = family(adam, x).
		assertUnify(ignore(), family(atom("adam"), Var("X")));
		// true.
		assertNoSubstitution(Var("X"));
	}

	function test_unify_should_unify_ignore_with_predicate_containing_ignore() public {
		// ?- _ = family(adam, _).
		assertUnify(ignore(), family(atom("adam"), ignore()));
		// true.
	}

	function test_unify_should_not_unify_ignore_with_multiple_arguments() public {
		// ?- family(_) = family(adam, eve).
		assertNotUnify(family(ignore()), family("adam", "eve"));
		// false.

		// ?- family(_) = family(_, _).
		assertNotUnify(family(ignore()), family(ignore(), ignore()));
		// false.
	}

	function test_unify_should_unify_nested_ignore_with_literal() public {
		// ?- family(_, paul) = family(adam, paul).
		assertUnify(family(ignore(), atom("paul")), family("adam", "paul"));
		// true.
	}

	function test_unify_should_unify_ignore_with_multiple_different_literals() public {
		// ?- family(_, paul) = family(adam, _).
		assertUnify(family(ignore(), atom("paul")), family(atom("adam"), ignore()));
		// true.

		// ?- family(_, _) = family(adam, family(paul, eve)).
		assertUnify(family(ignore(), ignore()), family(atom("adam"), family("paul", "")));
		// true.
	}

	function test_unify_should_not_unify_multiple_ignores_with_a_single_argument() public {
		// ?- family(_, _) = family(adam).
		assertNotUnify(family(ignore(), ignore()), family("adam"));
		// false.
	}

	function test_unify_should_not_allow_using_ignore_to_skip_arguments() public {
		// ?- family = family(_).
		assertNotUnify(atom("family"), family(ignore()));
		// false.

		// ?- family(adam) = family(adam, _).
		assertNotUnify(family("adam"), family(atom("adam"), ignore()));
		// false.
	}

	function test_unify_should_unify_nested_ignore_with_ignore() public {
		// ?- family(_, paul) = family(_, paul).
		assertUnify(family(ignore(), atom("adam")), family(ignore(), atom("adam")));
		// true.
	}

	function test_unify_should_unify_nested_ignore_with_variable_that_has_a_substitution_to_another_variable() public {
		// ?- family(X, X) = family(Y, _).
		assertUnify(family(Var("X"), Var("X")), family(Var("Y"), ignore()));
		// X = Y.
		assertSubstitution(Var("X"), Var("Y"));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_nested_ignore_with_variable_that_has_a_substitution_to_atom() public {
		// ?- family(X, X) = family(adam, _).
		assertUnify(family(Var("X"), Var("X")), family(atom("adam"), ignore()));
		// X = adam.
		assertSubstitution(Var("X"), atom("adam"));
		assertNoSubstitution(Var("Y"));
	}
}


contract ListUnificationTest is UnificationTestBase {
	function test_unify_should_unify_empty_list_only_with_that_exact_literal() public {
		// ?- [] = [].
		assertUnify(list(), list());
		// true.

		// ?- [] = 1.
		assertNotUnify(list(), num(1));
		// false.

		// ?- [] = adam.
		assertNotUnify(list(), atom("adam"));
		// false.
	}

	function test_unify_should_unify_single_element_list_of_numbers_only_with_that_exact_literal() public {
		// ?- [1] = [1].
		assertUnify(list(1), list(1));
		// true.

		// ?- [1] = [].
		assertNotUnify(list(1), list());
		// false.

		// ?- [1] = [2].
		assertNotUnify(list(1), list(2));
		// false.
	}

	function test_unify_should_unify_multi_element_list_of_numbers_only_with_that_exact_literal() public {
		// ?- [1, 2] = [1, 2].
		assertUnify(list(1, 2), list(1, 2));
		// true.

		// ?- [1, 2, 3] = [1, 2, 3].
		assertUnify(list(1, 2, 3), list(1, 2, 3));
		// true.

		// ?- [1, 2] = [2, 1].
		assertNotUnify(list(1, 2), list(2, 1));
		// false.

		// ?- [1, 2] = [1, 2, 3].
		assertNotUnify(list(1, 2), list(1, 2, 3));
		// false.
	}

	function test_unify_should_unify_list_of_atoms_only_with_that_exact_literal() public {
		// ?- [adam, eve] = [adam, eve].
		assertUnify(list(atom("adam"), atom("eve")), list(atom("adam"), atom("eve")));
		// true.
	}

	function test_unify_should_unify_list_of_predicates_only_with_that_exact_literal() public {
		// ?- [family(adam, eve), family(eve, paul)] = [family(adam, eve), family(eve, paul)].
		assertUnify(list(family("adam", "eve"), family("eve", "paul")), list(family("adam", "eve"), family("eve", "paul")));
		// true.
	}

	function test_unify_should_unify_list_of_lists_only_with_that_exact_literal() public {
		// ?- [[1, 2], 3] = [[1, 2], 3].
		assertUnify(list(list(1, 2), num(3)), list(list(1, 2), num(3)));
		// true.

		// ?- [[1, 2], 3] = [1, [2, 3]].
		assertNotUnify(list(list(1, 2), num(3)), list(num(1), list(2, 3)));
		// false.

		// ?- [1, 2, 3] = [1, [2, [3]]].
		assertNotUnify(list(1, 2, 3), list(num(1), list(num(2), list(3))));
		// false.
	}

	function test_unify_should_unify_empty_list_with_variable() public {
		// ?- [] = X.
		assertUnify(list(), Var("X"));
		// X = [].
		assertSubstitution(Var("X"), list());
	}

	function test_unify_should_unify_list_with_variable() public {
		// ?- X = [1, 2, 3].
		assertUnify(Var("X"), list(1, 2, 3));
		// X = [1, 2, 3].
		assertSubstitution(Var("X"), list(1, 2, 3));
	}

	function test_unify_should_unify_empty_list_with_ignore() public {
		// ?- [] = _.
		assertUnify(list(), ignore());
		// true.
	}

	function test_unify_should_unify_single_element_variable_list_with_literal_list() public {
		// ?- [X] = [1].
		assertUnify(list(Var("X")), list(1));
		// X = 1.
		assertSubstitution(Var("X"), num(1));
	}

	function test_unify_should_unify_multi_element_variable_list_with_literal_list() public {
		// ?- [X, Y] = [1, 2].
		assertUnify(list(Var("X"), Var("Y")), list(1, 2));
		// X = 1,
		// Y = 2.
		assertSubstitution(Var("X"), num(1));
		assertSubstitution(Var("Y"), num(2));
	}

	function test_unify_should_unify_multiple_instances_of_same_variable_on_the_list_with_same_literal() public {
		// ?- [X, X] = [1, 1].
		assertUnify(list(Var("X"), Var("X")), list(1, 1));
		// X = 1.
		assertSubstitution(Var("X"), num(1));
	}

	function test_unify_should_unify_variable_with_nested_list() public {
		// ?- [[1, 2], Y] = [X, [3, 4]].
		assertUnify(list(list(1, 2), Var("Y")), list(Var("X"), list(3, 4)));
		// Y = [3, 4],
		// X = [1, 2].
		assertSubstitution(Var("Y"), list(3, 4));
		assertSubstitution(Var("X"), list(1, 2));
	}

	function test_unify_should_not_unify_nested_variable_with_multiple_list_elements() public {
		// ?- [X] = [1, 2].
		assertNotUnify(list(Var("X")), list(1, 2));
		// false.
	}

	function test_unify_should_unify_variable_with_list_containing_that_variable() public {
		// ?- X = [X].
		assertUnify(Var("X"), list(Var("X")));
		// X = [X].
		assertSubstitution(Var("X"), list(Var("X")));
	}

	function test_unify_should_not_unify_predicate_arguments_with_list_of_those_arguments() public {
		// ?- family([adam, eve]) = family(adam, eve).
		assertNotUnify(family(list(atom("adam"), atom("eve"))), family(atom("adam"), atom("eve")));
		// false.
	}

	function test_unify_should_unify_ignore_with_list() public {
		// ?- [_, _] = _.
		assertUnify(list(ignore(), ignore()), ignore());
		// true.
	}

	function test_unify_should_unify_ignore_with_list_element() public {
		// ?- [1, 2] = [1, _].
		assertUnify(list(1, 2), list(num(1), ignore()));
		// true.
	}

	function test_unify_should_not_unify_ignore_with_multiple_list_elements() public {
		// ?- [1, 2] = [_].
		assertNotUnify(list(1, 2), list(ignore()));
		// false.
	}
}


contract ListHeadTailUnificationTest is UnificationTestBase {
	function test_unify_should_unify_empty_list_in_tail_with_zero_elements() public {
		// ?- [1|[]] = [1].
		assertUnify(listHT(num(1), list()), list(1));
		// true.
	}

	function test_unify_should_allow_tail_to_be_non_list_literal() public {
		// ?- [1|2] = [1|2].
		assertUnify(listHT(num(1), num(2)), listHT(num(1), num(2)));
		// true.

		// ?- [1|adam] = [1|adam].
		assertUnify(listHT(num(1), atom("adam")), listHT(num(1), atom("adam")));
		// true.

		// ?- [1|family(adam, eve)] = [1|family(adam, eve)].
		assertUnify(listHT(num(1), family("adam", "eve")), listHT(num(1), family("adam", "eve")));
		// true.
	}

	function test_unify_should_unify_ignore_in_tail_with_any_number_of_elements() public {
		// ?- [1|_] = [1].
		assertUnify(listHT(num(1), ignore()), list(1));
		// true.

		// ?- [1|_] = [1, 2].
		assertUnify(listHT(num(1), ignore()), list(1, 2));
		// true.

		// ?- [1|_] = [1, 2, 3].
		assertUnify(listHT(num(1), ignore()), list(1, 2, 3));
		// true.
	}

	function test_unify_should_unify_variable_in_tail_with_zero_elements() public {
		// ?- [1|T] = [1].
		assertUnify(listHT(num(1), Var("T")), list(1));
		// T = [].
		assertSubstitution(Var("T"), list());
	}

	function test_unify_should_unify_variable_in_tail_with_one_element() public {
		// ?- [1|T] = [1, 2].
		assertUnify(listHT(num(1), Var("T")), list(1, 2));
		// T = [2].
		assertSubstitution(Var("T"), list(2));
	}

	function test_unify_should_unify_variable_in_tail_with_two_elements() public {
		// ?- [1|T] = [1, 2, 3].
		assertUnify(listHT(num(1), Var("T")), list(1, 2, 3));
		// T = [2, 3].
		assertSubstitution(Var("T"), list(2, 3));
	}

	function test_unify_should_unify_list_in_tail() public {
		// ?- [1|[2]] = [1, 2].
		assertUnify(listHT(num(1), list(2)), list(1, 2));
		// true.

		// ?- [1|[2, 3]] = [1, 2, 3].
		assertUnify(listHT(num(1), list(2, 3)), list(1, 2, 3));
		// true.

		// ?- [1|[2|[3]]] = [1, 2, 3].
		assertUnify(listHT(num(1), listHT(num(2), list(3))), list(1, 2, 3));
		// true.
	}

	function test_unify_should_unify_multiple_elements_in_head() public {
		// ?- [1, 2|[3]] = [1, 2, 3].
		assertUnify(listHT(num(1), num(2), list(3)), list(1, 2, 3));
		// true.

		// ?- [1, 2, 3|[]] = [1, 2, 3].
		assertUnify(listHT(num(1), num(2), num(3), list()), list(1, 2, 3));
		// true.
	}

	function test_unify_should_allow_any_literal_in_head() public {
		// ?- [adam|[1]] = [adam, 1].
		assertUnify(listHT(atom("adam"), list(1)), list(atom("adam"), num(1)));
		// true.

		// ?- [family(adam, eve)|[1]] = [family(adam, eve), 1].
		assertUnify(listHT(family("adam", "eve"), list(1)), list(family("adam", "eve"), num(1)));
		// true.

		// ?- [[]|[1]] = [[], 1].
		assertUnify(listHT(list(), list(1)), list(list(), num(1)));
		// true.

		// ?- [[1, 2, 3]|[]] = [[1, 2, 3]].
		assertUnify(listHT(list(1, 2, 3), list()), list(list(1, 2, 3)));
		// true.

		// ?- [[1|[2]]|[3]] = [[1, 2], 3].
		assertUnify(listHT(listHT(num(1), list(2)), list(3)), list(list(1, 2), num(3)));
		// true.
	}

	function test_unify_should_unify_variable_in_head() public {
		// ?- [H|[1]] = [adam, 1].
		assertUnify(listHT(Var("H"), list(1)), list(atom("adam"), num(1)));
		// H = adam.
		assertSubstitution(Var("H"), atom("adam"));
	}

	function test_unify_should_unify_ignore_in_head() public {
		// ?- [_|[1]] = [adam, 1].
		assertUnify(listHT(ignore(), list(1)), list(atom("adam"), num(1)));
		// true.
	}

	function test_unify_should_not_unify_head_tail_list_with_non_list_literal() public {
		// ?- [H|T] = adam.
		assertNotUnify(listHT(Var("H"), Var("T")), atom("adam"));
		// false.

		// ?- [H|T] = 1.
		assertNotUnify(listHT(Var("H"), Var("T")), num(1));
		// false.

		// ?- [H|T] = family(adam, eve).
		assertNotUnify(listHT(Var("H"), Var("T")), family("adam", "eve"));
		// false.
	}

	function test_unify_should_unify_two_equivalent_head_tail_lists_with_different_heads() public {
		// ?- [1, 2|[3]] = [1|[2, 3]].
		assertUnify(listHT(num(1), num(2), list(3)), listHT(num(1), list(2, 3)));
		// true.
	}

	function test_unify_should_unify_head_tail_lists_with_equivalent_list_with_two_tails() public {
		// ?- [1, 2|3] = [1|[2|3]].
		assertUnify(listHT(num(1), num(2), num(3)), listHT(num(1), listHT(num(2), num(3))));
		// true.
	}

	function test_unify_should_unify_head_tail_lists_with_ignored_tails_only_if_heads_start_with_same_elements() public {
		// ?- [1, 2|_] = [1, 2|_].
		assertUnify(listHT(num(1), num(2), ignore()), listHT(num(1), num(2), ignore()));
		// true.

		// ?- [1, 2, 3|_] = [1, 2|_].
		assertUnify(listHT(num(1), num(2), num(3), ignore()), listHT(num(1), num(2), ignore()));
		// true.

		// ?- [1, 2|_] = [1, 2, 3|_].
		assertUnify(listHT(num(1), num(2), ignore()), listHT(num(1), num(2), num(3), ignore()));
		// true.

		// ?- [1, 3|_] = [1, 2, 3|_].
		assertNotUnify(listHT(num(1), num(3), ignore()), listHT(num(1), num(2), num(3), ignore()));
		// false.
	}

	function test_unify_should_unify_head_tail_list_with_variable() public {
		// ?- [H|T] = X.
		assertUnify(listHT(Var("H"), Var("T")), Var("X"));
		// X = [H|T].
		assertSubstitution(Var("X"), listHT(Var("H"), Var("T")));
		assertNoSubstitution(Var("H"));
		assertNoSubstitution(Var("T"));
	}

	function test_unify_should_unify_head_tail_list_with_ignore() public {
		// ?- [H|T] = _.
		assertUnify(listHT(Var("H"), Var("T")), ignore());
		// true.
		assertNoSubstitution(Var("H"));
		assertNoSubstitution(Var("T"));
	}

	function test_unify_should_unify_head_tail_list_containing_one_variable() public {
		// ?- [H|T] = [X].
		assertUnify(listHT(Var("H"), Var("T")), list(Var("X")));
		// H = X,
		// T = [].
		assertSubstitution(Var("H"), Var("X"));
		assertSubstitution(Var("T"), list());
		assertNoSubstitution(Var("X"));
	}

	function test_unify_should_unify_head_tail_list_containing_two_variables() public {
		// ?- [H|T] = [X, Y].
		assertUnify(listHT(Var("H"), Var("T")), list(Var("X"), Var("Y")));
		// H = X,
		// T = [Y].
		assertSubstitution(Var("H"), Var("X"));
		assertSubstitution(Var("T"), list(Var("Y")));
		assertNoSubstitution(Var("X"));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_head_tail_list_containing_variable_and_list_of_variables() public {
		// ?- [H|T] = [X, [Y]].
		assertUnify(listHT(Var("H"), Var("T")), list(Var("X"), list(Var("Y"))));
		// H = X,
		// T = [[Y]].
		assertSubstitution(Var("H"), Var("X"));
		assertSubstitution(Var("T"), list(list(Var("Y"))));
		assertNoSubstitution(Var("X"));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_head_tail_list_with_head_tail_list() public {
		// ?- [H|T] = [X|Y].
		assertUnify(listHT(Var("H"), Var("T")), listHT(Var("X"), Var("Y")));
		// H = X,
		// T = Y.
		assertSubstitution(Var("H"), Var("X"));
		assertSubstitution(Var("T"), Var("Y"));
		assertNoSubstitution(Var("X"));
		assertNoSubstitution(Var("Y"));
	}

	function test_unify_should_unify_head_with_tail_and_tail_with_head() public {
		// ?- [H|T] = [T|H].
		assertUnify(listHT(Var("H"), Var("T")), listHT(Var("T"), Var("H")));
		// H = T.
		assertSubstitution(Var("H"), Var("T"));
		assertNoSubstitution(Var("T"));
	}

	function test_unify_should_unify_head_with_tail_and_tail_with_list_containing_head() public {
		// ?- [H|T] = [T|[H]].
		assertUnify(listHT(Var("H"), Var("T")), listHT(Var("T"), list(Var("H"))));
		// H = T,
		// T = [H],
		// NOTE: SWI Prolog answers H = T, T = [T].
		assertSubstitution(Var("H"), Var("T"));
		assertSubstitution(Var("T"), list(Var("H")));
	}

	function test_unify_should_not_unify_head_tail_list_with_empty_list() public {
		// ?- [H|T] = [].
		assertNotUnify(listHT(Var("H"), Var("T")), list());
		// false.
	}

	function test_unify_should_not_unify_head_tail_list_with_two_element_head_with_one_element_list() public {
		// ?- [H1, H2|T] = [X].
		assertNotUnify(listHT(Var("H1"), Var("H2"), Var("T")), list(Var("X")));
		// false.
	}

	function test_unify_should_unify_head_tail_list_with_two_element_head_with_two_element_list() public {
		// ?- [H1, H2|T] = [X, Y].
		assertUnify(listHT(Var("H1"), Var("H2"), Var("T")), list(Var("X"), Var("Y")));
		// H1 = X,
		// H2 = Y,
		// T = [],
		assertSubstitution(Var("H1"), Var("X"));
		assertSubstitution(Var("H2"), Var("Y"));
		assertSubstitution(Var("T"), list());
		assertNoSubstitution(Var("X"));
		assertNoSubstitution(Var("Y"));
	}
}
