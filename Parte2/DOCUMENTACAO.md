# Trabalho 2 - Análise Sintática
## MATA61 - Compiladores

---

## 1. Introdução

Este trabalho implementa o analisador sintático da linguagem **HogwartsScript**, usando **Flex** (análise léxica) e **Bison** (análise sintática). O parser recebe os tokens gerados pelo Flex, verifica se seguem a gramática definida e imprime a árvore sintática do programa.

---

## 2. Mudanças em relação ao Trabalho 1

No Trabalho 1, o lexer (`hogwarts_script.l`) reconhecia tokens e os imprimia diretamente. No Trabalho 2, o mesmo lexer foi adaptado para se integrar ao Bison:

- O `main()` foi movido para o `parser.y`, que agora chama `yyparse()`
- Os tokens passam a ser definidos pelo Bison e compartilhados via `parser.tab.h`
- O `yylval` agora usa a union do Bison para carregar valores semânticos (`str_val` para identificadores, `int_val` e `float_val` para literais)

Além disso, ajustamos a sintaxe da linguagem para ficar mais clara e consistente com os exemplos:

| O que mudou | Antes (Trabalho 1) | Depois (Trabalho 2) |
|---|---|---|
| Delimitador de bloco | `{ }` | palavra-chave `avada` |
| Definição de função | `tipo nome(params) { }` | `spell tipo nome(params) ... avada` |
| `dumbledore` | Usado para função void | Exclusivo do `if` |
| `spell` | Era print (`spell(expr)`) | Exclusivo da definição de função |
| Ponto-e-vírgula | Usado no parser inicial | Removido (a linguagem não usa) |

---

## 3. Regras de Produção e Justificativas

### 3.1 Programa e lista de comandos

```
programa         → lista_comandos
lista_comandos   → lista_comandos comando | ε
```

O programa é uma sequência de comandos. Usamos **recursão à esquerda** em `lista_comandos` porque parsers LR (como o Bison) lidam melhor com ela — recursão à direita causaria crescimento desnecessário na pilha de análise.

A produção vazia (`ε`) permite blocos sem nenhum comando (como uma função com corpo vazio).

---

### 3.2 Tipos

```
tipo → gryffindor | ravenclaw | slytherin
```

Os três tipos escalares da linguagem:
- `gryffindor` = inteiro
- `ravenclaw` = ponto flutuante  
- `slytherin` = void (para funções sem retorno)

`hufflepuff` (vetor) foi retirado daqui porque vetores têm uma sintaxe própria com `[tamanho]`, então ficam em `declaracao_vetor`.

---

### 3.3 Declaração de variável

```
declaracao_variavel → tipo id
                    | tipo id = expressao
```

Duas formas: com ou sem inicialização. Exemplo:
```
gryffindor x
gryffindor y = 10
```

Separamos em duas produções para deixar claro que a inicialização é opcional.

---

### 3.4 Declaração de vetor

```
declaracao_vetor → hufflepuff id [ int_literal ]
```

Vetor de tamanho fixo usando `hufflepuff`. Exemplo: `hufflepuff v[10]`

Separado de `declaracao_variavel` para evitar ambiguidade — se `hufflepuff` fosse um `tipo` normal, o parser não saberia quando esperar `[tamanho]`.

---

### 3.5 Declaração de função

```
declaracao_funcao → spell tipo id ( parametros ) lista_comandos avada
```

Funções começam com `spell`, seguido do tipo de retorno, nome e parâmetros. O corpo é uma `lista_comandos` terminada por `avada`. Exemplo:

```
spell gryffindor soma(gryffindor a, gryffindor b)
  accio a + b
avada
```

Escolhemos `avada` como terminador de bloco (em vez de `}`) para manter a identidade temática da linguagem e não precisar de chaves.

---

### 3.6 Parâmetros

```
parametros       → ε | lista_parametros
lista_parametros → lista_parametros , parametro | parametro
parametro        → tipo id
```

Permite funções sem parâmetros (`spell slytherin vazio() ... avada`) ou com vários (`gryffindor a, ravenclaw b`). Recursão à esquerda em `lista_parametros` pelo mesmo motivo do item 3.1.

---

### 3.7 Atribuição

```
atribuicao       → id = expressao
atribuicao_vetor → id [ expressao ] = expressao
```

Duas formas: atribuição simples e atribuição a elemento de vetor. Exemplo:
```
x = 5
v[0] = x + 1
```

São produções separadas para facilitar a leitura da gramática e as ações semânticas.

---

### 3.8 Estruturas de controle

**If simples e If-Else:**
```
cmd_if → dumbledore ( expressao ) lista_comandos avada
       | dumbledore ( expressao ) lista_comandos severus lista_comandos avada
```

`dumbledore` abre, `severus` separa o else e `avada` fecha. Exemplo:
```
dumbledore (x > 0)
  gryffindor y = 1
severus
  gryffindor y = 0
avada
```

Duas produções distintas evitam o problema do "dangling-else" — o parser sabe exatamente quando há ou não um ramo `severus` pelo lookahead.

**While:**
```
cmd_while → dobby ( expressao ) lista_comandos avada
```

`dobby` abre o laço e `avada` fecha. Exemplo:
```
dobby (i < 10)
  i = i + 1
avada
```

---

### 3.9 Return e chamada de função

```
cmd_return → accio expressao
cmd_cast   → cast id ( argumentos )
```

`accio` retorna um valor de dentro de uma função. `cast` chama uma função — pode aparecer como comando isolado ou dentro de uma expressão (como `gryffindor t = cast soma(a, b)`).

---

### 3.10 Expressões

```
expressao → expressao OP expressao   (operadores aritméticos e relacionais)
          | - expressao              (menos unário)
          | ( expressao )
          | int_literal | float_literal | id
          | id [ expressao ]         (acesso a vetor)
          | cast id ( argumentos )   (chamada como expressão)
```

A gramática de expressões seria ambígua sem regras de precedência. Usamos as diretivas do Bison para resolver isso:

| Operadores | Precedência | Associatividade |
|---|---|---|
| `=` | menor | direita |
| `==` `!=` | — | esquerda |
| `<` `>` `<=` `>=` | — | esquerda |
| `+` `-` | — | esquerda |
| `*` `/` | — | esquerda |
| `-` unário | maior | direita |

Com isso, `2 + 3 * 4` é interpretado como `2 + (3 * 4)` automaticamente, sem precisar criar produções separadas por nível de precedência.

---

## 4. Impressão da Árvore Sintática

A AST é construída durante a análise e impressa ao final. Cada nó armazena nome e filhos. A função `print_tree` imprime recursivamente com 8 espaços por nível.

Para evitar alocação dinâmica complexa, usamos um pool estático de 500 nós — suficiente para qualquer programa de teste:

```c
static Node pool[MAX_NODES];
```

Exemplo de saída para `gryffindor x = 5`:
```
programa
        lista_comandos
                comando
                        declaracao_variavel
                                gryffindor
                                x
                                =
                                5
```

---

## 5. Como compilar e testar

```bash
# Gerar parser e lexer
bison -d Parte2/parser.y
flex hogwarts_script.l

# Compilar
gcc lex.yy.c parser.tab.c -o parser -lfl

# Testar com um exemplo
./parser Exemplos/03_if_else_idade.hws
```

---

## 6. Referências

- Aho, Lam, Sethi, Ullman. *Compilers: Principles, Techniques, and Tools*. Addison-Wesley, 2006.
- GNU Bison Manual: https://www.gnu.org/software/bison/manual/
- Flex Manual: https://westes.github.io/flex/manual/
