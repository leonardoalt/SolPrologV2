// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Logic.sol";
import "./Substitution.sol";

contract EncoderTest is DSTest {
	Substitution.Info info;

	using Substitution for Term;
	using Substitution for Substitution.Info;
	using Logic for *;
	using TermBuilder for *;

	function setUp() public {
	}

	function test_set_var_atom() public {
		info.push();
		Term memory x = bytes("X").atom();
		Term memory a = bytes("a").atom();
		x.set(a, info);
		assertTrue(x.get(info).termsEqualInMemory(a));
		info.pop();
	}

	function test_set_ignore_var() public {
		info.push();
		Term memory x = bytes("_").atom();
		Term memory y = bytes("Y").atom();
		x.set(y, info);
		assertTrue(x.get(info).termsEqualInMemory(y));
		info.pop();
	}

	function test_set_var_var() public {
		info.push();
		Term memory x = bytes("X").atom();
		Term memory y = bytes("Y").atom();
		x.set(y, info);
		assertTrue(x.get(info).termsEqualInMemory(y));
		info.pop();
	}

	function test_set_var_pred() public {
		info.push();
		Term memory x = bytes("X").atom();
		Term memory p = bytes("p").pred(2);
		p.arguments[0] = bytes("a").atom();
		p.arguments[1] = bytes("b").atom();
		x.set(p, info);
		assertTrue(x.get(info).termsEqualInMemory(p));
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
