// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Logic.sol";
import "./Parser.sol";

contract ParserTest is DSTest {
	using Parser for *;

	function setUp() public {
	}

	function parse_atom(bytes memory _literal) internal {
		(Term memory t, uint pos) = _literal.parseAtom(0);
		assertTrue(t.kind == TermKind.Predicate);
		assertEq(t.symbol, uint(keccak256(_literal)));
		assertEq(t.arguments.length, 0);
		assertEq(pos, _literal.length);
	}

	function parse_atom_fail(bytes memory _literal) internal {
		(Term memory t,) = _literal.parseAtom(0);
		assertTrue(t.kind == TermKind.Ignore);
		assertEq(t.symbol, 0);
		assertEq(t.arguments.length, 0);
	}

	function parse_variable(bytes memory _literal) internal {
		(Term memory t, uint pos) = _literal.parseAtom(0);
		assertTrue(t.kind == TermKind.Variable);
		assertEq(t.symbol, uint(keccak256(_literal)));
		assertEq(t.arguments.length, 0);
		assertEq(pos, _literal.length);
	}

	function parse_ignore(bytes memory _literal) internal {
		(Term memory t, uint pos) = _literal.parseAtom(0);
		assertTrue(t.kind == TermKind.Ignore);
		assertEq(t.symbol, uint(keccak256(_literal)));
		assertEq(t.arguments.length, 0);
		assertEq(pos, _literal.length);
	}

	function parse_number(bytes memory _literal) internal {
		(Term memory t, uint pos) = _literal.parseAtom(0);
		assertTrue(t.kind == TermKind.Number);
		assertEq(t.symbol, _literal.str2uint());
		assertEq(t.arguments.length, 0);
		assertEq(pos, _literal.length);
	}

	function simple_atoms() public {
		parse_atom("test");
		parse_atom("aaa123");
		parse_atom("_1231");
		parse_atom("_asdsad");
		parse_atom("_asdad_adlld_");
		parse_atom("aaaX");
	}

	function parse_numbers() public {
		parse_number("123");
	}

	function parse_variables() public {
		parse_variable("X");
		parse_variable("XX");
		parse_variable("Xaaaa");
	}

	function parse_ignore() public {
		parse_ignore("_");
	}

	function simple_atoms_fail() public {
		parse_atom_fail("");
		parse_atom_fail("123___");
		parse_atom_fail("123aaa");
		parse_atom_fail("?");
		parse_atom_fail("(");
		parse_atom_fail(")");
	}
}
