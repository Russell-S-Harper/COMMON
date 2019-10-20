%define parse.error verbose

%code requires {
	#include "xapp.h"
}

%{
	#include <stdlib.h>
	#include <stdio.h>
	#include <limits.h>
	#include <math.h>

	#include "xapp.h"
	#include "xapp.yy.h"
%}

%union {
	long long ival;
	char sval[TOKEN_LEN];
}

%token <sval> CONSTANT IDENTIFIER
%token LEFT_OP RIGHT_OP LE_OP GE_OP NE_OP AND_OP OR_OP

%type <ival> expr primary_expr unary_expr mult_expr add_expr shift_expr rel_expr eq_expr and_expr xor_expr or_expr logical_and_expr logical_or_expr

%start expr
%%

primary_expr
	: '*'						{ fprintf(stderr, "SET (program counter * is not allowed)\n"); exit(1); }
	| IDENTIFIER					{ fprintf(stderr, "SET (unsubstituted constant '%s', use #define)\n", $1); exit(1); }
	| CONSTANT					{ $$ = parseCommon($1); }
	| '(' expr ')'					{ $$ = $2; }
	;

unary_expr
	: primary_expr
	| '<' unary_expr				{ $$ = $2 & (0xff << INT_FRAC); }
	| '>' unary_expr				{ $$ = $2 >> CHAR_BIT & (0xff << INT_FRAC); }
	| '+' unary_expr				{ $$ = +$2; }
	| '-' unary_expr				{ $$ = -$2; }
	| '~' unary_expr				{ $$ = ~$2; }
	| '!' unary_expr				{ $$ = !$2; }
	;

mult_expr
	: unary_expr
	| mult_expr '*' unary_expr			{ $$ = ($1 * $3) >> INT_FRAC; }
	| mult_expr '/' unary_expr			{ $$ = ($1 << INT_FRAC) / $3; }
	| mult_expr '%' unary_expr			{ $$ = $1 % $3; }
	;

add_expr
	: mult_expr
	| add_expr '+' mult_expr			{ $$ = $1 + $3; }
	| add_expr '-' mult_expr			{ $$ = $1 - $3; }
	;

shift_expr
	: add_expr
	| shift_expr LEFT_OP add_expr			{ $$ = shiftCommon($1, +$3); }
	| shift_expr RIGHT_OP add_expr			{ $$ = shiftCommon($1, -$3); }
	;

rel_expr
	: shift_expr
	| rel_expr '<' shift_expr			{ $$ = ($1 < $3)? 1: 0; }
	| rel_expr '>' shift_expr			{ $$ = ($1 > $3)? 1: 0; }
	| rel_expr LE_OP shift_expr			{ $$ = ($1 <= $3)? 1: 0; }
	| rel_expr GE_OP shift_expr			{ $$ = ($1 >= $3)? 1: 0; }
	;

eq_expr
	: rel_expr
	| eq_expr '=' rel_expr				{ $$ = ($1 == $3)? 1: 0; }
	| eq_expr NE_OP rel_expr			{ $$ = ($1 == $3)? 0: 1; }
	;

and_expr
	: eq_expr
	| and_expr '&' eq_expr				{ $$ = $1 & $3; }
	;

xor_expr
	: and_expr
	| xor_expr '^' and_expr				{ $$ = $1 ^ $3; }
	;

or_expr
	: xor_expr
	| or_expr '|' xor_expr				{ $$ = $1 | $3; }
	;

logical_and_expr
	: or_expr
	| logical_and_expr AND_OP or_expr		{ $$ = ($1 && $3)? 1: 0; }
	;

logical_or_expr
	: logical_and_expr
	| logical_or_expr OR_OP logical_and_expr	{ $$ = ($1 || $3)? 1: 0; }
	;

expr
	: logical_or_expr				{ result = $1; }
	;

%%

void yyerror(char const *s)
{
	fprintf (stderr, "SET (%s)\n", s);
	exit(1);
}

long long parseCommon(const char *input)
{
	char digit[2] = {'\0', '\0'};
	double base = 10.0, working = 0.0;
	int sign;
	long long output;
	/* Check the first character for a base specification */
	switch (*input) {
		case '$':
			base = 16.0;
			++input;
			break;
		case '&':
			base = 8.0;
			++input;
			break;
		case '%':
			base = 2.0;
			++input;
			break;
	}
	/* Get all the digits before the point */
	while (*input && *input != '.') {
		digit[0] = *input;
		working = working * base + (double)strtol(digit, NULL, base);
		++input;
	}
	/* Has a fraction? */
	if (*input == '.') {
		double fraction = 0.0, divisor = 1.0;
		++input;
		/* Get all the digits after the point */
		while (*input) {
			digit[0] = *input;
			fraction = fraction * base + (double)strtol(digit, NULL, base);
			divisor *= base;
			++input;
		}
		/* Convert to fraction and add it */
		working += fraction / divisor;
	}
	/* Convert to integer */
	sign = (working < 0.0)? -1: +1;
	output = sign * (long long)floor(fabs(working) * (double)(1 << INT_FRAC));
	/* Done */
	return output;
}

long long shiftCommon(long long base, long long amount)
{
	double scaling = (double)(1 << INT_FRAC);
	double x = (double) base / scaling, y = (double) amount / scaling;
	double working = x * pow(2.0, y);
	int sign = (working < 0.0)? -1: +1;
	return sign * (long long)floor(fabs(working) * scaling);
}
