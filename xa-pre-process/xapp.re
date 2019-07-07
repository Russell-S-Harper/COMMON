#include <stdio.h>
#include <string.h>

#include "xapp.h"

static int copyToken(TOKEN *tokens, int index, TOKEN_TYPE type, const char *text, int length);

int tokenizeInput(const char *cursor, TOKEN *tokens)
{
	const char *marker, *token;
	int i;

	for (i = 0; *cursor && i < TOKENS; )
	{
		token = cursor;
/*!re2c
		re2c:define:YYCTYPE = "char";
		re2c:define:YYCURSOR = cursor;
		re2c:define:YYMARKER = marker;
		re2c:variable:yych = c;
		re2c:indent:top = 2;
		re2c:yyfill:enable = 0;
		re2c:yych:conversion = 1;

		BELL						= "\x07" ;
		BACKSPACE					= "\x08" ;
		HORIZONTAL_TAB					= "\x09" ;
		LINE_FEED					= "\x0a" ;
		VERTICAL_TAB					= "\x0b" ;
		FORM_FEED					= "\x0c" ;
		CARRIAGE_RETURN					= "\x0d" ;
		ESCAPE						= "\x1b" ;
		DELETE						= "\x7f" ;

		SPACE						= "\x20" ;
		EXCLAMATION_MARK				= "\x21" ;
		QUOTATION_MARK					= "\x22" ;
		NUMBER_SIGN					= "\x23" ;
		DOLLAR_SIGN					= "\x24" ;
		PERCENT_SIGN					= "\x25" ;
		AMPERSAND					= "\x26" ;
		APOSTROPHE					= "\x27" ;
		LEFT_PARENTHESIS				= "\x28" ;
		RIGHT_PARENTHESIS				= "\x29" ;
		ASTERISK					= "\x2a" ;
		PLUS_SIGN					= "\x2b" ;
		COMMA						= "\x2c" ;
		HYPHEN_MINUS					= "\x2d" ;
		FULL_STOP					= "\x2e" ;
		SOLIDUS						= "\x2f" ;
		COLON						= "\x3a" ;
		SEMICOLON					= "\x3b" ;
		LESS_THAN_SIGN					= "\x3c" ;
		EQUALS_SIGN					= "\x3d" ;
		GREATER_THAN_SIGN				= "\x3e" ;
		QUESTION_MARK					= "\x3f" ;
		COMMERCIAL_AT					= "\x40" ;
		LEFT_SQUARE_BRACKET				= "\x5b" ;
		REVERSE_SOLIDUS					= "\x5c" ;
		RIGHT_SQUARE_BRACKET				= "\x5d" ;
		CIRCUMFLEX_ACCENT				= "\x5e" ;
		LOW_LINE					= "\x5f" ;
		GRAVE_ACCENT					= "\x60" ;
		LEFT_CURLY_BRACKET				= "\x7b" ;
		VERTICAL_LINE					= "\x7c" ;
		RIGHT_CURLY_BRACKET				= "\x7d" ;
		TILDE						= "\x7e" ;

		DIGIT		= [0-9] ;

		LETTER		= [A-Za-z] ;

		WHITE_SPACE	= BELL | BACKSPACE | HORIZONTAL_TAB | ESCAPE | DELETE | SPACE ;

		SET_V_BGN	= LOW_LINE [Ss][Ee][Tt] LOW_LINE [Vv] WHITE_SPACE* LEFT_PARENTHESIS WHITE_SPACE* QUOTATION_MARK ;

		SET_V_END	= QUOTATION_MARK WHITE_SPACE* RIGHT_PARENTHESIS ;

		VALID		= DIGIT | LETTER | EXCLAMATION_MARK | DOLLAR_SIGN | PERCENT_SIGN | AMPERSAND
					| LEFT_PARENTHESIS | RIGHT_PARENTHESIS | ASTERISK | PLUS_SIGN | HYPHEN_MINUS
					| FULL_STOP | SOLIDUS | LESS_THAN_SIGN | EQUALS_SIGN | GREATER_THAN_SIGN
					| LOW_LINE | VERTICAL_LINE | TILDE | WHITE_SPACE ;

		LABEL		= SET_V_BGN ( LETTER | LOW_LINE ) ( LETTER | LOW_LINE | DIGIT )* SET_V_END ;

		EXPRESSION	= SET_V_BGN VALID+ SET_V_END ;

		DEFAULT		= . ;

		END_OF_LINE	= ( LINE_FEED | VERTICAL_TAB | FORM_FEED | CARRIAGE_RETURN )+ ;

		LABEL		{ i = copyToken(tokens, i, TT_LABEL, token, (int)(cursor - token)); continue; }
		EXPRESSION	{ i = copyToken(tokens, i, TT_EXPRESSION, token, (int)(cursor - token)); continue; }
		DEFAULT		{ i = copyToken(tokens, i, TT_DEFAULT, token, (int)(cursor - token)); continue; }
		WHITE_SPACE	{ i = copyToken(tokens, i, TT_WHITE_SPACE, token, (int)(cursor - token)); continue; }
		END_OF_LINE	{ i = copyToken(tokens, i, TT_END_OF_LINE, token, (int)(cursor - token)); continue; }
*/
	}

	return i;
}

int copyToken(TOKEN *tokens, int index, TOKEN_TYPE type, const char *text, int length)
{
	if (index < TOKENS)
	{
		int i;

		tokens[index].type = type;

		for (i = 0; i < length && i + 1 < TOKEN_LEN; ++i)
			tokens[index].text[i] = text[i];

		tokens[index].text[i] = '\0';

		++index;
	}
	return index;
}
