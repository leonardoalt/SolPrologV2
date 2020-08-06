// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import './Logic.sol';
import './Substitution.sol';

library Unification {

	function unify(
		Term memory _term1,
		Term memory _term2,
		mapping(bytes32 => Term) storage io_substitutions
	) internal returns (bool) {

		Logic.validate(_term1);
		Logic.validate(_term2);

		bytes32 hash1 = Logic.hash(_term1);
		if (_term1.kind == TermKind.Variable) {
			if (!Logic.isEmptyStorage(io_substitutions[hash1]))
				return unify(Logic.copyToMemory(io_substitutions[hash1]), _term2, io_substitutions);

			if (!reachableViaSubstitutionChain(_term2, _term1, io_substitutions))
				Substitution.set(io_substitutions[hash1], _term2);

			return true;
		}

		if (_term2.kind == TermKind.Variable)
			return unify(_term2, _term1, io_substitutions);

		if (_term1.symbol != _term2.symbol)
			return false;

		if (_term1.arguments.length != _term2.arguments.length)
			return false;

		return unifyArguments(0, _term1.arguments.length, _term1, _term2, io_substitutions);
	}

	function unifyArguments(
		uint _begin,
		uint _end,
		Term memory _term1,
		Term memory _term2,
		mapping(bytes32 => Term) storage io_substitutions
	) private returns (bool) {

		require(_begin <= _end);
		require(_end <= _term1.arguments.length);
		require(_end <= _term2.arguments.length);

		for (uint i = _begin; i < _end; ++i)
			if (!unify(_term1.arguments[i], _term2.arguments[i], io_substitutions))
				return false;

		return true;
	}

	function reachableViaSubstitutionChain(
		Term memory _origin,
		Term memory _target,
		mapping(bytes32 => Term) storage _substitutions
	) private view returns (bool) {

		if (Logic.termsEqualInMemory(_origin, _target))
			return true;

		bytes32 currentHash = Logic.hash(_origin);
		while (!Logic.isEmptyStorage(_substitutions[currentHash]) && !Logic.termsEqualInStorage(_substitutions[currentHash], _target))
			currentHash = Logic.hashStorage(_substitutions[currentHash]);

		return !Logic.isEmptyStorage(_substitutions[currentHash]);
	}
}
