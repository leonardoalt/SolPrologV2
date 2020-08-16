// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Logic.sol";
import "./Builder.sol";
import "./Substitution.sol";

contract EncoderTest is DSTest, TermBuilder {
	Substitution.Info info;

	using Substitution for Term;
	using Substitution for Substitution.Info;
	using Logic for *;

	function setUp() public {
	}

	function test_set_var_atom() public {
		info.push();
		Term memory x = atom("X");
		Term memory a = atom("a");
		info.set(x, a);
		assertTrue(info.get(x).equalsMemory(a));
		info.pop();
	}

	function test_set_ignore_var() public {
		info.push();
		Term memory x = atom("_");
		Term memory y = atom("Y");
		info.set(x, y);
		assertTrue(info.get(x).equalsMemory(y));
		info.pop();
	}

	function test_set_var_var() public {
		info.push();
		Term memory x = atom("X");
		Term memory y = atom("Y");
		info.set(x, y);
		assertTrue(info.get(x).equalsMemory(y));
		info.pop();
	}

	function test_set_var_pred() public {
		info.push();
		Term memory x = atom("X");
		Term memory p = pred("p", 2);
		p.arguments[0] = atom("a");
		p.arguments[1] = atom("b");
		info.set(x, p);
		assertTrue(info.get(x).equalsMemory(p));
		info.pop();
	}

	function test_push_pop() public {
		info.push();
		info.push();
		info.push();
		uint len = info.usedKeys.length;
		assertEq(len, 3);
		assertEq(info.usedKeys[len - 1].length, 0);
		info.pop();
		info.pop();
		info.pop();
		assertEq(info.usedKeys.length, 0);
	}

	function testFail_basic_sanity() public {
		assertTrue(false);
	}

	function test_basic_sanity() public {
		assertTrue(true);
	}
}
