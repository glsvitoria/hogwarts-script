%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();
extern int line_count;
%}

%union {
  int int_literal;
  float float_literal;
  int id;
}

/* Tokens declaração de variáveis e vetores */
%token T_GRYFFINDOR T_RAVENCLAW T_HUFFLEPUFF T_SLYTHERIN
%token T_DUMBLEDORE T_SEVERUS T_DOBBY T_SPELL T_ACCIO T_CAST T_AVADA

/* Tokens de Literais e Identificadores */
%token <int_literal> T_INT_LITERAL
%token <float_literal> T_FLOAT_LITERAL
%token <id> T_ID

/* Tokens de Operadores e Símbolos Especiais */
%token T_OP_IGUAL T_OP_DIFERENTE T_OP_MAIOR_IGUAL T_OP_MENOR_IGUAL T_OP_MAIOR T_OP_MENOR
%token T_OP_ATRIB T_OP_SOMA T_OP_SUB T_OP_MULT T_OP_DIV
%token T_PAREN_ESQ T_PAREN_DIR T_COLCHETE_ESQ T_COLCHETE_DIR T_VIRGULA
%token T_UNKNOWN

/* Menor precedência: Atribuição */
%right T_OP_ATRIB

/* Operadores Relacionais */
%left T_OP_IGUAL T_OP_DIFERENTE
%left T_OP_MENOR T_OP_MAIOR T_OP_MENOR_IGUAL T_OP_MAIOR_IGUAL

/* Operadores Aritméticos */
%left T_OP_SOMA T_OP_SUB
%left T_OP_MULT T_OP_DIV

/* Maior precedência: Menos Unário */
%right UMINUS

%%

programa: lista_declaracoes
        ;

lista_declaracoes: lista_declaracoes declaracao 
                 | declaracao
                 ;

declaracao: declaracao_variavel 
          | declaracao_funcao
          ;

tipo: T_GRYFFINDOR 
    | T_RAVENCLAW 
    | T_HUFFLEPUFF 
    | T_SLYTHERIN
    ;

declaracao_variavel: tipo T_ID T_PV 
                   | tipo T_ID T_OP_ATRIB expressao T_PV
                   ;

declaracao_funcao: tipo T_ID T_PAREN_ESQ parametros T_PAREN_DIR bloco
                 | T_DUMBLEDORE T_ID T_PAREN_ESQ parametros T_PAREN_DIR bloco
                 ;

parametros: 
          | lista_parametros
          ;

lista_parametros: lista_parametros T_VIRGULA parametro
                | parametro
                ;

parametro: tipo T_ID
         ;

bloco: T_CHAVE_ESQ lista_comandos T_CHAVE_DIR
     ;

lista_comandos: lista_comandos comando
              | 
              ;

comando: declaracao_variavel
       | T_ID T_OP_ATRIB expressao T_PV 
       | T_SPELL T_PAREN_ESQ expressao T_PAREN_DIR T_PV 
       ;

expressao: expressao T_OP_SOMA expressao
         | expressao T_OP_SUB expressao
         | expressao T_OP_MULT expressao
         | expressao T_OP_DIV expressao
         | T_OP_SUB expressao %prec UMINUS
         | T_PAREN_ESQ expressao T_PAREN_DIR
         | T_INT_LITERAL
         | T_FLOAT_LITERAL
         | T_ID
         ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", line_count, s);
}