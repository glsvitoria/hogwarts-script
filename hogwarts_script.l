%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef enum {
  T_EOF = 0,
  T_ID = 258,
  T_INT_LITERAL,
  T_FLOAT_LITERAL,
  
  T_GRYFFINDOR,
  T_RAVENCLAW,
  T_HUFFLEPUFF,
  T_SLYTHERIN,
  T_DUMBLEDORE,
  T_SEVERUS,
  T_DOBBY,
  T_SPELL,
  T_ACCIO,
  T_CAST,
  T_AVADA,
  
  T_OP_SOMA, 
  T_OP_SUB, 
  T_OP_MULT, 
  T_OP_DIV, 
  T_OP_ATRIB,
  T_OP_IGUAL, 
  T_OP_DIFERENTE, 
  T_OP_MAIOR, 
  T_OP_MENOR, 
  T_OP_MAIOR_IGUAL, 
  T_OP_MENOR_IGUAL,
  T_PAREN_ESQ, 
  T_PAREN_DIR, 
  T_COLCHETE_ESQ, 
  T_COLCHETE_DIR, 
  T_VIRGULA,
  
  T_UNKNOWN
} TokenType;

int yylval;
int line_count = 1;

#define MAX_SYMBOLS 100
char *symbol_table[MAX_SYMBOLS];
int symbol_count = 0;

int get_symbol_position(const char *id) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i], id) == 0) return i + 1;
    }
    if (symbol_count < MAX_SYMBOLS) {
        symbol_table[symbol_count] = strdup(id);
        return symbol_count++;
    }
    return -1;
}
%}

%x COMMENT
%option noyywrap

ID               [A-Za-z][A-Za-z0-9_]*
INT_LITERAL      [0-9]+
FLOAT_LITERAL    [0-9]+\.[0-9]+

%%
[ \t\r]+           { /* Ignorar espaços */ }
\n                 { line_count++; }

"// lumos"[^\n]*   { /* Ignora comentário de linha */ }

"/* aparecium"     { BEGIN(COMMENT); }
<COMMENT>"*/"      { BEGIN(INITIAL); }
<COMMENT>\n        { line_count++; }
<COMMENT>.         { /* consome caracteres do comentário */ }

"gryffindor"       { return T_GRYFFINDOR; }
"ravenclaw"        { return T_RAVENCLAW; }
"hufflepuff"       { return T_HUFFLEPUFF; }
"slytherin"        { return T_SLYTHERIN; }
"dumbledore"       { return T_DUMBLEDORE; }
"severus"          { return T_SEVERUS; }
"dobby"            { return T_DOBBY; }
"spell"            { return T_SPELL; }
"accio"            { return T_ACCIO; }
"cast"             { return T_CAST; }
"avada"            { return T_AVADA; }

{FLOAT_LITERAL}    { return T_FLOAT_LITERAL; }
{INT_LITERAL}      { return T_INT_LITERAL; }
{ID}               { yylval = get_symbol_position(yytext); return T_ID; }

"=="               { return T_OP_IGUAL; }
"!="               { return T_OP_DIFERENTE; }
">="               { return T_OP_MAIOR_IGUAL; }
"<="               { return T_OP_MENOR_IGUAL; }
">"                { return T_OP_MAIOR; }
"<"                { return T_OP_MENOR; }
"="                { return T_OP_ATRIB; }

"+"                { return T_OP_SOMA; }
"-"                { return T_OP_SUB; }
"*"                { return T_OP_MULT; }
"/"                { return T_OP_DIV; }

"("                { return T_PAREN_ESQ; }
")"                { return T_PAREN_DIR; }
"["                { return T_COLCHETE_ESQ; }
"]"                { return T_COLCHETE_DIR; }
","                { return T_VIRGULA; }

.                  { printf("Erro na linha %d: Feitiço desconhecido '%s'\n", line_count, yytext); return T_UNKNOWN; }

%%

int main(int argc, char **argv) {
  if (argc > 1) {
      FILE *file = fopen(argv[1], "r");
      if (file) yyin = file;
  }

  int token;
  while ((token = yylex())) {
    if (token == T_ID) {
      printf("<id, %d> ", yylval);
    } 
    else if (token == T_INT_LITERAL || token == T_FLOAT_LITERAL) {
      printf("<num, %s> ", yytext);
    }
    else if (token != T_UNKNOWN) {
      printf("<%s> ", yytext);
    }
  }
  printf("\n");

  for (int i = 0; i < symbol_count; i++) free(symbol_table[i]);

  return 0;
}