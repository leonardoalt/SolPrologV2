// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import './Logic.sol';
import './Substitution.sol';

library Unification {
	using Logic for Term;

	function unify(
		Term memory _term1,
		Term memory _term2,
		mapping(bytes32 => Term) storage io_substitutions
	) internal returns (bool) {

		Logic.validate(_term1);
		Logic.validate(_term2);

		if (_term1.kind == TermKind.Ignore || _term2.kind == TermKind.Ignore)
			return true;

		bytes32 hash1 = _term1.hashMemory();
		if (_term1.kind == TermKind.Variable) {
			if (!Logic.isEmptyStorage(io_substitutions[hash1]))
				return unify(io_substitutions[hash1].toMemory(), _term2, io_substitutions);

			if (!reachableViaSubstitutionChain(_term2, _term1, io_substitutions))
				Substitution.set(io_substitutions[hash1], _term2);

			return true;
		}

		if (_term2.kind == TermKind.Variable)
			return unify(_term2, _term1, io_substitutions);

		if (_term1.symbol != _term2.symbol)
			return false;

		if (_term1.kind == TermKind.List && _term2.kind == TermKind.ListHeadTail)
			return unify(_term2, _term1, io_substitutions);

		if (_term1.kind == TermKind.ListHeadTail && _term2.kind == TermKind.List) {
			if (_term2.arguments.length < _term1.arguments.length - 1)
				return false;

			return
				unifyArguments(0, _term1.arguments.length - 1, _term1, _term2, io_substitutions) &&
				unify(
					_term1.arguments[_term1.arguments.length - 1],
					tail(_term1.arguments.length - 1, _term2),
					io_substitutions
				);
		}

		if (_term1.kind == TermKind.ListHeadTail && _term2.kind == TermKind.ListHeadTail) {
			if (_term1.arguments.length > _term2.arguments.length)
				return unify(_term2, _term1, io_substitutions);

			return
				unifyArguments(0, _term1.arguments.length - 1, _term1, _term2, io_substitutions) &&
				unify(
					_term1.arguments[_term1.arguments.length - 1],
					extendedTailHT(_term1.arguments.length - 1, _term2),
					io_substitutions
				);
		}

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

	function tail(uint _begin, Term memory _list) internal pure returns (Term memory) {
		require(_list.kind == TermKind.List);
		require(_begin <= _list.arguments.length);

		Term memory listTail = Term(TermKind.List, 0, new Term[](_list.arguments.length - _begin));

		for (uint i = _begin; i < _list.arguments.length; ++i)
			listTail.arguments[i - _begin] = _list.arguments[i];

		return listTail;
	}

	function extendedTailHT(uint _begin, Term memory _listHT) internal pure returns (Term memory) {
		require(_listHT.kind == TermKind.ListHeadTail);
		require(_begin <= _listHT.arguments.length - 1);

		Term memory extendedTail = _listHT.arguments[_listHT.arguments.length - 1];
		for (uint i = _listHT.arguments.length - 1; i > _begin; --i) {
			// Shorten the head by putting one element in the tail.
			// This relies on the fact that [X, Y|Z] = [X|[Y|Z]].

			Term memory newTail = Term(TermKind.ListHeadTail, 0, new Term[](2));
			newTail.arguments[0] = _listHT.arguments[i - 1];
			newTail.arguments[1] = extendedTail;
			extendedTail = newTail;
		}

		return extendedTail;
	}

	function reachableViaSubstitutionChain(
		Term memory _origin,
		Term memory _target,
		mapping(bytes32 => Term) storage _substitutions
	) private view returns (bool) {

		if (_origin.equalsMemory(_target))
			return true;

		bytes32 currentHash = _origin.hashMemory();
		while (!Logic.isEmptyStorage(_substitutions[currentHash]) && !_substitutions[currentHash].equalsStorage(_target))
			currentHash =_substitutions[currentHash].hashStorage();

		return !Logic.isEmptyStorage(_substitutions[currentHash]);
	}
}
