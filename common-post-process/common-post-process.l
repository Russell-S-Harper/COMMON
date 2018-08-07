%{

#include <stdio.h>
#include <string.h>

#include "common-post-process.tab.h"

%}

DEC	[0-9]+(\.[0-9]+)?
HEX	\$[0-9A-Fa-f]+(\.[0-9A-Fa-f]+)?
OCT	&[0-7]+(\.[0-7]+)?
BIN	%[01]+(\.[01]+)?

%%

[A-Za-z_][A-Za-z0-9_]*	{ strncpy(yylval.sval, yytext, sizeof(yylval.sval)); return IDENTIFIER; }
{DEC}|{HEX}|{OCT}|{BIN}	{ strncpy(yylval.sval, yytext, sizeof(yylval.sval)); return CONSTANT; }
"<<"			return LEFT_OP;
">>"			return RIGHT_OP;
(<=)|(=<)		return LE_OP;
(>=)|(=>)		return GE_OP;
(<>)|(><)		return NE_OP;
"&&"			return AND_OP;
"||"			return OR_OP;
[ \t\n]+        	; /* Ignore whitespace */
[-()<>+~!*/%=&^|]	return yytext[0];
.			{ fprintf(stderr, "SET (invalid character '%s')\n", yytext); exit(1); }

%%

int yywrap(void) {
    return 1;
}
