// SPDX-License-Identifier: GPL V3
pragma solidity ^0.7.0;

import 'Logic.sol';

contract Substitution {
	mapping (uint => mapping (bytes32 => Term)) frames;
	uint[][] usedKeys;

	function set(Term memory _term1, Term memory _term2) internal {
		bytes32 hash = Logic.hash(_term1);
		frames[currentFrame][hash] = _term2;
		usedKeys[usedKeys.length - 1].push(hash);
	}

	function push() internal {
		usedKeys.push();
	}

	function pop() internal {
		uint frame = usedKeys.length - 1;
		for (uint i = 0; i < usedKeys[frame].length; ++i)
			delete frames[frame][usedKeys[frame][i]];
		usedKeys.pop();
	}
}
