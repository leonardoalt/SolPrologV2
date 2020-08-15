// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;

import './Logic.sol';

library Substitution {
	using Logic for Term;

	struct Info {
		mapping (uint => mapping (bytes32 => Term)) frames;
		uint[][] usedKeys;
	}

	function set(Info storage _info, Term memory _term1, Term memory _term2) internal {
		set(_info, _term1.hashMemory(), _term2);
	}

	function set(Info storage _info, bytes32 _hash, Term memory _term) internal {
		require(_info.usedKeys.length > 0);

		uint frame = _info.usedKeys.length - 1;
		set(_info.frames[frame][_hash], _term);
		_info.usedKeys[frame].push(uint(_hash));
	}

	function set(Term storage _to, Term memory _from) internal {
		_to.fromMemory(_from);
	}

	function get(Info storage _info, bytes32 _hash) internal view returns (Term memory) {
		require(_info.usedKeys.length > 0);

		uint frame = _info.usedKeys.length - 1;
		return _info.frames[frame][_hash];
	}

	function get(Info storage _info, Term memory _term) internal view returns (Term memory) {
		return get(_info, _term.hashMemory());
	}

	function push(Info storage _info) internal {
		_info.usedKeys.push();
	}

	function pop(Info storage _info) internal {
		require(_info.usedKeys.length > 0);

		uint frame = _info.usedKeys.length - 1;
		for (uint i = 0; i < _info.usedKeys[frame].length; ++i)
			delete _info.frames[frame][bytes32(_info.usedKeys[frame][i])];
		_info.usedKeys.pop();
	}

	function dup(Info storage _info) internal {
		push(_info);

		if (_info.usedKeys.length == 1)
			return;

		uint srcFrame = _info.usedKeys.length - 2;
		for (uint i = 0; i < _info.usedKeys[srcFrame].length; ++i) {
			bytes32 hash = bytes32(_info.usedKeys[srcFrame][i]);

			set(_info, hash, _info.frames[srcFrame][hash]);
		}
	}

	function clear(Info storage _info) internal {
		while (_info.usedKeys.length > 0)
			pop(_info);
	}

	function followSubstitutionChain(
		Info storage _info,
		Term memory _term
	) internal view returns (Term memory) {

		bytes32 currentHash = _term.hashMemory();
		Term memory currentTerm = _term;

		while (!get(_info, currentHash).isEmptyMemory()) {
			currentTerm = get(_info, currentHash);
			currentHash = currentTerm.hashMemory();
		}

		return currentTerm;
	}
}
