// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import './Logic.sol';

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

	function list(Term memory _element1) internal pure returns (Term memory) {
		Term memory l = list();
		l.arguments = new Term[](1);
		l.arguments[0] = _element1;
		return l;
	}

	function list(Term memory _element1, Term memory _element2) internal pure returns (Term memory) {
		Term memory l = list();
		l.arguments = new Term[](2);
		l.arguments[0] = _element1;
		l.arguments[1] = _element2;
		return l;
	}

	function list(Term memory _element1, Term memory _element2, Term memory _element3) internal pure returns (Term memory) {
		Term memory l = list();
		l.arguments = new Term[](3);
		l.arguments[0] = _element1;
		l.arguments[1] = _element2;
		l.arguments[2] = _element3;
		return l;
	}

	function list(uint _element1) internal pure returns (Term memory) {
		return list(num(_element1));
	}

	function list(uint _element1, uint _element2) internal pure returns (Term memory) {
		return list(num(_element1), num(_element2));
	}

	function list(uint _element1, uint _element2, uint _element3) internal pure returns (Term memory) {
		return list(num(_element1), num(_element2), num(_element3));
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

	function listHT(Term memory _headElement1, Term memory _tail) internal pure returns (Term memory) {
		Term memory l = listHT(1, _tail);
		l.arguments[0] = _headElement1;
		return l;
	}

	function listHT(Term memory _headElement1, Term memory _headElement2, Term memory _tail) internal pure returns (Term memory) {
		Term memory l = listHT(2, _tail);
		l.arguments[0] = _headElement1;
		l.arguments[1] = _headElement2;
		return l;
	}

	function listHT(Term memory _headElement1, Term memory _headElement2, Term memory _headElement3, Term memory _tail) internal pure returns (Term memory) {
		Term memory l = listHT(3, _tail);
		l.arguments[0] = _headElement1;
		l.arguments[1] = _headElement2;
		l.arguments[2] = _headElement3;
		return l;
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
