pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Solprologv2.sol";

contract Solprologv2Test is DSTest {
    Solprologv2 solprologv;

    function setUp() public {
        solprologv = new Solprologv2();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
