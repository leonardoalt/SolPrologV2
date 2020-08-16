// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Logic.sol";
import "./Builder.sol";
import "./Prolog.sol";


contract Fixtures is TermBuilder {
	using RuleBuilder for Rule[];

	function loadRulesAtoms(Rule[] storage _rules) internal {
		// adam.
		// eve.
		_rules.add(atom("adam"));
		_rules.add(atom("eve"));
	}

	function loadRulesManWoman(Rule[] storage _rules) internal {
		// man(adam).
		// man(peter).
		// man(paul).
		// man(john).
		// man(hal).
		// man(tom).
		_rules.add(pred("man", atom("adam")));
		_rules.add(pred("man", atom("peter")));
		_rules.add(pred("man", atom("paul")));
		_rules.add(pred("man", atom("john")));
		_rules.add(pred("man", atom("hal")));
		_rules.add(pred("man", atom("tom")));

		// woman(mary).
		// woman(eve).
		_rules.add(pred("woman", atom("mary")));
		_rules.add(pred("woman", atom("eve")));
	}

	function loadRulesParent(Rule[] storage _rules) internal {
		// parent(adam, peter).
		// parent(eve,  peter).
		// parent(adam, paul).
		// parent(mary, paul).
		_rules.add(pred("parent", atom("adam"), atom("peter")));
		_rules.add(pred("parent", atom("eve"),  atom("peter")));
		_rules.add(pred("parent", atom("adam"), atom("paul")));
		_rules.add(pred("parent", atom("mary"), atom("paul")));
		_rules.add(pred("parent", atom("john"), atom("adam")));
		_rules.add(pred("parent", atom("hal"),  atom("john")));
		_rules.add(pred("parent", atom("tom"),  atom("hal")));
	}

	function loadRulesAnything(Rule[] storage _rules) internal {
		// anything(X).
		_rules.add(pred("anything", Var("X")));
	}

	function loadRulesFatherMother(Rule[] storage _rules) internal {
		loadRulesManWoman(_rules);
		loadRulesParent(_rules);

		// father(F, C) :- man(F), parent(F, C).
		// mother(M, C) :- woman(M), parent(M, C).
		_rules.add(pred("father", Var("F"), Var("C")), pred("man", Var("F")), pred("parent", Var("F"), Var("C")));
		_rules.add(pred("mother", Var("M"), Var("C")), pred("woman", Var("M")), pred("parent", Var("M"), Var("C")));
	}

	function loadRulesHuman(Rule[] storage _rules) internal {
		loadRulesManWoman(_rules);

		// human(H) :- man(H).
		// human(H) :- woman(H).
		_rules.add(pred("human", Var("H")), pred("man", Var("H")));
		_rules.add(pred("human", Var("H")), pred("woman", Var("H")));
	}

	function loadRulesDescendant(Rule[] storage _rules) internal {
		loadRulesParent(_rules);

		// descendant(D, A) :- parent(A, D).
		// descendant(D, A) :- parent(P, D), descendant(P, A).
		_rules.add(pred("descendant", Var("D"), Var("A")), pred("parent", Var("A"), Var("D")));
		_rules.add(pred("descendant", Var("D"), Var("A")), pred("parent", Var("P"), Var("D")), pred("descendant", Var("P"), Var("A")));
	}

	function loadRulesGrandfather(Rule[] storage _rules) internal {
		loadRulesFatherMother(_rules);

		// grandfather(C, F) :- father(C, X), parent(X, F).
		_rules.add(pred("grandfather", Var("C"), Var("F")), pred("father", Var("C"), Var("X")), pred("parent", Var("X"), Var("F")));
	}
}


contract PrologTestBase is DSTest, TermBuilder, Fixtures {
	using Logic for Term;
	using Substitution for Substitution.Info;

	Rule[] rules;
	Substitution.Info substitutions;

	function setUp() public {
	}

	function assertGoal(Term memory _goal) internal {
		assert(Prolog.query(_goal, rules, substitutions));
	}

	function assertGoals(Term memory _goal1, Term memory _goal2) internal {
		Term[] memory goals = new Term[](2);
		goals[0] = _goal1;
		goals[1] = _goal2;

		assert(Prolog.query(goals, rules, substitutions));
	}

	function assertRefute(Term memory _goal) internal {
		assert(!Prolog.query(_goal, rules, substitutions));
	}

	function assertRefute(Term memory _goal1, Term memory _goal2) internal {
		Term[] memory goals = new Term[](2);
		goals[0] = _goal1;
		goals[1] = _goal2;

		assert(!Prolog.query(goals, rules, substitutions));
	}

	function assertSubstitution(Term memory _to, Term memory _from) internal view {
		require(_to.kind == TermKind.Variable);
		Logic.validate(_to);
		Logic.validate(_from);

		assert(substitutions.usedKeys.length > 0);
		assert(substitutions.get(_to).equalsMemory(_from));
	}

	function assertReachableViaSubstitutionChain(Term memory _to, Term memory _from) internal view {
		assert(substitutions.usedKeys.length > 0);
		assert(Unification.reachableViaSubstitutionChain(_to, _from, substitutions));
	}

	function assertNoSubstitution(Term memory _to) internal view {
		require(_to.kind == TermKind.Variable);
		Logic.validate(_to);

		assert(substitutions.usedKeys.length == 0 || substitutions.get(_to).isEmptyMemory());
	}
}


