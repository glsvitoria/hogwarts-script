/* Node vai para o parser.tab.h, visível pelo lexer */
%code requires {
    #define MAX_CHILDREN 12
    #define MAX_NAME     64

    typedef struct Node {
        char        name[MAX_NAME];
        struct Node *children[MAX_CHILDREN];
        int          n;
    } Node;
}

/* Código interno do parser — aparece após as declarações geradas */
%code {
    #include <stdio.h>
    #include <string.h>

    int  yylex(void);
    void yyerror(const char *s);
    extern int   line_count;
    extern FILE *yyin;

    #define MAX_NODES 500
    static Node pool[MAX_NODES];
    static int  pool_idx = 0;

    static Node *new_node(const char *s) {
        Node *nd = &pool[pool_idx++];
        strncpy(nd->name, s, MAX_NAME - 1);
        nd->n = 0;
        return nd;
    }

    static void add(Node *p, Node *c) {
        if (p && c && p->n < MAX_CHILDREN) p->children[p->n++] = c;
    }

    static void print_tree(Node *nd, int d) {
        if (!nd) return;
        for (int i = 0; i < d; i++) printf("        ");
        printf("%s\n", nd->name);
        for (int i = 0; i < nd->n; i++) print_tree(nd->children[i], d + 1);
    }
}

%union {
    int   int_val;
    float float_val;
    char *str_val;
    Node *node;
}

%token T_GRYFFINDOR T_RAVENCLAW T_HUFFLEPUFF T_SLYTHERIN
%token T_DUMBLEDORE T_SEVERUS T_DOBBY T_SPELL T_ACCIO T_CAST T_AVADA
%token <int_val>   T_INT_LITERAL
%token <float_val> T_FLOAT_LITERAL
%token <str_val>   T_ID
%token T_OP_IGUAL T_OP_DIFERENTE T_OP_MAIOR_IGUAL T_OP_MENOR_IGUAL
%token T_OP_MAIOR T_OP_MENOR T_OP_ATRIB
%token T_OP_SOMA T_OP_SUB T_OP_MULT T_OP_DIV
%token T_PAREN_ESQ T_PAREN_DIR T_COLCHETE_ESQ T_COLCHETE_DIR T_VIRGULA
%token T_UNKNOWN

%type <node> programa lista_comandos comando tipo
%type <node> declaracao_variavel declaracao_vetor declaracao_funcao
%type <node> atribuicao atribuicao_vetor
%type <node> cmd_if cmd_while cmd_return cmd_cast
%type <node> parametros lista_parametros parametro
%type <node> argumentos lista_argumentos
%type <node> expressao

%right T_OP_ATRIB
%left  T_OP_IGUAL T_OP_DIFERENTE
%left  T_OP_MENOR T_OP_MAIOR T_OP_MENOR_IGUAL T_OP_MAIOR_IGUAL
%left  T_OP_SOMA T_OP_SUB
%left  T_OP_MULT T_OP_DIV
%right UMINUS

%%

programa
    : lista_comandos
        { $$ = new_node("programa"); add($$, $1); print_tree($$, 0); }
    ;

lista_comandos
    : lista_comandos comando  { $$ = $1; add($$, $2); }
    | /* vazio */             { $$ = new_node("lista_comandos"); }
    ;

comando
    : declaracao_variavel { $$ = new_node("comando"); add($$, $1); }
    | declaracao_vetor    { $$ = new_node("comando"); add($$, $1); }
    | declaracao_funcao   { $$ = new_node("comando"); add($$, $1); }
    | atribuicao          { $$ = new_node("comando"); add($$, $1); }
    | atribuicao_vetor    { $$ = new_node("comando"); add($$, $1); }
    | cmd_if              { $$ = new_node("comando"); add($$, $1); }
    | cmd_while           { $$ = new_node("comando"); add($$, $1); }
    | cmd_return          { $$ = new_node("comando"); add($$, $1); }
    | cmd_cast            { $$ = new_node("comando"); add($$, $1); }
    ;

tipo
    : T_GRYFFINDOR { $$ = new_node("gryffindor"); }
    | T_RAVENCLAW  { $$ = new_node("ravenclaw");  }
    | T_SLYTHERIN  { $$ = new_node("slytherin");  }
    ;

declaracao_variavel
    : tipo T_ID
        { $$ = new_node("declaracao_variavel"); add($$,$1); add($$,new_node($2)); }
    | tipo T_ID T_OP_ATRIB expressao
        { $$ = new_node("declaracao_variavel"); add($$,$1); add($$,new_node($2)); add($$,new_node("=")); add($$,$4); }
    ;

declaracao_vetor
    : T_HUFFLEPUFF T_ID T_COLCHETE_ESQ T_INT_LITERAL T_COLCHETE_DIR
        {
            char buf[32]; sprintf(buf, "%d", $4);
            $$ = new_node("declaracao_vetor");
            add($$, new_node($2)); add($$, new_node(buf));
        }
    ;

