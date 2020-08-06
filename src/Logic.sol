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

	function termsEqualInMemory(Term memory _term1, Term memory _term2) internal view returns (bool) {
		if (_term1.kind != _term2.kind || _term1.symbol != _term2.symbol || _term1.arguments.length != _term2.arguments.length)
			return false;

		for (uint i = 0; i < _term1.arguments.length; ++i)
			if (!termsEqualInMemory(_term1.arguments[i], _term2.arguments[i]))
				return false;

		return true;
	}

	function termsEqualInStorage(Term storage _term1, Term memory _term2) internal view returns (bool) {
		if (_term1.kind != _term2.kind || _term1.symbol != _term2.symbol || _term1.arguments.length != _term2.arguments.length)
			return false;

		for (uint i = 0; i < _term1.arguments.length; ++i)
			if (!termsEqualInStorage(_term1.arguments[i], _term2.arguments[i]))
				return false;

		return true;
	}

	function copyToMemory(Term storage _input) internal returns (Term memory){
		Term memory output = Term({
			kind: _input.kind,
			symbol: _input.symbol,
			arguments: new Term[](_input.arguments.length)
		});

		for (uint i = 0; i < _input.arguments.length; ++i)
			output.arguments[i] = copyToMemory(_input.arguments[i]);

		return output;
	}
}

contract TermBuilder {
	function ignore() internal pure returns (Term memory t) {
		t.kind = TermKind.Ignore;
		t.symbol = 1; // 1 rather than 0 to be able to discern Ignore from an uninitialized piece of memory.
	}

	function num(uint _value) internal pure returns (Term memory t) {
		t.kind = TermKind.Number;
		t.symbol = _value;
	}

	function Var(bytes memory _name) internal pure returns (Term memory t) {
		t.kind = TermKind.Variable;
		t.symbol = uint(keccak256(_name));
	}

	function list() internal pure returns (Term memory t) {
		t.kind = TermKind.List;
	}

	function listHT() internal pure returns (Term memory t) {
		t.kind = TermKind.ListHeadTail;
	}

	function listHT(uint _headElementCount, Term memory _tail) internal pure returns (Term memory t) {
		require(_headElementCount > 0);

		t = listHT();
		t.arguments = new Term[](_headElementCount + 1);
		t.arguments[_headElementCount] = _tail;
	}

	function atom(bytes memory _symbol) internal pure returns (Term memory t) {
		t.kind = TermKind.Predicate;
		t.symbol = uint(keccak256(_symbol));
	}

	function pred(bytes memory _symbol, uint _argumentCount) internal pure returns (Term memory t) {
		t = atom(_symbol);
		t.arguments = new Term[](_argumentCount);
	}

	// TODO: Define a more complete set of overloads or find a way to use arrays conveniently.
	function pred(bytes memory _name, Term memory _term) internal pure returns (Term memory) {
		Term memory p = pred(_name, 1);
		p.arguments[0] = _term;
		return p;
	}

	function pred(bytes memory _name, Term memory _term1, Term memory _term2) internal pure returns (Term memory) {
		Term memory p = pred(_name, 2);
		p.arguments[0] = _term1;
		p.arguments[1] = _term2;
		return p;
	}

	function pred(bytes memory _name, Term memory _term1, Term memory _term2, Term memory _term3) internal pure returns (Term memory) {
		Term memory p = pred(_name, 3);
		p.arguments[0] = _term1;
		p.arguments[1] = _term2;
		p.arguments[2] = _term3;
		return p;
	}
}
