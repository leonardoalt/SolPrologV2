// SPDX-License-Identifier: GPL V3
pragma solidity ^0.7.0;

enum TermKind {
	Number,
	Ignore,
	Literal,
	Variable,
	List,
	Predicate
}

struct Term {
	TermKind kind;
	uint symbol;
	Term[] arguments;
}

struct FrontendTerm {
	bytes value;
	FrontendTerm[] children;
}

struct Rule {
	Term head;
	Term[] body;
}
