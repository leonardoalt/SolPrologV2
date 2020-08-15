// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";

import "./TicTacToe.sol";
import "./TicTacToeBoard.sol";


contract Player {
	TicTacToe ticTacToe;

	constructor (TicTacToe _ticTacToe) public {
		ticTacToe = _ticTacToe;
	}

	function newGame(Player _opponent) external payable {
		ticTacToe.newGame{value: msg.value}(address(_opponent));
	}

	function move(Player _opponent, TicTacToeBoard.Field[3][3] calldata _nextBoard) external {
		ticTacToe.move(address(_opponent), _nextBoard);
	}

	function gameState(Player _opponent) external view returns (TicTacToe.GameState memory) {
		return ticTacToe.gameState(address(_opponent));
	}

	function winner(Player _opponent) external returns (TicTacToe.Field) {
		return ticTacToe.winner(address(_opponent));
	}

	function payOut(Player _opponent) external {
		ticTacToe.payOut(address(_opponent));
	}

	function withdraw(Player _opponent) external {
		ticTacToe.withdraw(address(_opponent));
	}

	receive() external payable {
	}
}


contract TicTacToeTestBase is DSTest {
	TicTacToe ticTacToe;
	Player player1;
	Player player2;
	Player player3;

	TicTacToeBoard.Field constant X = TicTacToeBoard.Field.X;
	TicTacToeBoard.Field constant O = TicTacToeBoard.Field.O;
	TicTacToeBoard.Field constant B = TicTacToeBoard.Field.Blank;

	function setUp() public {
		ticTacToe = new TicTacToe();
		player1 = new Player(ticTacToe);
		player2 = new Player(ticTacToe);
		player3 = new Player(ticTacToe);
	}

	function assertEq(TicTacToeBoard.Field _expectedValue, TicTacToeBoard.Field _actualValue) internal {
		assertEq(uint(_expectedValue), uint(_actualValue));
	}

	function assertBoardEq(TicTacToeBoard.Field[3][3] memory _expectedBoard, TicTacToeBoard.Field[3][3] memory _actualBoard) internal {
		for (uint i = 0; i < 3; ++i)
			for (uint j = 0; j < 3; ++j)
				assertEq(TicTacToeBoard.Field(_expectedBoard[i][j]), TicTacToeBoard.Field(_actualBoard[i][j]));
	}

	function assertState(
		uint _expectedHostStake,
		uint _expectedGuestStake,
		TicTacToeBoard.Field _expectedNextPlayer,
		TicTacToeBoard.Field[3][3] memory _expectedBoard,
		TicTacToe.GameState memory _actualState
	) internal {
		assertEq(_actualState.hostStake, _expectedHostStake);
		assertEq(_actualState.guestStake, _expectedGuestStake);
		assertEq(_actualState.nextPlayer, _expectedNextPlayer);
		assertBoardEq(_actualState.board, _expectedBoard);
	}
}


