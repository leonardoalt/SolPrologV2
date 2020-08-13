// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import './Logic.sol';
import './Substitution.sol';
import './Unification.sol';

library Prolog {
	using Substitution for Substitution.Info;

	function query(Term memory _goal, Rule[] storage _rules, Substitution.Info storage _substitutions) internal returns (bool) {
		Term[] memory goals = new Term[](1);
		goals[0] = _goal;

		return query(goals, _rules, _substitutions);
	}

	function query(Term[] memory _goals, Rule[] storage _rules, Substitution.Info storage _substitutions) internal returns (bool) {
		if (_goals.length == 0)
			return true;

		if (_rules.length == 0)
			return false;

		for (uint i = 0; i < _rules.length; ++i) {
			_substitutions.dup();
			Rule memory rewrittenRule = rewriteVariables(_rules[i], _substitutions.usedKeys.length);

			if (Unification.unify(_goals[0], rewrittenRule.head, _substitutions)) {
				Term[] memory unifiedGoals = new Term[](_goals.length - 1 + rewrittenRule.body.length);

				for (uint g = 0; g < rewrittenRule.body.length; ++g)
					unifiedGoals[g] =  rewrittenRule.body[g];

				for (uint g = 1; g < _goals.length; ++g)
					unifiedGoals[rewrittenRule.body.length + g - 1] =  _goals[g];

				bool success = query(unifiedGoals, _rules, _substitutions);
				if (success) {
					return true;
				}
			}

			_substitutions.pop();
		}

		return false;
	}

	function rewriteVariables(Rule memory _rule, uint _uniqueContext) private pure returns (Rule memory) {
		Rule memory rewrittenRule;
		rewrittenRule.head = rewriteVariables(_rule.head, _uniqueContext);

		rewrittenRule.body = new Term[](_rule.body.length);
		for (uint i = 0; i < _rule.body.length; ++i)
			rewrittenRule.body[i] = rewriteVariables(_rule.body[i], _uniqueContext);

		return rewrittenRule;
	}

	function rewriteVariables(Term memory _term, uint _uniqueContext) private pure returns (Term memory) {
		Term memory rewrittenTerm;
		rewrittenTerm.kind = _term.kind;
		rewrittenTerm.symbol = (_term.kind == TermKind.Variable ? rewriteVariable(_term.symbol, _uniqueContext) : _term.symbol);

		rewrittenTerm.arguments = new Term[](_term.arguments.length);
		for (uint i = 0; i < _term.arguments.length; ++i)
			rewrittenTerm.arguments[i] = rewriteVariables(_term.arguments[i], _uniqueContext);

		if (_term.kind == TermKind.Variable) {
			rewrittenTerm.symbol = rewriteVariable(_term.symbol, _uniqueContext);
		}

		return rewrittenTerm;
	}

	function rewriteVariable(uint _symbol, uint _uniqueContext) private pure returns (uint) {
		bytes32[] memory input = new bytes32[](2);
		input[0] = bytes32(_symbol);
		input[1] = bytes32(_uniqueContext);
		return uint(keccak256(abi.encodePacked(input)));
	}
}
