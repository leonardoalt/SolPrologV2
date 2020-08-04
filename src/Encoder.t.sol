// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Encoder.sol";

contract EncoderTest is DSTest {
	Encoder.Info info;

	using Encoder for FrontendTerm;

    function setUp() public {
    }

	function test_adam() public {
		FrontendTerm memory adam;
		adam.value = "adam";
		Term memory t = adam.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Literal));
		assertEq(t.symbol, 0x1b85ce0bb068b0afabedb4b50cf3876dc545680f066001fe2d79bf5a12de4c5c);
		assertEq(t.arguments.length, 0);
	}

	function test_man_adam() public {
		FrontendTerm memory adam;
		adam.value = "adam";
		FrontendTerm memory manAdam;
		manAdam.value = "man";
		manAdam.children = new FrontendTerm[](1);
		manAdam.children[0] = adam;
		Term memory t = manAdam.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Predicate));
		assertEq(t.symbol, 0xec84212b669cc259b42900f38ceafde860a5c8244dff2532ee756ad04953d93d);
		assertEq(t.arguments.length, 1);
	}

	function test_parent_adam_peter() public {
		FrontendTerm memory adam;
		adam.value = "adam";
		FrontendTerm memory peter;
		peter.value = "peter";
		FrontendTerm memory parent;
		parent.value = "parent";
		parent.children = new FrontendTerm[](2);
		parent.children[0] = adam;
		parent.children[1] = peter;
		Term memory t = parent.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Predicate));
		assertEq(t.symbol, 0xff483e972a04a9a62bb4b7d04ae403c615604e4090521ecc5bb7af67f71be09c);
		assertEq(t.arguments.length, 2);
	}

	function test_var() public {
		FrontendTerm memory x;
		x.value = "Xxxx";
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Variable));
		assertEq(t.symbol, 0xf57963f05fcc88c45bd612a48ad9661abc448805419a5fc5ef0e57f656771d79);
		assertEq(t.arguments.length, 0);
	}

	function test_number() public {
		FrontendTerm memory x;
		x.value = "12";
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Number));
		assertEq(t.symbol, 12);
		assertEq(t.arguments.length, 0);
	}

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
