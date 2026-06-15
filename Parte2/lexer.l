%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.tab.h"

int line_count = 1;
%}

%x COMMENT
%option noyywrap

ID            [A-Za-z][A-Za-z0-9_]*
INT_LITERAL   [0-9]+
FLOAT_LITERAL [0-9]+\.[0-9]+

%%

[ \t\r]+           { /* ignora espaços */ }
\n                 { line_count++; }

"// lumos"[^\n]*   { /* comentário de linha */ }
"/* aparecium"     { BEGIN(COMMENT); }
<COMMENT>"*/"      { BEGIN(INITIAL); }
<COMMENT>\n        { line_count++; }
<COMMENT>.         { }

"gryffindor"       { return T_GRYFFINDOR; }
"ravenclaw"        { return T_RAVENCLAW;  }
"hufflepuff"       { return T_HUFFLEPUFF; }
"slytherin"        { return T_SLYTHERIN;  }
"dumbledore"       { return T_DUMBLEDORE; }
"severus"          { return T_SEVERUS;    }
"dobby"            { return T_DOBBY;      }
"spell"            { return T_SPELL;      }
"accio"            { return T_ACCIO;      }
"cast"             { return T_CAST;       }
"avada"            { return T_AVADA;      }

{FLOAT_LITERAL}    { yylval.float_val = atof(yytext); return T_FLOAT_LITERAL; }
{INT_LITERAL}      { yylval.int_val   = atoi(yytext); return T_INT_LITERAL;   }
{ID}               { yylval.str_val   = strdup(yytext); return T_ID;          }

"=="               { return T_OP_IGUAL;       }
"!="               { return T_OP_DIFERENTE;   }
">="               { return T_OP_MAIOR_IGUAL; }
"<="               { return T_OP_MENOR_IGUAL; }
">"                { return T_OP_MAIOR;       }
"<"                { return T_OP_MENOR;       }
"="                { return T_OP_ATRIB;       }

"+"                { return T_OP_SOMA;       }
"-"                { return T_OP_SUB;        }
"*"                { return T_OP_MULT;       }
"/"                { return T_OP_DIV;        }

"("                { return T_PAREN_ESQ;    }
")"                { return T_PAREN_DIR;    }
"["                { return T_COLCHETE_ESQ; }
"]"                { return T_COLCHETE_DIR; }
","                { return T_VIRGULA;      }

.  { fprintf(stderr, "Erro léxico na linha %d: '%s'\n", line_count, yytext); return T_UNKNOWN; }

%%
