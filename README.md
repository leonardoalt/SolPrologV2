# SolPrologV2

A Prolog engine written in Solidity.

```solidity
pragma solidity ^0.7.0;

// SPDX-License-Identifier: GPLv3

contract PrologContract {
    struct Term {
        string value;      // If empty, term is a list, otherwise it's a predicate.
                           // value can represent an atom, variable, | or _.
        Term[] children;
    }

    struct Rule {
        Term head;
        Term[] body;
    }

    Term[] predicates;
    Rule[] rules;

    function t(string memory value)                                                                             internal returns (Term memory) {}
    function t(string memory value, Term memory term1)                                                          internal returns (Term memory) {}
    function t(string memory value, Term memory term1, Term memory term2)                                       internal returns (Term memory) {}
    function t(string memory value, Term memory term1, Term memory term2, Term memory term3)                    internal returns (Term memory) {}
    function t(string memory value, Term memory term1, Term memory term2, Term memory term3, Term memory term4) internal returns (Term memory) {}

    function list()                                                                           internal returns (Term memory) {}
    function list(Term memory term1)                                                          internal returns (Term memory) {}
    function list(Term memory term1, Term memory term2)                                       internal returns (Term memory) {}
    function list(Term memory term1, Term memory term2, Term memory term3)                    internal returns (Term memory) {}
    function list(Term memory term1, Term memory term2, Term memory term3, Term memory term4) internal returns (Term memory) {}

    function rule(Term memory head, Term memory body1)                                                          internal returns (Rule memory) {}
    function rule(Term memory head, Term memory body1, Term memory body2)                                       internal returns (Rule memory) {}
    function rule(Term memory head, Term memory body1, Term memory body2, Term memory body3)                    internal returns (Rule memory) {}
    function rule(Term memory head, Term memory body1, Term memory body2, Term memory body3, Term memory body4) internal returns (Rule memory) {}

    function def(Term memory predicate) internal { /* predicates.push(...); */ }
    function def(Rule memory rule)      internal { /* rules.push(...); */ }
}

contract PrologExample is PrologContract {
    constructor() {
        /*
        % Atom
        adam.
        eve.

        % Predicate
        man(adam).
        man(peter).
        man(paul).

        woman(mary).
        woman(eve).

        parent(adam, peter).
        parent(eve,  peter).
        parent(adam, paul).
        parent(mary, paul).

        % Rule
        father(F, C) :- man(F),   parent(F,C).
        mother(M, C) :- woman(M), parent(M,C).

        % Wildcard
        is_father(F) :- father(F, _).
        is_mother(M) :- mother(M, _).

        % Operator
        siblings(A, B) :- parent(P, A), parent(P, B), A \= B.

        % Multiple definitions
        human(H) :- man(H).
        human(H) :- woman(H).

        % Recursive rule
        descendant(D, A) :- parent(A, D).
        descendant(D, A) :- parent(P, D), descendant(P, A).

        % Nesting
        make_date(Y, M, D, date(Y, M, D)).

        % Arithmetic
        get_year(date(Y, _, _), Y).
        set_year(Y, date(_, M, D), date(Y, M, D)).
        next_year(Today, NextYear) :- get_year(Today, Y), NY is Y + 1, set_year(NY, Today, NextYear).

        % List
        [].
        head(H, [H|_]).
        tail(T, [_|T]).
        */

        Term memory adam  = t("adam");
        Term memory peter = t("peter");
        Term memory paul  = t("paul");
        Term memory eve   = t("eve");
        Term memory mary  = t("mary");

        Term memory A  = t("A");
        Term memory B  = t("B");
        Term memory C  = t("C");
        Term memory D  = t("D");
        Term memory H  = t("H");
        Term memory F  = t("F");
        Term memory M  = t("M");
        Term memory P  = t("P");
        Term memory T  = t("T");
        Term memory Y  = t("Y");
        Term memory NY  = t("NY");
        Term memory Today  = t("Today");
        Term memory NextYear  = t("NextYear");
        Term memory _  = t("_");

        def(adam);
        def(eve);

        def(t("man", adam));
        def(t("man", peter));
        def(t("man", paul));

        def(t("woman", mary));
        def(t("woman", eve));

        def(t("parent", adam, peter));
        def(t("parent", eve,  peter));
        def(t("parent", adam, paul));
        def(t("parent", adam, paul));

        def(rule(t("father", F, C),
            t("man",    F),
            t("parent", F, C)
        ));
        def(rule(t("mother", t("M"), t("C")),
            t("woman",  M),
            t("parent", M, C)
        ));

        def(rule(t("is_father", F), t("father", F, _)));
        def(rule(t("is_mother", M), t("mother", M, _)));

        def(rule(t("siblings", A, B),
            t("parent", P, A),
            t("parent", P, B),
            t("\\=", A, B)
        ));

        def(rule(t("human", H), t("man",   H)));
        def(rule(t("human", H), t("woman", H)));

        def(rule(t("descendant", D, A),
            t("parent", A, D)
        ));
        def(rule(t("descendant", D, A),
            t("parent", P, D),
            t("descendant", P, A)
        ));

        def(t("make_date", Y, M, D, t("date", Y, M, D)));

        def(t("get_year", t("date", Y, _, _), Y));
        def(t("set_year", Y, t("date", _, M, D), t("date", Y, M, D)));
        def(rule(t("next_year", Today, NextYear),
            t("get_year", Today, Y),
            t("is", NY, t("+", Y, t("1"))),
            t("get_year", NY, Today, NextYear)
        ));

        def(list());
        def(t("head", H, list(H, t("|"), _)));
        def(t("tail", T, list(_, t("|"), T)));
    }
}
```