contract PrologEmptyTest is PrologTestBase {
	function test_query_should_fail_if_database_empty() public {
		// ?- adam.
		assertRefute(atom("adam"));
	}

	function test_query_should_succeed_if_no_goals_and_database_empty() public {
		Term[] memory goals;
		assert(Prolog.query(goals, rules, substitutions));
	}

	function test_query_should_succeed_if_no_goals_and_database_non_empty() public {
		loadRulesAtoms(rules);

		Term[] memory goals;
		assert(Prolog.query(goals, rules, substitutions));
	}
}


contract PrologLiteralGoalTest is PrologTestBase {
	function test_query_should_succeed_if_atom_matches_fact() public {
		loadRulesAtoms(rules);

		// ?- adam.
		assertGoal(atom("adam"));
	}

	function test_query_should_fail_if_atom_matches_no_clause() public {
		loadRulesAtoms(rules);

		// ?- eve.
		assertRefute(atom("dave"));
	}

	function test_query_should_succeed_if_single_argument_predicate_matches_fact() public {
		loadRulesManWoman(rules);

		// ?- man(adam).
		assertGoal(pred("man", atom("adam")));
	}

	function test_query_should_fail_if_single_argument_predicate_matches_no_clause() public {
		loadRulesManWoman(rules);

		// ?- woman(adam).
		assertRefute(pred("woman", atom("adam")));
	}

	function test_query_should_succeed_if_two_argument_predicate_matches_fact() public {
		loadRulesParent(rules);

		// ?- parent(adam, peter).
		assertGoal(pred("parent", atom("adam"), atom("peter")));
	}

	function test_query_should_fail_if_two_argument_predicate_matches_no_clause() public {
		loadRulesParent(rules);

		// ?- parent(adam, eve).
		assertRefute(pred("parent", atom("adam"), atom("eve")));
	}

	function test_query_should_succeed_if_literal_predicate_matches_fact_with_variables() public {
		loadRulesAnything(rules);

		// anything(adam).
		assertGoal(pred("anything", atom("adam")));
	}

	function test_query_should_succeed_if_literal_predicate_can_satisfy_all_goals_in_a_rule() public {
		loadRulesFatherMother(rules);

		// father(adam, paul).
		assertGoal(pred("father", atom("adam"), atom("paul")));
	}

	function test_query_should_fail_if_literal_predicate_cannot_satisfy_first_goal_in_a_rule() public {
		loadRulesFatherMother(rules);

		// father(eve, peter).
		assertRefute(pred("father", atom("eve"), atom("peter")));
	}

	function test_query_should_fail_if_literal_predicate_cannot_satisfy_second_goal_in_a_rule() public {
		loadRulesFatherMother(rules);

		// father(peter, adam).
		assertRefute(pred("father", atom("peter"), atom("adam")));
	}

	function test_query_should_succeed_for_two_goals_if_both_can_be_satisfied() public {
		loadRulesFatherMother(rules);

		// father(adam, paul), man(adam).
		assertGoals(pred("father", atom("adam"), atom("paul")), pred("man", atom("adam")));
	}

	function test_query_should_fail_for_two_goals_if_first_cannot_be_satisfied() public {
		loadRulesFatherMother(rules);

		// mother(adam, paul), man(adam).
		assertRefute(pred("mother", atom("adam"), atom("paul")), pred("man", atom("adam")));
	}

	function test_query_should_fail_for_two_goals_if_second_cannot_be_satisfied() public {
		loadRulesFatherMother(rules);

		// father(adam, paul), woman(adam).
		assertRefute(pred("father", atom("adam"), atom("paul")), pred("woman", atom("adam")));
	}

	function test_query_should_fail_for_two_goals_if_both_cannot_be_satisfied() public {
		loadRulesFatherMother(rules);

		// mother(adam, paul), woman(adam).
		assertRefute(pred("mother", atom("adam"), atom("paul")), pred("woman", atom("adam")));
	}

	function test_query_should_backtrack() public {
		loadRulesHuman(rules);

		// human(eve), human(adam).
		assertGoals(pred("human", atom("eve")), pred("human", atom("adam")));
	}

	function test_query_should_follow_recursive_rules() public {
		loadRulesDescendant(rules);

		// descendant(adam, tom).
		assertGoal(pred("descendant", atom("adam"), atom("tom")));
	}

	function test_query_should_fail_if_recursive_rule_application_fails_unification_down_the_chain() public {
		loadRulesDescendant(rules);

		// descendant(adam, eve).
		assertRefute(pred("descendant", atom("adam"), atom("eve")));
	}

	function test_query_should_not_conflate_variables_with_same_names_from_different_rules() public {
		loadRulesGrandfather(rules);

		// This can only match anything if C and F used in father() are treated as distinct from the ones in grandfather().
		// grandfather(john, paul).
		assertGoal(pred("grandfather", atom("john"), atom("paul")));
	}
}