declaracao_funcao
    : T_SPELL tipo T_ID T_PAREN_ESQ parametros T_PAREN_DIR lista_comandos T_AVADA
        {
            $$ = new_node("declaracao_funcao");
            add($$,$2); add($$,new_node($3)); add($$,$5); add($$,$7);
        }
    ;

parametros
    : /* vazio */      { $$ = new_node("parametros"); }
    | lista_parametros { $$ = $1; }
    ;

lista_parametros
    : lista_parametros T_VIRGULA parametro { $$ = $1; add($$, $3); }
    | parametro { $$ = new_node("parametros"); add($$, $1); }
    ;

parametro
    : tipo T_ID
        { $$ = new_node("parametro"); add($$,$1); add($$,new_node($2)); }
    ;

atribuicao
    : T_ID T_OP_ATRIB expressao
        { $$ = new_node("atribuicao"); add($$,new_node($1)); add($$,$3); }
    ;

atribuicao_vetor
    : T_ID T_COLCHETE_ESQ expressao T_COLCHETE_DIR T_OP_ATRIB expressao
        { $$ = new_node("atribuicao_vetor"); add($$,new_node($1)); add($$,$3); add($$,$6); }
    ;

cmd_if
    : T_DUMBLEDORE T_PAREN_ESQ expressao T_PAREN_DIR lista_comandos T_AVADA
        {
            $$ = new_node("if_statement");
            Node *cond = new_node("condition"); add(cond,$3);
            add($$,cond); add($$,$5);
        }
    | T_DUMBLEDORE T_PAREN_ESQ expressao T_PAREN_DIR lista_comandos T_SEVERUS lista_comandos T_AVADA
        {
            $$ = new_node("if_statement");
            Node *cond = new_node("condition"); add(cond,$3);
            Node *els  = new_node("else");      add(els,$7);
            add($$,cond); add($$,$5); add($$,els);
        }
    ;

cmd_while
    : T_DOBBY T_PAREN_ESQ expressao T_PAREN_DIR lista_comandos T_AVADA
        {
            $$ = new_node("while_statement");
            Node *cond = new_node("condition"); add(cond,$3);
            add($$,cond); add($$,$5);
        }
    ;

cmd_return
    : T_ACCIO expressao
        { $$ = new_node("return"); add($$,$2); }
    ;

cmd_cast
    : T_CAST T_ID T_PAREN_ESQ argumentos T_PAREN_DIR
        { $$ = new_node("chamada_funcao"); add($$,new_node($2)); add($$,$4); }
    ;

argumentos
    : /* vazio */      { $$ = new_node("argumentos"); }
    | lista_argumentos { $$ = $1; }
    ;

lista_argumentos
    : lista_argumentos T_VIRGULA expressao { $$ = $1; add($$,$3); }
    | expressao { $$ = new_node("argumentos"); add($$,$1); }
    ;

expressao
    : expressao T_OP_SOMA         expressao { $$ = new_node("soma");          add($$,$1); add($$,$3); }
    | expressao T_OP_SUB          expressao { $$ = new_node("subtracao");     add($$,$1); add($$,$3); }
    | expressao T_OP_MULT         expressao { $$ = new_node("multiplicacao"); add($$,$1); add($$,$3); }
    | expressao T_OP_DIV          expressao { $$ = new_node("divisao");       add($$,$1); add($$,$3); }
    | expressao T_OP_IGUAL        expressao { $$ = new_node("igual");         add($$,$1); add($$,$3); }
    | expressao T_OP_DIFERENTE    expressao { $$ = new_node("diferente");     add($$,$1); add($$,$3); }
    | expressao T_OP_MAIOR        expressao { $$ = new_node("maior");         add($$,$1); add($$,$3); }
    | expressao T_OP_MENOR        expressao { $$ = new_node("menor");         add($$,$1); add($$,$3); }
    | expressao T_OP_MAIOR_IGUAL  expressao { $$ = new_node("maior_igual");   add($$,$1); add($$,$3); }
    | expressao T_OP_MENOR_IGUAL  expressao { $$ = new_node("menor_igual");   add($$,$1); add($$,$3); }
    | T_OP_SUB expressao %prec UMINUS       { $$ = new_node("negacao");       add($$,$2); }
    | T_PAREN_ESQ expressao T_PAREN_DIR     { $$ = $2; }
    | T_INT_LITERAL
        { char buf[32]; sprintf(buf,"%d",$1); $$ = new_node(buf); }
    | T_FLOAT_LITERAL
        { char buf[32]; sprintf(buf,"%g",$1); $$ = new_node(buf); }
    | T_ID
        { $$ = new_node($1); }
    | T_ID T_COLCHETE_ESQ expressao T_COLCHETE_DIR
        { $$ = new_node("acesso_vetor"); add($$,new_node($1)); add($$,$3); }
    | T_CAST T_ID T_PAREN_ESQ argumentos T_PAREN_DIR
        { $$ = new_node("chamada_funcao"); add($$,new_node($2)); add($$,$4); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", line_count, s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) { fprintf(stderr, "Arquivo não encontrado: %s\n", argv[1]); return 1; }
        yyin = f;
    }
    return yyparse();
}
