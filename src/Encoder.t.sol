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
		assertEq(uint(t.kind), uint(TermKind.Predicate));
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

	function test_father() public {
		FrontendTerm memory father;
		father.value = "father";
		FrontendTerm memory f;
		f.value = "F";
		FrontendTerm memory c;
		c.value = "C";
		father.children = new FrontendTerm[](2);
		father.children[0] = f;
		father.children[1] = c;
		Term memory t = father.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Predicate));
		assertEq(t.symbol, 0x44cb6a28e80e8a1cac1de6bf0c955466a8f3482729973d1235300e757c94964d);
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

	function test_ignore() public {
		FrontendTerm memory x;
		x.value = "_";
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.Ignore));
		assertEq(t.symbol, 0xcd5edcba1904ce1b09e94c8a2d2a85375599856ca21c793571193054498b51d7);
		assertEq(t.arguments.length, 0);
	}

	function test_list() public {
		FrontendTerm memory x;
		x.value = "[]";
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.List));
		assertEq(t.symbol, 0x518674ab2b227e5f11e9084f615d57663cde47bce1ba168b4c19c7ee22a73d70);
		assertEq(t.arguments.length, 0);
	}

	function test_list_head_tail() public {
		FrontendTerm memory x;
		x.value = "[|]";
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.ListHeadTail));
		assertEq(t.symbol, 0x5b8a6c638e8621600828f0b80f9ef313f84db523503971e7a1981d0e899dc3cd);
		assertEq(t.arguments.length, 0);
	}

	function test_list_args() public {
		FrontendTerm memory a;
		a.value = "a";
		FrontendTerm memory v;
		v.value = "V";
		FrontendTerm memory x;
		x.value = "[]";
		x.children = new FrontendTerm[](2);
		x.children[0] = a;
		x.children[1] = v;
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.List));
		assertEq(t.symbol, 0x518674ab2b227e5f11e9084f615d57663cde47bce1ba168b4c19c7ee22a73d70);
		assertEq(t.arguments.length, 2);
	}

	function test_list_head_tail_args() public {
		FrontendTerm memory head;
		head.value = "H";
		FrontendTerm memory tail;
		tail.value = "T";
		FrontendTerm memory x;
		x.value = "[|]";
		x.children = new FrontendTerm[](2);
		x.children[0] = head;
		x.children[1] = tail;
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.ListHeadTail));
		assertEq(t.symbol, 0x5b8a6c638e8621600828f0b80f9ef313f84db523503971e7a1981d0e899dc3cd);
		assertEq(t.arguments.length, 2);
	}

	function test_list_head_tail_args_2() public {
		FrontendTerm memory head1;
		head1.value = "H1";
		FrontendTerm memory head2;
		head2.value = "H2";
		FrontendTerm memory tail;
		tail.value = "T";
		FrontendTerm memory x;
		x.value = "[|]";
		x.children = new FrontendTerm[](3);
		x.children[0] = head1;
		x.children[1] = head2;
		x.children[2] = tail;
		Term memory t = x.encode(info);
		assertEq(uint(t.kind), uint(TermKind.ListHeadTail));
		assertEq(t.symbol, 0x5b8a6c638e8621600828f0b80f9ef313f84db523503971e7a1981d0e899dc3cd);
		assertEq(t.arguments.length, 3);
	}

	function testFail_basic_sanity() public {
		assertTrue(false);
	}

	function test_basic_sanity() public {
		assertTrue(true);
	}
}
