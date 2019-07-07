#include <stdio.h>
#include <limits.h>
#include <string.h>

#include "xapp.h"
#include "xapp.yy.h"

long long result;

int main(int argc, char **argv)
{
	TOKEN tokens[TOKENS];
	char buffer[IO_BUFFER] = {'\0'};

	/* Process input */
	while (fgets(buffer, IO_BUFFER, stdin))
	{
		/* Tokenize the line */
		int count;
		if (count = tokenizeInput(buffer, tokens))
		{
			/* Iterate through the tokens */
			int i;
			for (i = 0; i < count; ++i)
			{
				int j, sign;
				const char *s = "", *p, *q;
				switch (tokens[i].type)
				{
					/* Process each _SET_V("<label>") command */
					case TT_LABEL:
						/* Extract the start and ending indices */
						p = strchr(tokens[i].text, '"') + 1;
						q = strrchr(tokens[i].text, '"');
						j = (int)(q - p);
						/* Output in .BYTE format */
						printf("0, <(%.*s - _data), >(%.*s - _data), 0", j, p, j, p);
						break;
					/* Process each _SET_V("<expression>") command */
					case TT_EXPRESSION:
						/* Extract the start and ending indices */
						p = strchr(tokens[i].text, '"') + 1;
						q = strrchr(tokens[i].text, '"');
						/* Parse the input */
						yyin = fmemopen((void *)p, q - p, "r");
						yyparse();
						fclose(yyin);
						/* Round towards ± infinity */
						sign = result < 0? -1: +1;
						if (sign < 0) result = -result;
						result += 1 << (INT_FRAC - EXP_FRAC - 1);
						/* Normalize */
						result >>= (INT_FRAC - EXP_FRAC);
						if (sign < 0) result = -result;
						/* Output in .BYTE format */
						for (j = 0; j < EXP_FULL; j += CHAR_BIT)
						{
							printf("%s$%02llX", s, result & 0xff);
							result >>= CHAR_BIT;
							s = ", ";
						}
						break;
					default:
						/* Default, just print it */
						printf("%s", tokens[i].text);
						break;
				}
			}
		}
	}
	return 0;
}
