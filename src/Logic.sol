// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

enum TermKind {
	Number,
	Ignore,
	Literal,
	Variable,
	List,
	ListHeadTail,
	Predicate
}

struct Term {
	TermKind kind;
	uint symbol;
	Term[] arguments;
}

struct FrontendTerm {
	bytes value;
	FrontendTerm[] children;
}

struct Rule {
	Term head;
	Term[] body;
}

library Logic {
	function hash(Term memory _term) internal pure returns (bytes32) {
		bytes32[] memory args = new bytes32[](_term.arguments.length);
		for (uint i = 0; i < _term.arguments.length; ++i)
			args[i] = hash(_term.arguments[i]);
		return keccak256(abi.encodePacked(_term.kind, _term.symbol, args));
	}
}