contract TicTacToeTest is TicTacToeTestBase {
	function test_initial_state() public {
		TicTacToe.GameState memory gameState = player1.gameState(player2);

		assertEq(gameState.hostStake, 0);
		assertEq(gameState.guestStake, 0);
	}

	function test_new_game_should_start_a_game_when_used_by_both_players() public {
		player1.newGame{value: 500}(player2);
		assertState(500, 0, X, [[B, B, B], [B, B, B], [B, B, B]], player1.gameState(player2));
		assertState(500, 0, X, [[B, B, B], [B, B, B], [B, B, B]], player2.gameState(player1));

		player2.newGame{value: 300}(player1);
		assertState(500, 300, X, [[B, B, B], [B, B, B], [B, B, B]], player2.gameState(player1));
		assertState(500, 300, X, [[B, B, B], [B, B, B], [B, B, B]], player1.gameState(player2));
	}

	function testFail_new_game_should_not_start_new_game_if_host_stake_is_zero() public {
		player1.newGame{value: 0}(player2);
	}

	function testFail_new_game_should_not_start_new_game_if_guestt_stake_is_zero() public {
		player1.newGame{value: 500}(player2);
		player2.newGame{value: 0}(player1);
	}

	function testFail_new_game_should_not_start_new_game_if_one_already_in_progress() public {
		player1.newGame{value: 500}(player2);
		player1.newGame{value: 500}(player2);
	}

	function testFail_new_game_should_not_allow_accepting_game_twice() public {
		player1.newGame{value: 500}(player2);
		player2.newGame{value: 500}(player1);
		player2.newGame{value: 500}(player1);
	}

	function test_new_game_should_allow_starting_games_with_multiple_players() public {
		player1.newGame{value: 100}(player2);
		player2.newGame{value: 200}(player1);
		player1.newGame{value: 300}(player3);
		player3.newGame{value: 400}(player1);
		player2.newGame{value: 500}(player3);
		player3.newGame{value: 600}(player2);

		assertState(100, 200, X, [[B, B, B], [B, B, B], [B, B, B]], player1.gameState(player2));
		assertState(300, 400, X, [[B, B, B], [B, B, B], [B, B, B]], player1.gameState(player3));
		assertState(500, 600, X, [[B, B, B], [B, B, B], [B, B, B]], player2.gameState(player3));
	}

	// FIXME: This test is just too heavy for the current Prolog implementation
	//function test_move_should_accept_first_move_from_player_who_started_game() public {
	//	player1.newGame{value: 500}(player2);
	//	player2.newGame{value: 300}(player1);
	//	player1.move(player2, [[X, B, B], [B, B, B], [B, B, B]]);

	//	assertState(500, 300, O, [[X, B, B], [B, B, B], [B, B, B]], player1.gameState(player2));
	//}

	function testFail_move_should_not_accept_first_move_from_player_who_did_not_start_game() public {
		player1.newGame{value: 500}(player2);
		player2.newGame{value: 300}(player1);
		player2.move(player1, [[O, B, B], [B, B, B], [B, B, B]]);
	}

	function testFail_move_should_not_accept_first_move_from_player_not_participating_in_the_game() public {
		player1.newGame{value: 500}(player2);
		player2.newGame{value: 300}(player1);
		player3.move(player1, [[O, B, B], [B, B, B], [B, B, B]]);
	}

	// FIXME: This test is just too heavy for the current Prolog implementation
	//function testFail_move_should_not_accept_move_with_wrong_mark() public {
	//	player1.newGame{value: 500}(player2);
	//	player2.newGame{value: 300}(player1);
	//	player1.move(player2, [[O, B, B], [B, B, B], [B, B, B]]);
	//}

	function testFail_move_should_not_accept_moves_if_game_not_in_progress() public {
		player1.move(player2, [[O, B, B], [B, B, B], [B, B, B]]);
	}

	function testFail_move_should_not_accept_moves_if_game_not_accepted_yet_by_guest_player() public {
		player1.newGame{value: 500}(player2);
		player1.move(player2, [[O, B, B], [B, B, B], [B, B, B]]);
	}

	// FIXME: This test is just too heavy for the current Prolog implementation
	//function testFail_move_should_not_allow_making_two_moves_in_one_go() public {
	//	player1.newGame{value: 500}(player2);
	//	player2.newGame{value: 300}(player1);
	//	player1.move(player2, [[O, O, B], [B, B, B], [B, B, B]]);
	//}

	// FIXME: This test is just too heavy for the current Prolog implementation
	//function testFail_move_should_not_allow_immediately_putting_the_board_into_a_winning_position() public {
	//	player1.newGame{value: 500}(player2);
	//	player2.newGame{value: 300}(player1);
	//	player1.move(player2, [[X, X, B], [O, O, O], [B, B, B]]);
	//}

	function testFail_pay_out_should_not_be_available_when_game_has_not_been_accepted() public {
		player1.newGame{value: 500}(player2);

		player1.payOut(player2);
	}

	function testFail_pay_out_should_not_be_available_when_game_is_in_progress() public {
		player1.newGame{value: 500}(player2);
		player2.newGame{value: 300}(player1);

		player1.payOut(player2);
	}

	function testFail_withdraw_should_not_allow_canceling_game_that_has_not_been_accepted() public {
		player1.newGame{value: 500}(player2);
		player1.withdraw(player2);
	}

	function testFail_withdraw_should_not_allow_the_other_player_to_cancel_game() public {
		player1.newGame{value: 500}(player2);
		player2.withdraw(player1);
	}

	function testFail_withdraw_should_not_be_available_when_game_is_in_progress() public {
		player1.newGame{value: 500}(player2);
		player2.newGame{value: 300}(player1);

		player1.withdraw(player2);
	}
}

