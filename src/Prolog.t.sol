// SPDX-License-Identifier: GPL V3
pragma solidity ^0.7.0;

import "ds-test/test.sol";

import "./Prolog.sol";

contract PrologTest is DSTest {
	Prolog prolog;

    function setUp() public {
        prolog = new Prolog();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
