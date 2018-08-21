#ifndef __XAPP_H
#define __XAPP_H

/* How many bits for ... */

/* ... internal significands */
#define INT_SIGN	48

/* ... internal fractions */
#define INT_FRAC	16

/* ... internal full numbers */
#define INT_FULL	(INT_SIGN + INT_FRAC)

/* ... exported significands */
#define EXP_SIGN	20

/* ... exported fractions */
#define EXP_FRAC	10

/* ... exported full numbers */
#define EXP_FULL	(EXP_SIGN + EXP_FRAC)

/*
	Internal calculations may require left shifting of
	numbers by INT_FRAC bits, so be aware that the higher
	bits of numbers may be lost if multiplying or dividing
	large numbers.

	These are the safe upper limits for various internal
	significand and fraction combinations in bits.

	+----------+----------+-------------+
	| INT_SIGN | INT_FRAC | Upper Limit |
	+----------+----------+-------------+
	|    64    |     0    |   2^63-1    |
	|    56    |     8    |   2^47-1    |
	|    48    |    16    |   2^31-1    |
	|    40    |    24    |   2^15-1    |
	+----------+----------+-------------+
*/

/* Definitions for flex and bison */

#ifndef TOKEN_LEN
#define TOKEN_LEN	256
#endif /* TOKEN_LEN */
#define TOKENS		128
#define IO_BUFFER	(TOKENS * TOKEN_LEN)

typedef enum
{
	TT_COMMAND, TT_DEFAULT, TT_WHITE_SPACE, TT_END_OF_LINE
} TOKEN_TYPE;

typedef struct
{
	TOKEN_TYPE type;
	char text[TOKEN_LEN];
} TOKEN;

extern long long result;

int yyparse (void);
void yyerror(char const *s);

int tokenizeInput(const char *cursor, TOKEN *tokens);
long long parseCommon(const char *input);
long long shiftCommon(long long base, long long amount);

#endif /* __XAPP_H */
