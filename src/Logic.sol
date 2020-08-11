// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

enum TermKind {
	Ignore,  // NOTE: We depend on Ignore being the first element (uninitialized terms must be of this kind)
	Number,
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

struct FrontendRule {
	FrontendTerm head;
	FrontendTerm[] body;
}

struct Rule {
	Term head;
	Term[] body;
}

library Logic {
	function hashMemory(Term memory _term) internal pure returns (bytes32) {
		bytes32[] memory args = new bytes32[](_term.arguments.length);
		for (uint i = 0; i < _term.arguments.length; ++i)
			args[i] = hashMemory(_term.arguments[i]);
		return keccak256(abi.encodePacked(_term.kind, _term.symbol, args));
	}

	function hashStorage(Term storage _term) internal view returns (bytes32) {
		bytes32[] memory args = new bytes32[](_term.arguments.length);
		for (uint i = 0; i < _term.arguments.length; ++i)
			args[i] = hashStorage(_term.arguments[i]);
		return keccak256(abi.encodePacked(_term.kind, _term.symbol, args));
	}

	function validate(Term memory _term) internal pure {
		if (_term.kind == TermKind.Number || _term.kind == TermKind.Ignore || _term.kind == TermKind.Variable)
			require(_term.arguments.length == 0);
		else if (_term.kind == TermKind.ListHeadTail)
			// The last argument represents the tail. Head must contain at least one term.
			require(_term.arguments.length >= 2);

		// Symbol should not be used in case of _ and lists
		if (_term.kind == TermKind.List || _term.kind == TermKind.ListHeadTail)
			require(_term.symbol == 0);
		else if (_term.kind == TermKind.Ignore)
			// NOTE: Ignore can't use symbol == 0 because it would then be indistinguishable from
			// uninitialized memory.
			require(_term.symbol == 1);
		else if (_term.kind == TermKind.Predicate)
			require(_term.symbol != 0);
	}

	function isEmptyMemory(Term memory _term) internal pure returns (bool) {
		return _term.kind == TermKind.Ignore && _term.symbol == 0 && _term.arguments.length == 0;
	}

	function isEmptyStorage(Term storage _term) internal view returns (bool) {
		return _term.kind == TermKind.Ignore && _term.symbol == 0 && _term.arguments.length == 0;
	}

	function equalsMemory(Term memory _term1, Term memory _term2) internal view returns (bool) {
		if (_term1.kind != _term2.kind || _term1.symbol != _term2.symbol || _term1.arguments.length != _term2.arguments.length)
			return false;

		for (uint i = 0; i < _term1.arguments.length; ++i)
			if (!equalsMemory(_term1.arguments[i], _term2.arguments[i]))
				return false;

		return true;
	}

	function equalsStorage(Term storage _term1, Term memory _term2) internal view returns (bool) {
		if (_term1.kind != _term2.kind || _term1.symbol != _term2.symbol || _term1.arguments.length != _term2.arguments.length)
			return false;

		for (uint i = 0; i < _term1.arguments.length; ++i)
			if (!equalsStorage(_term1.arguments[i], _term2.arguments[i]))
				return false;

		return true;
	}

	function toMemory(Term storage _from) internal returns (Term memory) {
		Term memory output = Term({
			kind: _from.kind,
			symbol: _from.symbol,
			arguments: new Term[](_from.arguments.length)
		});

		for (uint i = 0; i < _from.arguments.length; ++i)
			output.arguments[i] = toMemory(_from.arguments[i]);

		return output;
	}

	function fromMemory(Term storage _to, Term memory _from) internal {
		_to.kind = _from.kind;
		_to.symbol = _from.symbol;
		delete _to.arguments;
		for (uint i = 0; i < _from.arguments.length; ++i)
			fromMemory(_to.arguments.push(), _from.arguments[i]);
	}
}
