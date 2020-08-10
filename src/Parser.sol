// SPDX-License-Identifier: GPL V3
pragma solidity ^0.6.7;

import "./Logic.sol";

library Parser {
	function parsePredicate(bytes memory _source, uint _pos) internal pure returns (Term memory pred, uint) {
		Term memory name;
		(name, _pos) = parseAtom(_source, _pos);
		if (name.kind != TermKind.Predicate)
			return (pred, _pos);

		_pos = skipBlanks(_source, _pos);
		if (_pos >= _source.length || _source[_pos++] != '(')
			return (pred, _pos);
		_pos = skipBlanks(_source, _pos);
		if (_pos >= _source.length)
			return (pred, _pos);

		if (_source[_pos] != ')') {
			uint argCount = 1;
			uint i;
			for (i = _pos; i < _source.length && _source[i] != ')'; ++i)
				if (_source[i] == ',')
					++argCount;
			if (i == _source.length)
				return (pred, _pos);

			pred.arguments = new Term[](argCount);
			uint arg = 0;
			do {
				(pred.arguments[arg++], _pos) = parseAtom(_source, _pos);
				if (_pos >= _source.length)
					return (pred, _pos);
				_pos = skipBlanks(_source, _pos);
			} while (_pos < _source.length && _source[_pos++] == ',');

			if (_source[_pos - 1] != ')')
				return (pred, _pos);
			if (arg != argCount)
				return (pred, _pos);
		}

		pred.symbol = name.symbol;
		pred.kind = TermKind.Predicate;
		return (pred, _pos);
	}

	function parseAtom(bytes memory _source, uint _pos) internal pure returns (Term memory atom, uint) {
		_pos = skipBlanks(_source, _pos);
		uint endAtom = _pos;
		while (endAtom < _source.length && (isDigit(_source[endAtom]) || isAlpha(_source[endAtom]) || isUnderscore(_source[endAtom])))
			++endAtom;

		if (endAtom == _pos)
			return (atom, _pos);

		bytes memory lit = new bytes(endAtom - _pos);
		for (uint i = _pos; i < endAtom; ++i)
			lit[i - _pos] = _source[i];

		byte first = lit[0];
		if (isDigit(first)) {
			for (uint l = 1; l < lit.length; ++l)
				if (!isDigit(lit[l]))
					return (atom, _pos);
			atom.kind = TermKind.Number;
			atom.symbol = str2uint(lit);
		}
		else if (isUnderscore(first) && lit.length == 1) {
				atom.kind = TermKind.Ignore;
				atom.symbol = 1;
		}
		else {
			if (isUppercase(first))
				atom.kind = TermKind.Variable;
			else
				atom.kind = TermKind.Predicate;
			atom.symbol = uint(keccak256(lit));
		}
		return (atom, endAtom);
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
