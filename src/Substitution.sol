// SPDX-License-Identifier: GPL V3
pragma solidity ^0.7.0;

import 'Logic.sol';

library Substitution {
	struct Info {
		mapping (uint => mapping (bytes32 => Term)) frames;
		uint[][] usedKeys;
	}

	function set(Term memory _term1, Term memory _term2, Info storage _info) internal {
		bytes32 hash = Logic.hash(_term1);
		_info.frames[currentFrame][hash] = _term2;
		_info.usedKeys[usedKeys.length - 1].push(hash);
	}

	function get(Term memory _term, Info storage _info) internal returns (Term memory) {
		bytes32 hash = Logic.hash(_term);
		uint frame = _info.usedKeys.length - 1;
		return _info.frames[frame][hash];
	}

	function push(Info storage _info) internal {
		_info.usedKeys.push();
	}

	function pop(Info storage _info) internal {
		uint frame = _info.usedKeys.length - 1;
		for (uint i = 0; i < _info.usedKeys[frame].length; ++i)
			delete _info.frames[frame][_info.usedKeys[frame][i]];
		_info.usedKeys.pop();
	}
}
