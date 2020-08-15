// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import './TicTacToeBoard.sol';

contract TicTacToe is TicTacToeBoard {
	struct GameState {
		Field[3][3] board;
		Field nextPlayer;
		uint hostStake;    // Stake must be greater than zero. Zero is used as a special value to indicate uninitialized struct.
		uint guestStake;
	}

	mapping(address => mapping(address => GameState)) games;

	function newGame(address _opponent) external payable {
		GameState storage ownGame = games[msg.sender][_opponent];
		GameState storage opponentsGame = games[_opponent][msg.sender];

		require(msg.value > 0);
		require(!inProgress(ownGame) && !inProgress(opponentsGame));
		require(ownGame.hostStake == 0);
		assert(ownGame.guestStake == 0 && opponentsGame.guestStake == 0);

		if (opponentsGame.hostStake > 0) {
			opponentsGame.guestStake = msg.value;
			assert(opponentsGame.nextPlayer == Field.X);
		} else {
			ownGame.hostStake = msg.value;
			ownGame.nextPlayer = Field.X;
			ownGame.board = emptyBoard();
		}
	}

	function move(address _opponent, Field[3][3] calldata _nextBoard) external {
		GameState storage game = findGame(_opponent);
		require(inProgress(game));
		assert(game.nextPlayer != Field.Blank);
		require(game.nextPlayer == whichSide(_opponent));

		require(isValidMove(game.nextPlayer, game.board, _nextBoard));
		game.board = _nextBoard;
		game.nextPlayer = (game.nextPlayer == Field.X ? Field.O : Field.X);
	}

	function gameState(address _opponent) public view returns (GameState memory) {
		return findGame(_opponent);
	}

	function winner(address _opponent) public view returns (Field) {
		GameState storage game = findGame(_opponent);

		return findWinner(game.board);
	}

	function payOut(address _opponent) external {
		GameState storage game = findGame(_opponent);
		require(game.hostStake > 0 || game.guestStake > 0);
		require(whichSide(_opponent) == winner(_opponent));

		uint amount = game.hostStake + game.guestStake;
		game.hostStake = 0;
		game.guestStake = 0;
		assert(address(this).balance >= amount);
		msg.sender.transfer(amount);

		assert(!inProgress(game));
	}

	function withdraw(address payable _opponent) external {
		GameState storage ownGame = games[msg.sender][_opponent];
		GameState storage opponentsGame = games[_opponent][msg.sender];

		uint ownStake = ownGame.hostStake + opponentsGame.guestStake;
		uint opponentsStake = ownGame.guestStake + opponentsGame.hostStake;
		require(ownStake > 0 || opponentsStake > 0);

		GameState storage game = findGame(_opponent);
		require(winner(_opponent) == Field.Blank);
		require(!movePossible(game.board));

		ownGame.hostStake = 0;
		ownGame.guestStake = 0;
		opponentsGame.hostStake = 0;
		opponentsGame.guestStake = 0;

		if (ownStake > 0) {
			assert(address(this).balance >= ownStake + opponentsStake);
			msg.sender.transfer(ownStake);
		}

		if (opponentsStake > 0) {
			assert(address(this).balance >= opponentsStake);
			_opponent.transfer(opponentsStake);
		}

		assert(!inProgress(ownGame));
		assert(!inProgress(opponentsGame));
	}

	function whichSide(address _opponent) internal view returns(Field) {
		if (games[msg.sender][_opponent].hostStake > 0)
			return Field.X;
		else if (games[_opponent][msg.sender].hostStake > 0)
			return Field.O;
		else
			// We'll use Blank as a special value to indicate that sender is not participating.
			return Field.Blank;
	}

	function inProgress(GameState storage _game) internal view returns (bool) {
		return _game.hostStake > 0 && _game.guestStake > 0;
	}

	function findGame(address _opponent) internal view returns (GameState storage) {
		GameState storage ownGame = games[msg.sender][_opponent];
		GameState storage opponentsGame = games[_opponent][msg.sender];

		assert(!inProgress(ownGame) || !inProgress(opponentsGame));

		if (opponentsGame.hostStake > 0)
			return opponentsGame;
		else
			return ownGame;
	}

	function movePossible(Field[3][3] memory _board) internal pure returns (bool) {
		for (uint i = 0; i < 3; ++i)
			for (uint j = 0; j < 3; ++j)
				if (_board[i][j] == Field.Blank)
					return true;

		return false;
	}

	function isValidMove(
		Field _nextPlayer,
		Field[3][3] memory _currentBoard,
		Field[3][3] memory _nextBoard
	) internal pure returns (bool) {
		require(_nextPlayer != Field.Blank);

		for (uint i = 0; i < 3; ++i)
			for (uint j = 0; j < 3; ++j) {
				if (_currentBoard[i][j] != Field.Blank && _nextBoard[i][j] != Field.Blank && _currentBoard[i][j] != _nextBoard[i][j])
					return false;

				if (_currentBoard[i][j] != Field.Blank && _nextBoard[i][j] == Field.Blank)
					return false;
			}

		uint xCountBefore = 0;
		uint oCountBefore = 0;
		uint xCountAfter = 0;
		uint oCountAfter = 0;
		for (uint i = 0; i < 3; ++i)
			for (uint j = 0; j < 3; ++j) {
				if (_currentBoard[i][j] == Field.X)
					++xCountBefore;
				if (_nextBoard[i][j] == Field.X)
					++xCountAfter;

				if (_currentBoard[i][j] == Field.O)
					++oCountBefore;
				if (_nextBoard[i][j] == Field.O)
					++oCountAfter;
			}

		return
			_nextPlayer == Field.X && xCountAfter == xCountBefore + 1 && oCountBefore == oCountAfter ||
			_nextPlayer == Field.O && oCountAfter == oCountBefore + 1 && xCountBefore == xCountAfter;
	}

	function findWinner(Field[3][3] memory _board) internal pure returns (Field) {
		if (
			_board[0][0] == Field.X && _board[0][1] == Field.X && _board[0][2] == Field.X ||
			_board[1][0] == Field.X && _board[1][1] == Field.X && _board[1][2] == Field.X ||
			_board[2][0] == Field.X && _board[2][1] == Field.X && _board[2][2] == Field.X ||

			_board[0][0] == Field.X && _board[1][0] == Field.X && _board[2][0] == Field.X ||
			_board[0][1] == Field.X && _board[1][1] == Field.X && _board[2][1] == Field.X ||
			_board[0][2] == Field.X && _board[1][2] == Field.X && _board[2][2] == Field.X ||

			_board[0][0] == Field.X && _board[1][1] == Field.X && _board[2][2] == Field.X ||
			_board[0][2] == Field.X && _board[1][1] == Field.X && _board[2][0] == Field.X
		)
			return Field.X;

		if (
			_board[0][0] == Field.O && _board[0][1] == Field.O && _board[0][2] == Field.O ||
			_board[1][0] == Field.O && _board[1][1] == Field.O && _board[1][2] == Field.O ||
			_board[2][0] == Field.O && _board[2][1] == Field.O && _board[2][2] == Field.O ||

			_board[0][0] == Field.O && _board[1][0] == Field.O && _board[2][0] == Field.O ||
			_board[0][1] == Field.O && _board[1][1] == Field.O && _board[2][1] == Field.O ||
			_board[0][2] == Field.O && _board[1][2] == Field.O && _board[2][2] == Field.O ||

			_board[0][0] == Field.O && _board[1][1] == Field.O && _board[2][2] == Field.O ||
			_board[0][2] == Field.O && _board[1][1] == Field.O && _board[2][0] == Field.O
		)
			return Field.O;

		return Field.Blank;
	}
}