contract PrologGoalWithVariablesTest is PrologTestBase {
	function test_query_should_unify_goal_variable_with_any_fact_atom() public {
		loadRulesAtoms(rules);

		// ?- adam.
		assertGoal(Var("X"));
		assertSubstitution(Var("X"), atom("adam"));
	}

	function test_query_should_unify_goal_variable_with_any_rule() public {
		rules.add(pred("abc", Var("X")), pred("xyz", Var("X")));
		rules.add(pred("xyz", Var("X")));

		// ?- adam.
		assertGoal(Var("X"));
		assert(substitutions.get(Var("X")).kind == TermKind.Predicate);
		assert(substitutions.get(Var("X")).symbol == atom("abc").symbol);
		assert(substitutions.get(Var("X")).arguments.length == 1);
		assert(substitutions.get(Var("X")).arguments[0].kind == TermKind.Variable);
		assert(substitutions.get(Var("X")).arguments[0].symbol != Var("X").symbol);
	}

	function test_query_should_unify_goal_variable_with_matching_fact_predicate() public {
		loadRulesParent(rules);

		// ?- parent(X, peter).
		assertGoal(pred("parent", Var("X"), atom("peter")));
		assertSubstitution(Var("X"), atom("adam"));
	}

	function test_query_should_not_unify_goal_variable_if_whole_predicate_does_not_match() public {
		loadRulesParent(rules);

		// ?- parent(peter, X).
		assertRefute(pred("parent", atom("peter"), Var("X")));
		assertNoSubstitution(Var("X"));
	}

	function test_query_should_unify_goal_variable_with_matching_rule() public {
		loadRulesFatherMother(rules);

		// ?- mother(X, peter).
		assertGoal(pred("mother", Var("X"), atom("peter")));
		assertReachableViaSubstitutionChain(Var("X"), atom("eve"));
	}

	function test_query_should_succeed_if_predicate_with_variables_matches_fact_with_variables() public {
		loadRulesAnything(rules);

		// anything(X).
		assertGoal(pred("anything", Var("X")));
		assert(substitutions.get(Var("X")).kind == TermKind.Variable);
		assert(substitutions.get(Var("X")).symbol != Var("X").symbol);
	}

	function test_query_should_unify_goal_variable_with_matching_tail_of_recursive_rule() public {
		loadRulesDescendant(rules);

		// descendant(X, john).
		assertGoal(pred("descendant", Var("X"), atom("john")));
		assertReachableViaSubstitutionChain(Var("X"), atom("adam"));
	}

	function test_query_should_unify_goal_variable_with_matching_recursive_rule() public {
		loadRulesDescendant(rules);

		// descendant(X, Y), descendant(Y, john).
		assertGoals(pred("descendant", Var("X"), Var("Y")), pred("descendant", Var("Y"), atom("john")));
		assertReachableViaSubstitutionChain(Var("X"), atom("peter"));
		assertReachableViaSubstitutionChain(Var("Y"), atom("adam"));
	}

	function test_query_should_not_conflate_goal_variables_with_rule_variables_with_same_name() public {
		loadRulesFatherMother(rules);

		// This can only match anything if C and F used in the goal are treated as distinct from the ones in the father() rule.
		// father(C, F).
		assertGoal(pred("father", Var("C"), Var("F")));
		assertReachableViaSubstitutionChain(Var("C"), atom("adam"));
		assertReachableViaSubstitutionChain(Var("F"), atom("peter"));
	}
}