// FIXME: These tests are just too heavy for the current Prolog implementation
//contract TicTacToeFullGameTest is TicTacToeTestBase {
//	function winningMoves() internal pure returns (TicTacToeBoard.Field[3][3][] memory moves) {
//		moves = new TicTacToeBoard.Field[3][3][](7);
//
//		moves[0] = [
//			[B, B, B],
//			[B, X, B],
//			[B, B, B]
//		];
//		moves[1] = [
//			[B, B, O],
//			[B, X, B],
//			[B, B, B]
//		];
//		moves[2] = [
//			[B, B, O],
//			[B, X, B],
//			[B, X, B]
//		];
//		moves[3] = [
//			[B, O, O],
//			[B, X, B],
//			[B, X, B]
//		];
//		moves[4] = [
//			[X, O, O],
//			[B, X, B],
//			[B, X, B]
//		];
//		moves[5] = [
//			[X, O, O],
//			[O, X, B],
//			[B, X, B]
//		];
//		moves[6] = [
//			[X, O, O],
//			[O, X, B],
//			[B, X, X]
//		];
//
//		return moves;
//	}
//
//	function drawMoves() internal pure returns (TicTacToeBoard.Field[3][3][] memory moves) {
//		moves = new TicTacToeBoard.Field[3][3][](9);
//
//		moves[0] = [
//			[B, X, B],
//			[B, B, B],
//			[B, B, B]
//		];
//		moves[1] = [
//			[B, X, B],
//			[B, O, B],
//			[B, B, B]
//		];
//		moves[2] = [
//			[X, X, B],
//			[B, O, B],
//			[B, B, B]
//		];
//		moves[3] = [
//			[X, X, O],
//			[B, O, B],
//			[B, B, B]
//		];
//		moves[4] = [
//			[X, X, O],
//			[B, O, B],
//			[X, B, B]
//		];
//		moves[5] = [
//			[X, X, O],
//			[O, O, B],
//			[X, B, B]
//		];
//		moves[6] = [
//			[X, X, O],
//			[O, O, X],
//			[X, B, B]
//		];
//		moves[7] = [
//			[X, X, O],
//			[O, O, X],
//			[X, O, B]
//		];
//		moves[8] = [
//			[X, X, O],
//			[O, O, X],
//			[X, O, X]
//		];
//
//		return moves;
//	}
//
//	function playGame(TicTacToeBoard.Field[3][3][] memory _moves) internal {
//		require(_moves.length > 0);
//
//		Player[2] memory players = [player1, player2];
//		TicTacToeBoard.Field[2] memory marks = [X, O];
//
//		for (uint i = 0; i < _moves.length; ++i) {
//			players[i % 2].move(players[(i + 1) % 2], _moves[i]);
//
//			TicTacToe.GameState memory gameState1 = player1.gameState(player2);
//			TicTacToe.GameState memory gameState2 = player2.gameState(player1);
//			assertState(gameState1.hostStake, gameState1.guestStake, gameState1.nextPlayer, gameState1.board, gameState2);
//
//			assertEq(gameState1.nextPlayer, marks[(i + 1) % 2]);
//			assertBoardEq(gameState1.board, _moves[i]);
//
//			assertEq(player1.winner(player2), player2.winner(player1));
//			if (i < _moves.length - 1)
//				assertEq(player1.winner(player2), B);
//		}
//	}
//
//	function test_winner_should_be_x_if_player_who_started_game_wins() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertEq(player1.winner(player2), player2.winner(player1));
//		assertEq(player1.winner(player2), X);
//	}
//
//	function test_there_should_be_no_winner_if_game_is_a_draw() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(drawMoves());
//		assertEq(player1.winner(player2), player2.winner(player1));
//		assertEq(player1.winner(player2), B);
//	}
//
//	function test_pay_out_should_pay_out_whole_stake_to_player_who_won() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertEq(player1.winner(player2), X);
//
//		uint player1BalanceBefore = address(player1).balance;
//		uint player2BalanceBefore = address(player2).balance;
//
//		player1.payOut(player2);
//		assertEq(address(player1).balance, player1BalanceBefore + 800);
//		assertEq(address(player2).balance, player2BalanceBefore);
//
//		TicTacToe.GameState memory gameState = player1.gameState(player2);
//		assertEq(gameState.hostStake, 0);
//		assertEq(gameState.guestStake, 0);
//
//		assertEq(player1.winner(player2), X);
//	}
//
//	function testFail_pay_out_should_not_pay_out_stake_twice() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertEq(player1.winner(player2), X);
//
//		player1.payOut(player2);
//		player1.payOut(player2);
//	}
//
//	function testFail_pay_out_should_not_pay_out_stake_to_the_losing_player() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertEq(player1.winner(player2), X);
//
//		player2.payOut(player1);
//	}
//
//	function testFail_pay_out_should_not_pay_out_stake_to_player_who_did_not_participate() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertEq(player3.winner(player1), B);
//
//		player3.payOut(player1);
//	}
//
//	function testFail_new_game_should_not_start_a_fresh_game_before_stake_is_paid_out() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertState(500, 300, O, [[X, O, O], [O, X, B], [B, X, X]], player1.gameState(player2));
//
//		player1.newGame{value: 400}(player2);
//	}
//
//	function test_new_game_should_start_a_fresh_game_after_stake_is_paid_out() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertState(500, 300, O, [[X, O, O], [O, X, B], [B, X, X]], player1.gameState(player2));
//
//		player1.payOut(player2);
//		assertState(0, 0, O, [[X, O, O], [O, X, B], [B, X, X]], player1.gameState(player2));
//
//		player1.newGame{value: 400}(player2);
//		player2.newGame{value: 200}(player1);
//		assertState(400, 200, X, [[B, B, B], [B, B, B], [B, B, B]], player1.gameState(player2));
//		assertState(400, 200, X, [[B, B, B], [B, B, B], [B, B, B]], player2.gameState(player1));
//	}
//
//	function test_new_game_should_allow_the_other_player_to_start_a_fresh_game_after_stake_is_paid_out() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(winningMoves());
//		assertState(500, 300, O, [[X, O, O], [O, X, B], [B, X, X]], player1.gameState(player2));
//
//		player1.payOut(player2);
//		assertState(0, 0, O, [[X, O, O], [O, X, B], [B, X, X]], player1.gameState(player2));
//
//		player2.newGame{value: 400}(player1);
//		player1.newGame{value: 200}(player2);
//		assertState(400, 200, X, [[B, B, B], [B, B, B], [B, B, B]], player1.gameState(player2));
//		assertState(400, 200, X, [[B, B, B], [B, B, B], [B, B, B]], player2.gameState(player1));
//	}
//
//	function testFail_pay_out_should_not_be_available_in_case_of_draw() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//		playGame(drawMoves());
//
//		player1.payOut(player2);
//	}
//
//	function test_withdraw_should_let_host_player_initiate_stake_withdrawal_case_of_draw() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(drawMoves());
//		assertState(500, 300, O, [[X, X, O], [O, O, X], [X, O, X]], player1.gameState(player2));
//		assertEq(player1.winner(player2), B);
//
//		uint player1BalanceBefore = address(player1).balance;
//		uint player2BalanceBefore = address(player2).balance;
//
//		player1.withdraw(player2);
//		assertState(0, 0, O, [[X, X, O], [O, O, X], [X, O, X]], player1.gameState(player2));
//		assertEq(address(player1).balance, player1BalanceBefore + 500);
//		assertEq(address(player2).balance, player2BalanceBefore + 300);
//	}
//
//	function test_withdraw_should_let_guest_player_initiate_stake_withdrawal_case_of_draw() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//
//		playGame(drawMoves());
//		assertState(500, 300, O, [[X, X, O], [O, O, X], [X, O, X]], player1.gameState(player2));
//		assertEq(player1.winner(player2), B);
//
//		uint player1BalanceBefore = address(player1).balance;
//		uint player2BalanceBefore = address(player2).balance;
//
//		player2.withdraw(player1);
//		assertState(0, 0, O, [[X, X, O], [O, O, X], [X, O, X]], player1.gameState(player2));
//		assertEq(address(player1).balance, player1BalanceBefore + 500);
//		assertEq(address(player2).balance, player2BalanceBefore + 300);
//	}
//
//	function testFail_withdraw_should_not_allow_multiple_withdrawwals_for_the_same_game() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//		playGame(drawMoves());
//
//		player2.withdraw(player1);
//		player1.withdraw(player2);
//	}
//
//	function test_new_game_should_allow_starting_new_game_after_withdrawal() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//		playGame(drawMoves());
//		player1.withdraw(player2);
//
//		player1.newGame{value: 100}(player2);
//		player2.newGame{value: 200}(player1);
//		assertState(100, 200, X, [[B, B, B], [B, B, B], [B, B, B]], player2.gameState(player1));
//	}
//
//	function testFail_withdraw_should_not_be_available_if_game_is_won() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//		playGame(winningMoves());
//
//		player1.withdraw(player2);
//	}
//
//	function testFail_new_game_should_not_allow_starting_new_game_after_draw_but_before_withdrawal() public {
//		player1.newGame{value: 500}(player2);
//		player2.newGame{value: 300}(player1);
//		playGame(drawMoves());
//
//		player1.newGame{value: 100}(player2);
//	}
//}
