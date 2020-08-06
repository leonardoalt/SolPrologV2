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
}
