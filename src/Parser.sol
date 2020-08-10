// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "./Logic.sol";

library Parser {
	function parsePredicate(bytes memory _source, uint _pos) internal pure returns (Term memory pred, uint) {
		_pos = skipBlanks(_source, _pos);

		pred.kind = TermKind.Predicate;
	}

	function parseAtom(bytes memory _source, uint _pos) internal pure returns (Term memory atom, uint) {
		_pos = skipBlanks(_source, _pos);
		uint i = _pos;
		while (i < _source.length && (isDigit(_source[i]) || isAlpha(_source[i]) || isUnderscore(_source[i])))
			++i;

		if (i == 0)
			return (atom, _pos);

		bytes memory lit = new bytes(i);
		for (uint j = _pos; j < i; ++j)
			lit[j - _pos] = _source[j];

		byte first = lit[0];
		if (isDigit(first)) {
			for (uint l = 1; l < lit.length; ++l)
				if (!isDigit(lit[l]))
					return (atom, _pos);
			atom.kind = TermKind.Number;
			atom.symbol = str2uint(lit);
		}
		else {
			if (isUnderscore(first) && lit.length == 1)
				atom.kind = TermKind.Ignore;
			else if (isUppercase(first))
				atom.kind = TermKind.Variable;
			else
				atom.kind = TermKind.Predicate;
			atom.symbol = uint(keccak256(lit));
		}
		return (atom, _pos + i);
	}

	function skipBlanks(bytes memory _source, uint _pos) internal pure returns (uint) {
		while (_pos < _source.length && isBlank(_source[_pos]))
			++_pos;
		return _pos;
	}

	function isDigit(byte _char) internal pure returns (bool) {
		return _char >= '0' && _char <= '9';
	}

	function isArithmetic(byte _char) internal pure returns (bool) {
		return _char == '+' ||
			_char == '-' ||
			_char == '*' ||
			_char == '/' ||
			_char == '%';
	}

	function isAlpha(byte _char) internal pure returns (bool) {
		return isLowercase(_char) || isUppercase(_char);
	}

	function isLowercase(byte _char) internal pure returns (bool) {
		return _char >= 'a' && _char <= 'z';
	}

	function isUppercase(byte _char) internal pure returns (bool) {
		return _char >= 'A' && _char <= 'Z';
	}

	function isUnderscore(byte _char) internal pure returns (bool) {
		return _char == '_';
	}

	function isBlank(byte _char) internal pure returns (bool) {
		return _char == ' ' ||
			_char == '\t' ||
			_char == '\n';
	}

	function str2uint(bytes memory _str) internal pure returns (uint n) {
		assert(_str.length > 0);
		uint p10 = 1;
		for (uint i = _str.length; i > 0; --i) {
			n += p10 * (uint8(_str[i - 1]) - 48);
			p10 *= 10;
		}
	}
}
