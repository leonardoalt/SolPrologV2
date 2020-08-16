// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.7;

import './Logic.sol';

library Encoder {
	struct Info {
		mapping (uint => bytes) hash2Symbol;
	}

	function encode(FrontendTerm memory _inTerm, Info storage _info) internal returns (Term memory outTerm) {
		assert(_inTerm.value.length > 0);

		byte first = _inTerm.value[0];
		if (first == '[') {
			if (_inTerm.value[1] == ']')
				outTerm.kind = TermKind.List;
			else {
				assert(_inTerm.value[1] == '|');
				assert(_inTerm.value[2] == ']');
				outTerm.kind = TermKind.ListHeadTail;
			}
		}
		else if (isDigit(first))
			outTerm.kind = TermKind.Number;
		else if (isUppercase(first))
			outTerm.kind = TermKind.Variable;
		else if (_inTerm.value.length == 1 && first == '_')
			outTerm.kind = TermKind.Ignore;
		else
			outTerm.kind = TermKind.Predicate;

		if (outTerm.kind == TermKind.Number)
			outTerm.symbol = str2uint(_inTerm.value);
		else {
			outTerm.symbol = uint(keccak256(_inTerm.value));
			_info.hash2Symbol[outTerm.symbol] = _inTerm.value;
		}

		outTerm.arguments = new Term[](_inTerm.children.length);
		for (uint i = 0; i < _inTerm.children.length; ++i)
			outTerm.arguments[i] = encode(_inTerm.children[i], _info);
	}

	function str2uint(bytes memory _str) internal pure returns (uint n) {
		assert(_str.length > 0);
		uint p10 = 1;
		for (uint i = _str.length; i > 0; --i) {
			n += p10 * (uint8(_str[i - 1]) - 48);
			p10 *= 10;
		}
	}

	function isDigit(byte _char) internal pure returns (bool) {
		return _char >= '0' && _char <= '9';
	}

	function isLowercase(byte _char) internal pure returns (bool) {
		return _char >= 'a' && _char <= 'z';
	}

	function isUppercase(byte _char) internal pure returns (bool) {
		return _char >= 'A' && _char <= 'Z';
	}
}
