// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Logic.sol";
import "./Parser.sol";

contract ParserTest is DSTest, TermBuilder {
	using Logic for Term;
	using Parser for *;

	function setUp() public {
	}

	// Internal functions that do the computation and comparison.

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

	function parse_predicate(bytes memory _pred1, Term memory _pred2) internal {
		(Term memory p1, uint pos) = _pred1.parsePredicate(0);
		assertTrue(pos <= _pred1.length);
		assertEq(p1.hash(), _pred2.hash());
	}

	// Test cases.

	function simple_numbers() public {
		parse_number("123");
	}

	function simple_variables() public {
		parse_variable("X");
		parse_variable("XX");
		parse_variable("Xaaaa");
	}

	function simple_ignore() public {
		parse_ignore("_");
	}

	function simple_atoms() public {
		parse_atom("test");
		parse_atom("aaa123");
		parse_atom("_1231");
		parse_atom("_asdsad");
		parse_atom("_asdad_adlld_");
		parse_atom("aaaX");
	}

	function simple_atoms_fail() public {
		parse_atom_fail("");
		parse_atom_fail("123___");
		parse_atom_fail("123aaa");
		parse_atom_fail("?");
		parse_atom_fail("(");
		parse_atom_fail(")");
	}

	function simple_predicate_number() public {
		parse_predicate("f(1)", pred("f", num(1)));
		parse_predicate("f(1   )", pred("f", num(1)));
		parse_predicate("f(    1   )", pred("f", num(1)));
		parse_predicate("f    (    1   )", pred("f", num(1)));
		parse_predicate("f    (    1   )   ", pred("f", num(1)));
		parse_predicate("   f    (    1   )   ", pred("f", num(1)));
	}

	function simple_predicate_atom() public {
		parse_predicate("f(adam)", pred("f", atom("adam")));
		parse_predicate("f(adam    )", pred("f", atom("adam")));
		parse_predicate("f(    adam    )", pred("f", atom("adam")));
		parse_predicate("f    (    adam    )", pred("f", atom("adam")));
		parse_predicate("f    (    adam    )    ", pred("f", atom("adam")));
		parse_predicate("    f    (    adam    )    ", pred("f", atom("adam")));
	}

	function multi_arg_predicate() public {
		parse_predicate("f(1,2)", pred("f", num(1), num(2)));
		parse_predicate("f(1,    2)", pred("f", num(1), num(2)));
		parse_predicate("  f   (    1,    2)   ", pred("f", num(1), num(2)));
		parse_predicate("f(1,adam,2)", pred("f", num(1), atom("adam"), num(2)));
		parse_predicate("f(_,adam,2)", pred("f", ignore(), atom("adam"), num(2)));
		parse_predicate("f(_,adam,X)", pred("f", ignore(), atom("adam"), Var("X")));
	}

	function nested_predicate() public {
		parse_predicate("f(g(1),2)", pred("f", pred("g", num(1)), num(2)));
	}
}
