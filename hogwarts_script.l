%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Enumeração de Tokens Temáticos */
typedef enum {
  T_EOF = 0,
  T_ID = 258,
  T_INT_LITERAL,
  T_FLOAT_LITERAL,
  
  // Keywords Mágicas
  T_GRYFFINDOR, // int
  T_RAVENCLAW,   // float
  T_HUFFLEPUFF,  // [ ] (vetor)
  T_SLYTHERIN,   // void
  T_DUMBLEDORE,  // if
  T_SEVERUS,     // else
  T_DOBBY,       // while
  T_SPELL,       // function start
  T_ACCIO,       // return
  T_CAST,        // call
  T_AVADA,       // end block
  
  // Operadores e Pontuação
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

%option noyywrap

/* Definições de Erros Regulares */
ID               [A-Za-z][A-Za-z0-9_]*
INT_LITERAL      [0-9]+
FLOAT_LITERAL    [0-9]+\.[0-9]+

/* Comentários Mágicos */
COMENTARIO_LINHA "// lumos"[^\n]*
COMENTARIO_BLOCO "/* aparecium"([^*]|\*+[^*/])*(\*+\/)?

%%
[ \t\r]+           { /* Ignorar espaços */ }
\n                 { line_count++; }

{COMENTARIO_LINHA} { /* Ignora comentário de linha */ }
{COMENTARIO_BLOCO} { /* Ignora comentário de bloco */ }

/* Palavras-Chave de Hogwarts */
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

/* Literais e IDs */
{FLOAT_LITERAL}    { return T_FLOAT_LITERAL; }
{INT_LITERAL}      { return T_INT_LITERAL; }
{ID}  { yylval = get_symbol_position(yytext); return T_ID; }

/* Operadores de Comparação (Sempre antes do simples '=') */
"=="               { return T_OP_IGUAL; }
"!="               { return T_OP_DIFERENTE; }
">="               { return T_OP_MAIOR_IGUAL; }
"<="               { return T_OP_MENOR_IGUAL; }
">"                { return T_OP_MAIOR; }
"<"                { return T_OP_MENOR; }
"="                { return T_OP_ATRIB; }

    /* Operadores Aritméticos */
"+"                { return T_OP_SOMA; }
"-"                { return T_OP_SUB; }
"*"                { return T_OP_MULT; }
"/"                { return T_OP_DIV; }

    /* Pontuação */
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