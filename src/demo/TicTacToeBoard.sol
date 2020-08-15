// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

contract TicTacToeBoard {
	enum Field {
		Blank,
		X,
		O
	}

	function emptyBoard() internal pure returns (Field[3][3] memory) {
		return [
			[Field.Blank, Field.Blank, Field.Blank],
			[Field.Blank, Field.Blank, Field.Blank],
			[Field.Blank, Field.Blank, Field.Blank]
		];
	}
}

