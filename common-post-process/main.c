#include <stdio.h>
#include <limits.h>
#include <string.h>

#include "common-post-process.h"
#include "common-post-process.yy.h"

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
				int j;
				unsigned long working;
				const char *s = "", *p, *q;
				switch (tokens[i].type)
				{
					/* Process each _SET_V("<expr>") command */
					case TT_COMMAND:
						/* Extract the start and ending indices */
						p = strchr(tokens[i].text, '"') + 1;
						q = strrchr(tokens[i].text, '"');
						/* Parse the input */
						yyin = fmemopen((void *)p, q - p, "r");
						yyparse();
						fclose(yyin);
						/* Output */
						working = (unsigned long)((result >> (INT_FRAC - EXP_FRAC)) % (1 << EXP_FULL));
						for (j = 0; j < EXP_FULL; j += CHAR_BIT)
						{
							printf("%s$%02lX", s, working & 0xff);
							working >>= CHAR_BIT;
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
