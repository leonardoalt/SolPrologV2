// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

enum TermKind {
	Number,
	Ignore,
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

contract TermBuilder {
	function term(bytes memory _symbol) internal pure returns (Term memory) {
		Term memory t;
		t.kind = TermKind.Predicate;
		t.symbol = uint(keccak256(_symbol));
		return t;
	}

	function term(bytes memory _symbol, uint _argumentCount) internal pure returns (Term memory) {
		Term memory t = term(_symbol);
		t.arguments = new Term[](_argumentCount);
		return t;
	}

	function compare(Term storage _term1, Term memory _term2) internal view returns (bool) {
		if (_term1.kind != _term2.kind || _term1.symbol != _term2.symbol || _term1.arguments.length != _term2.arguments.length)
			return false;

		for (uint i = 0; i < _term1.arguments.length; ++i)
			if (!compare(_term1.arguments[i], _term2.arguments[i]))
				return false;

		return true;
	}
}
