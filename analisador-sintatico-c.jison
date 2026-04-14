/*
  Analisador Sintático — C Simplificado
  Implementado com Jison (LALR)
  ─────────────────────────────────────────────────────────────
  Cobre:
    - Declarações: variáveis, arrays 1D/2D (matrizes), ponteiros simples e duplos
    - Inicializadores: {1,2,3}, {{1,2},{3,4}}, "string"
    - struct / union / enum / typedef (inclui uso de alias typedef como especificador de tipo)
    - Qualificadores: const, static, extern, volatile, register
    - Definição e declaração de funções (incluindo protótipos)
    - Parâmetros: tipo, ponteiro, array, ponteiro para array (char *argv[])
    - Atribuições como expressões: =, +=, -=, *=, /=, %=, &=, |=, ^=, <<=, >>=
    - Cast de tipos: (int *)malloc(...), (struct Node *)calloc(...)
    - Alocação / desalocação: malloc, calloc, realloc, free
    - if / if-else / switch / case / default / goto
    - while / do-while / for (com declarações múltiplas e comma update)
    - return / break / continue
    - Operadores: aritméticos, comparação, lógicos, bitwise, sizeof
    - sizeof: sizeof(type), sizeof(type *), sizeof(expression)
    - Incremento/decremento: pré e pós em qualquer lvalue
    - Acesso a membro: expr.campo  e  expr->campo
    - #define / #include (caminhos com ponto e barra: sys/types.h)
*/

%lex
%%

\s+                    /* ignora espaços e quebras de linha */
\/\/[^\n]*             /* comentário de linha */
\/\*[\s\S]*?\*\/       /* comentário de bloco */

/* ── Diretivas de pré-processador ─────────────────────────── */
"#define"    return 'DEFINE';
"#include"   return 'INCLUDE';

/* ── Palavras-chave de controle de fluxo ───────────────────── */
"if"         return 'IF';
"else"       return 'ELSE';
"while"      return 'WHILE';
"do"         return 'DO';
"for"        return 'FOR';
"switch"     return 'SWITCH';
"case"       return 'CASE';
"default"    return 'DEFAULT';
"break"      return 'BREAK';
"continue"   return 'CONTINUE';
"return"     return 'RETURN';
"goto"       return 'GOTO';

/* ── Tipos primitivos ──────────────────────────────────────── */
"int"        return 'INT';
"float"      return 'FLOAT';
"char"       return 'CHAR';
"double"     return 'DOUBLE';
"long"       return 'LONG';
"short"      return 'SHORT';
"unsigned"   return 'UNSIGNED';
"signed"     return 'SIGNED';
"void"       return 'VOID';

/* ── Modificadores e tipos compostos ───────────────────────── */
"const"      return 'CONST';
"static"     return 'STATIC';
"extern"     return 'EXTERN';
"volatile"   return 'VOLATILE';
"register"   return 'REGISTER';
"sizeof"     return 'SIZEOF';
"struct"     return 'STRUCT';
"union"      return 'UNION';
"enum"       return 'ENUM';
"typedef"    return 'TYPEDEF';

/* ── Operadores compostos (mais longos primeiro) ───────────── */
"<<="        return 'LSHIFT_ASSIGN';
">>="        return 'RSHIFT_ASSIGN';
"+="         return 'ADD_ASSIGN';
"-="         return 'SUB_ASSIGN';
"*="         return 'MUL_ASSIGN';
"/="         return 'DIV_ASSIGN';
"%="         return 'MOD_ASSIGN';
"&="         return 'AND_ASSIGN';
"|="         return 'OR_ASSIGN';
"^="         return 'XOR_ASSIGN';
"++"         return 'INC';
"--"         return 'DEC';
"<<"         return 'LSHIFT';
">>"         return 'RSHIFT';
"->"         return 'ARROW';
"&&"         return 'AND';
"||"         return 'OR';
"=="         return 'EQ';
"!="         return 'NEQ';
"<="         return 'LE';
">="         return 'GE';

/* ── Operadores simples ────────────────────────────────────── */
"+"          return '+';
"-"          return '-';
"*"          return '*';
"/"          return '/';
"%"          return '%';
"<"          return 'LT';
">"          return 'GT';
"!"          return 'NOT';
"="          return '=';
"&"          return '&';
"|"          return '|';
"^"          return '^';
"~"          return '~';
","          return ',';
";"          return ';';
":"          return ':';
"("          return '(';
")"          return ')';
"["          return '[';
"]"          return ']';
"{"          return '{';
"}"          return '}';
"."          return '.';

/* ── Literais ──────────────────────────────────────────────── */
0[xX][0-9a-fA-F]+   return 'NUMBER';
[0-9]+(\.[0-9]+)?   return 'NUMBER';
\"[^\"]*\"          return 'STRING';
\'[^\']*\'          return 'CHAR_LIT';

[a-zA-Z_][a-zA-Z0-9_]*   return 'ID';

<<EOF>>      return 'EOF';
.            return 'INVALID';

/lex

/*
──────────────────────────────────────────────────────────────
  Precedência e associatividade (do MENOR para o MAIOR)
────────────────────────────────────────────────────────────── 
*/
%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN AND_ASSIGN OR_ASSIGN XOR_ASSIGN LSHIFT_ASSIGN RSHIFT_ASSIGN
%left  OR
%left  AND
%left  '|'
%left  '^'
%left  '&'
%left  EQ NEQ
%left  LT GT LE GE
%left  LSHIFT RSHIFT
%left  '+' '-'
%left  '*' '/' '%'
%right NOT '~' UMINUS DEREF ADDR
%left  INC DEC ARROW '.' '['

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%start program

%%

/*
══════════════════════════════════════════════════════════════
  REGRA RAIZ
══════════════════════════════════════════════════════════════
*/

program
  : statement_list EOF
    { console.log("Programa reconhecido com sucesso!"); return $1; }
  ;

statement_list
  : /* vazio */
    { $$ = []; }
  | statement_list statement
    { $$ = $1.concat([$2]); }
  ;

statement
  : declaration
    { console.log("Declaração encontrada");              $$ = $1; }
  | struct_definition
    { console.log("Definição de struct encontrada");     $$ = $1; }
  | union_definition
    { console.log("Definição de union encontrada");      $$ = $1; }
  | enum_definition
    { console.log("Definição de enum encontrada");       $$ = $1; }
  | typedef_declaration
    { console.log("Typedef encontrado");                 $$ = $1; }
  | function_definition
    { console.log("Definição de função encontrada");     $$ = $1; }
  | if_statement
    { console.log("Entrou em estrutura IF");             $$ = $1; }
  | switch_statement
    { console.log("Entrou em estrutura SWITCH");         $$ = $1; }
  | while_statement
    { console.log("Loop WHILE identificado");            $$ = $1; }
  | do_while_statement
    { console.log("Loop DO-WHILE identificado");         $$ = $1; }
  | for_statement
    { console.log("Loop FOR identificado");              $$ = $1; }
  | return_statement
    { console.log("  Return encontrado");                $$ = $1; }
  | break_statement
    { console.log("  Break encontrado");                 $$ = $1; }
  | continue_statement
    { console.log("  Continue encontrado");              $$ = $1; }
  | goto_statement
    { console.log("  Goto encontrado");                  $$ = $1; }
  | label_statement
    { console.log("  Label encontrado");                 $$ = $1; }
  | preprocessor_directive
    { console.log("  Diretiva de pré-processador");      $$ = $1; }
  | expression ';'
    { console.log("  Expressão como instrução");         $$ = $1; }
  | block
    { console.log("Bloco de código");                    $$ = $1; }
  ;

/*
══════════════════════════════════════════════════════════════
  TIPOS
══════════════════════════════════════════════════════════════
*/

type
  : INT                    { $$ = "int"; }
  | FLOAT                  { $$ = "float"; }
  | CHAR                   { $$ = "char"; }
  | DOUBLE                 { $$ = "double"; }
  | LONG                   { $$ = "long"; }
  | LONG INT               { $$ = "long int"; }
  | LONG LONG              { $$ = "long long"; }
  | LONG LONG INT          { $$ = "long long int"; }
  | SHORT                  { $$ = "short"; }
  | SHORT INT              { $$ = "short int"; }
  | VOID                   { $$ = "void"; }
  | UNSIGNED               { $$ = "unsigned"; }
  | UNSIGNED INT           { $$ = "unsigned int"; }
  | UNSIGNED CHAR          { $$ = "unsigned char"; }
  | UNSIGNED SHORT         { $$ = "unsigned short"; }
  | UNSIGNED SHORT INT     { $$ = "unsigned short int"; }
  | UNSIGNED LONG          { $$ = "unsigned long"; }
  | UNSIGNED LONG INT      { $$ = "unsigned long int"; }
  | UNSIGNED LONG LONG     { $$ = "unsigned long long"; }
  | UNSIGNED LONG LONG INT { $$ = "unsigned long long int"; }
  | SIGNED                 { $$ = "signed"; }
  | SIGNED INT             { $$ = "signed int"; }
  | SIGNED CHAR            { $$ = "signed char"; }
  | SIGNED SHORT           { $$ = "signed short"; }
  | SIGNED SHORT INT       { $$ = "signed short int"; }
  | SIGNED LONG            { $$ = "signed long"; }
  | SIGNED LONG INT        { $$ = "signed long int"; }
  | SIGNED LONG LONG       { $$ = "signed long long"; }
  | SIGNED LONG LONG INT   { $$ = "signed long long int"; }
  | LONG DOUBLE            { $$ = "long double"; }
  | CONST type             { $$ = "const " + $2; }
  | STATIC type            { $$ = "static " + $2; }
  | EXTERN type            { $$ = "extern " + $2; }
  | VOLATILE type          { $$ = "volatile " + $2; }
  | REGISTER type          { $$ = "register " + $2; }
  | STRUCT ID              { $$ = "struct " + $2; }
  | UNION  ID              { $$ = "union "  + $2; }
  | ENUM   ID              { $$ = "enum "   + $2; }
  ;

/*
══════════════════════════════════════════════════════════════
  DECLARAÇÕES DE VARIÁVEIS
══════════════════════════════════════════════════════════════
*/

declaration
  : type declarator_list ';'
    { console.log("  → Declaração: tipo=" + $1);
      $$ = { type: 'declaration', varType: $1, declarators: $2 }; }
  | ID declarator_list ';'
    { console.log("  → Declaração (typedef): tipo=" + $1);
      $$ = { type: 'declaration', varType: $1, declarators: $2 }; }
  ;

declarator_list
  : declarator
    { $$ = [$1]; }
  | declarator_list ',' declarator
    { $$ = $1.concat([$3]); }
  ;

declarator
  : ID
    { console.log("    → Variável: " + $1);
      $$ = { type: 'variable', name: $1, init: null }; }
  | ID '=' expression
    { console.log("    → Variável com init: " + $1);
      $$ = { type: 'variable', name: $1, init: $3 }; }
  
  | ID '=' '{' initializer_list '}'
    { console.log("    → Variável com init (chaves): " + $1);
      $$ = { type: 'variable', name: $1, init: { type: 'init_list', values: $4 } }; }

  | '*' ID
    { console.log("    → Ponteiro: *" + $2);
      $$ = { type: 'pointer', name: $2, init: null }; }
  | '*' ID '=' expression
    { console.log("    → Ponteiro com init: *" + $2);
      $$ = { type: 'pointer', name: $2, init: $4 }; }
  | '*' ID '=' '{' initializer_list '}'
    { console.log("    → Ponteiro com init (chaves): *" + $2);
      $$ = { type: 'pointer', name: $2, init: { type: 'init_list', values: $5 } }; }

  | '*' '*' ID
    { console.log("    → Ponteiro duplo: **" + $3);
      $$ = { type: 'double_pointer', name: $3, init: null }; }
  | '*' '*' ID '=' expression
    { console.log("    → Ponteiro duplo com init: **" + $3);
      $$ = { type: 'double_pointer', name: $3, init: $5 }; }
  | '*' '*' ID '=' '{' initializer_list '}'
    { console.log("    → Ponteiro duplo com init (chaves): **" + $3);
      $$ = { type: 'double_pointer', name: $3, init: { type: 'init_list', values: $6 } }; }

  | ID '[' expression ']'
    { console.log("    → Array: " + $1 + "[...]");
      $$ = { type: 'array', name: $1, size: $3, init: null }; }
  | ID '[' ']'
    { console.log("    → Array sem tamanho: " + $1 + "[]");
      $$ = { type: 'array', name: $1, size: null, init: null }; }
  | ID '[' ']' '=' '{' initializer_list '}'
    { console.log("    → Array com init (braces): " + $1 + "[] = {...}");
      $$ = { type: 'array', name: $1, size: null, init: $6 }; }
  | ID '[' ']' '=' expression
    { console.log("    → Array com init (expr): " + $1 + "[] = expr");
      $$ = { type: 'array', name: $1, size: null, init: $5 }; }
  | ID '[' expression ']' '=' '{' initializer_list '}'
    { console.log("    → Array com tamanho e init (braces): " + $1 + "[...] = {...}");
      $$ = { type: 'array', name: $1, size: $3, init: $7 }; }
  | ID '[' expression ']' '=' expression
    { console.log("    → Array com tamanho e init (expr): " + $1 + "[...] = expr");
      $$ = { type: 'array', name: $1, size: $3, init: $6 }; }

  | ID '[' expression ']' '[' expression ']'
    { console.log("    → Matriz: " + $1 + "[...][...]");
      $$ = { type: 'matrix', name: $1, rows: $3, cols: $6, init: null }; }
  | ID '[' expression ']' '[' expression ']' '=' '{' initializer_list '}'
    { console.log("    → Matriz com init: " + $1 + "[...][...] = {...}");
      $$ = { type: 'matrix', name: $1, rows: $3, cols: $6, init: $10 }; }
  | ID '[' ']' '[' expression ']'
    { console.log("    → Matriz (parâmetro): " + $1 + "[][...]");
      $$ = { type: 'matrix', name: $1, rows: null, cols: $5, init: null }; }
  ;

initializer_list
  : initializer
    { $$ = [$1]; }
  | initializer_list ',' initializer
    { $$ = $1.concat([$3]); }
  ;

initializer
  : expression
    { $$ = $1; }
  | '{' initializer_list '}'
    { $$ = { type: 'init_list', values: $2 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  FUNÇÕES
══════════════════════════════════════════════════════════════
*/

param_list
  : /* vazio */               { $$ = []; }
  | param                     { $$ = [$1]; }
  | param_list ',' param      { $$ = $1.concat([$3]); }
  ;

param
  : type ID
    { $$ = { paramType: $1, name: $2 }; }
  | type '*' ID
    { $$ = { paramType: $1 + '*', name: $3 }; }
  | type '*' '*' ID
    { $$ = { paramType: $1 + '**', name: $4 }; }
  | type ID '[' ']'
    { $$ = { paramType: $1 + '[]', name: $2 }; }
  | type ID '[' ']' '[' expression ']'
    { $$ = { paramType: $1 + '[][]', name: $2 }; }
  | type '*' ID '[' ']'
    { $$ = { paramType: $1 + '*[]', name: $3 }; }
  ;

function_definition
  : type ID '(' VOID ')' block
    { console.log("  → Função (void): " + $2 + "()");
      $$ = { type: 'function', returnType: $1, name: $2, params: [], body: $6 }; }
  | type '*' ID '(' VOID ')' block
    { console.log("  → Função ptr (void): " + $3 + "()");
      $$ = { type: 'function', returnType: $1 + '*', name: $3, params: [], body: $7 }; }
  | type ID '(' VOID ')' ';'
    { console.log("  → Protótipo (void): " + $2 + "()");
      $$ = { type: 'prototype', returnType: $1, name: $2, params: [] }; }
  | type '*' ID '(' VOID ')' ';'
    { console.log("  → Protótipo ptr (void): " + $3 + "()");
      $$ = { type: 'prototype', returnType: $1 + '*', name: $3, params: [] }; }
  | type ID '(' param_list ')' block
    { console.log("  → Função: " + $2 + "()");
      $$ = { type: 'function', returnType: $1, name: $2, params: $4, body: $6 }; }
  | type '*' ID '(' param_list ')' block
    { console.log("  → Função (retorna ponteiro): " + $3 + "()");
      $$ = { type: 'function', returnType: $1 + '*', name: $3, params: $5, body: $7 }; }
  | type ID '(' param_list ')' ';'
    { console.log("  → Protótipo: " + $2 + "()");
      $$ = { type: 'prototype', returnType: $1, name: $2, params: $4 }; }
  | type '*' ID '(' param_list ')' ';'
    { console.log("  → Protótipo (ponteiro): " + $3 + "()");
      $$ = { type: 'prototype', returnType: $1 + '*', name: $3, params: $5 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  STRUCT
══════════════════════════════════════════════════════════════
*/

struct_definition
  : STRUCT ID '{' struct_member_list '}' ';'
    { console.log("  → Struct definida: struct " + $2);
      $$ = { type: 'struct_def', name: $2, members: $4 }; }
  | STRUCT ID ID "=" '{' struct_member_values '}' ';'
    { console.log("  → Struct definida: struct " + $2);
      $$ = { type: 'struct_def', name: $2, members: $4 }; }
  | STRUCT ID '{' struct_member_list '}' declarator_list ';'
    { console.log("  → Struct com variável: struct " + $2);
      $$ = { type: 'struct_def', name: $2, members: $4, vars: $6 }; }
  | STRUCT '{' struct_member_list '}' declarator_list ';'
    { console.log("  → Struct anônima com variável");
      $$ = { type: 'struct_def', name: null, members: $3, vars: $5 }; }
  ;

struct_member_values
: struct_member_v
    { $$ = [$1]; }
  | struct_member_values "," struct_member_v
    { $$ = $1.concat([$2]); }
;

struct_member_v
: NUMBER
  { $$ = { name: $1, value: null }; }
| STRING
  { $$ = { name: $1, value: null }; }
;

/*
══════════════════════════════════════════════════════════════
  UNION
══════════════════════════════════════════════════════════════
*/

union_definition
  : UNION ID '{' struct_member_list '}' ';'
    { console.log("  → Union definida: union " + $2);
      $$ = { type: 'union_def', name: $2, members: $4 }; }
  | UNION ID '{' struct_member_list '}' declarator_list ';'
    { console.log("  → Union com variável: union " + $2);
      $$ = { type: 'union_def', name: $2, members: $4, vars: $6 }; }
  | UNION '{' struct_member_list '}' declarator_list ';'
    { console.log("  → Union anônima com variável");
      $$ = { type: 'union_def', name: null, members: $3, vars: $5 }; }
  ;

struct_member_list
  : /* vazio */
    { $$ = []; }
  | struct_member_list struct_member
    { $$ = $1.concat([$2]); }
  ;

struct_member
  : type declarator_list ';'
    { $$ = { type: 'member', varType: $1, declarators: $2 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  ENUM
══════════════════════════════════════════════════════════════
*/

enum_definition
  : ENUM ID '{' enum_member_list '}' ';'
    { console.log("  → Enum definida: enum " + $2);
      $$ = { type: 'enum_def', name: $2, members: $4 }; }
  | ENUM ID '{' enum_member_list '}' declarator_list ';'
    { console.log("  → Enum com variável: enum " + $2);
      $$ = { type: 'enum_def', name: $2, members: $4, vars: $6 }; }
  | ENUM '{' enum_member_list '}' ';'
    { console.log("  → Enum anônima");
      $$ = { type: 'enum_def', name: null, members: $3 }; }
  | ENUM '{' enum_member_list '}' declarator_list ';'
    { console.log("  → Enum anônima com variável");
      $$ = { type: 'enum_def', name: null, members: $3, vars: $5 }; }
  ;

enum_member_list
  : enum_member
    { $$ = [$1]; }
  | enum_member_list ',' enum_member
    { $$ = $1.concat([$3]); }
  | enum_member_list ','
    { $$ = $1; }
  ;

enum_member
  : ID
    { $$ = { name: $1, value: null }; }
  | ID '=' expression
    { $$ = { name: $1, value: $3 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  TYPEDEF
══════════════════════════════════════════════════════════════
*/

typedef_declaration
  : TYPEDEF type ID ';'
    { console.log("  → Typedef simples: " + $3);
      $$ = { type: 'typedef', base: $2, alias: $3 }; }
  | TYPEDEF type '*' ID ';'
    { console.log("  → Typedef ponteiro: " + $4);
      $$ = { type: 'typedef', base: $2 + '*', alias: $4 }; }
  | TYPEDEF STRUCT '{' struct_member_list '}' ID ';'
    { console.log("  → Typedef struct anônima: " + $6);
      $$ = { type: 'typedef_struct', name: null, members: $4, alias: $6 }; }
  | TYPEDEF STRUCT ID '{' struct_member_list '}' ID ';'
    { console.log("  → Typedef struct: " + $7);
      $$ = { type: 'typedef_struct', name: $3, members: $5, alias: $7 }; }
  | TYPEDEF UNION '{' struct_member_list '}' ID ';'
    { console.log("  → Typedef union anônima: " + $6);
      $$ = { type: 'typedef_union', name: null, members: $4, alias: $6 }; }
  | TYPEDEF ENUM '{' enum_member_list '}' ID ';'
    { console.log("  → Typedef enum anônima: " + $6);
      $$ = { type: 'typedef_enum', name: null, members: $4, alias: $6 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  ESTRUTURAS CONDICIONAIS
══════════════════════════════════════════════════════════════
*/

if_statement
  : IF '(' expression ')' statement %prec LOWER_THAN_ELSE
    { console.log("Entrou em estrutura IF");
      $$ = { type: 'if', condition: $3, then: $5 }; }
  | IF '(' expression ')' statement ELSE statement
    { console.log("Entrou em estrutura IF-ELSE");
      $$ = { type: 'if_else', condition: $3, then: $5, else: $7 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  SWITCH / CASE / DEFAULT
══════════════════════════════════════════════════════════════
*/

switch_statement
  : SWITCH '(' expression ')' '{' case_list '}'
    { console.log("Estrutura SWITCH reconhecida");
      $$ = { type: 'switch', condition: $3, cases: $6 }; }
  ;

case_list
  : /* vazio */
    { $$ = []; }
  | case_list case_clause
    { $$ = $1.concat([$2]); }
  ;

case_clause
  : CASE expression ':' statement_list
    { console.log("  → case");
      $$ = { type: 'case', value: $2, body: $4 }; }
  | DEFAULT ':' statement_list
    { console.log("  → default");
      $$ = { type: 'default', body: $3 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  ESTRUTURAS DE REPETIÇÃO
══════════════════════════════════════════════════════════════
*/

while_statement
  : WHILE '(' expression ')' statement
    { console.log("Loop WHILE identificado");
      $$ = { type: 'while', condition: $3, body: $5 }; }
  ;

do_while_statement
  : DO statement WHILE '(' expression ')' ';'
    { console.log("Loop DO-WHILE identificado");
      $$ = { type: 'do_while', body: $2, condition: $5 }; }
  ;

for_statement
  : FOR '(' for_init ';' for_cond ';' for_update ')' statement
    { console.log("Loop FOR identificado");
      $$ = { type: 'for', init: $3, condition: $5, update: $7, body: $9 }; }
  ;

for_init
  : /* vazio */
    { $$ = null; }
  | type declarator_list
    { console.log("    → For init: declaração");
      $$ = { type: 'declaration', varType: $1, declarators: $2 }; }
  | for_expression_list
    { $$ = $1; }
  ;

for_cond
  : /* vazio */    { $$ = null; }
  | expression     { $$ = $1; }
  ;

for_update
  : /* vazio */
    { $$ = null; }
  | for_expression_list
    { $$ = $1; }
  ;

for_expression_list
  : expression
    { $$ = $1; }
  | for_expression_list ',' expression
    { $$ = { type: 'comma', left: $1, right: $3 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  COMANDOS DE CONTROLE
══════════════════════════════════════════════════════════════
*/

return_statement
  : RETURN ';'
    { console.log("  → Return sem valor");
      $$ = { type: 'return', value: null }; }
  | RETURN expression ';'
    { console.log("  → Return com valor");
      $$ = { type: 'return', value: $2 }; }
  ;

break_statement
  : BREAK ';'
    { console.log("  → Break"); $$ = { type: 'break' }; }
  ;

continue_statement
  : CONTINUE ';'
    { console.log("  → Continue"); $$ = { type: 'continue' }; }
  ;

goto_statement
  : GOTO ID ';'
    { console.log("  → Goto: " + $2); $$ = { type: 'goto', label: $2 }; }
  ;

label_statement
  : ID ':' statement
    { console.log("  → Label: " + $1); $$ = { type: 'label', name: $1, body: $3 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  DIRETIVAS DE PRÉ-PROCESSADOR
══════════════════════════════════════════════════════════════
*/

preprocessor_directive
  : DEFINE ID expression
    { console.log("  → #define: " + $2);
      $$ = { type: 'define', name: $2, value: $3 }; }
  | DEFINE ID
    { console.log("  → #define flag: " + $2);
      $$ = { type: 'define', name: $2, value: null }; }
  | INCLUDE LT include_path GT
    { console.log("  → #include sistema: <" + $3 + ">");
      $$ = { type: 'include', file: $3, system: true }; }
  | INCLUDE STRING
    { console.log("  → #include local: " + $2);
      $$ = { type: 'include', file: $2, system: false }; }
  ;

include_path
  : ID
    { $$ = $1; }
  | include_path '.' ID
    { $$ = $1 + '.' + $3; }
  | include_path '/' ID
    { $$ = $1 + '/' + $3; }
  ;

/*
══════════════════════════════════════════════════════════════
  EXPRESSÕES
══════════════════════════════════════════════════════════════
*/

arg_list
  : /* vazio */               { $$ = []; }
  | expression                { $$ = [$1]; }
  | arg_list ',' expression   { $$ = $1.concat([$3]); }
  ;

expression
  : NUMBER
    { $$ = { type: 'number', value: $1 }; }
  | STRING
    { $$ = { type: 'string', value: $1 }; }
  | CHAR_LIT
    { $$ = { type: 'char', value: $1 }; }
  | ID
    { $$ = { type: 'id', name: $1 }; }

  | ID '(' arg_list ')'
    { console.log("    → Chamada de função: " + $1 + "()");
      $$ = { type: 'call', name: $1, args: $3 }; }

  | expression '[' expression ']'
    { console.log("    → Índice de array/matriz");
      $$ = { type: 'index', array: $1, index: $3 }; }

  | expression '.' ID
    { console.log("    → Acesso a membro: ." + $3);
      $$ = { type: 'member', object: $1, member: $3 }; }
  | expression ARROW ID
    { console.log("    → Acesso via ponteiro: ->" + $3);
      $$ = { type: 'arrow', object: $1, member: $3 }; }

  | '(' type ')' expression         %prec UMINUS
    { console.log("    → Cast: (" + $2 + ")");
      $$ = { type: 'cast', castType: $2, expr: $4 }; }
  | '(' type '*' ')' expression     %prec UMINUS
    { console.log("    → Cast ponteiro: (" + $2 + "*)");
      $$ = { type: 'cast', castType: $2 + '*', expr: $5 }; }
  | '(' type '*' '*' ')' expression %prec UMINUS
    { console.log("    → Cast ponteiro duplo: (" + $2 + "**)");
      $$ = { type: 'cast', castType: $2 + '**', expr: $6 }; }

  | expression '+' expression   { $$ = { type: '+', left: $1, right: $3 }; }
  | expression '-' expression   { $$ = { type: '-', left: $1, right: $3 }; }
  | expression '*' expression   { $$ = { type: '*', left: $1, right: $3 }; }
  | expression '/' expression   { $$ = { type: '/', left: $1, right: $3 }; }
  | expression '%' expression   { $$ = { type: '%', left: $1, right: $3 }; }

  | expression LSHIFT expression  { $$ = { type: '<<', left: $1, right: $3 }; }
  | expression RSHIFT expression  { $$ = { type: '>>', left: $1, right: $3 }; }
  | expression '|' expression     { $$ = { type: '|',  left: $1, right: $3 }; }
  | expression '^' expression     { $$ = { type: '^',  left: $1, right: $3 }; }
  | expression '&' expression     { $$ = { type: '&',  left: $1, right: $3 }; }

  | expression EQ  expression
    { console.log("    → Operador =="); $$ = { type: '==', left: $1, right: $3 }; }
  | expression NEQ expression
    { console.log("    → Operador !="); $$ = { type: '!=', left: $1, right: $3 }; }
  | expression LT  expression
    { console.log("    → Operador <");  $$ = { type: '<',  left: $1, right: $3 }; }
  | expression GT  expression
    { console.log("    → Operador >");  $$ = { type: '>',  left: $1, right: $3 }; }
  | expression LE  expression
    { console.log("    → Operador <="); $$ = { type: '<=', left: $1, right: $3 }; }
  | expression GE  expression
    { console.log("    → Operador >="); $$ = { type: '>=', left: $1, right: $3 }; }

  | expression AND expression
    { console.log("    → Operador &&"); $$ = { type: '&&', left: $1, right: $3 }; }
  | expression OR  expression
    { console.log("    → Operador ||"); $$ = { type: '||', left: $1, right: $3 }; }
  | NOT expression
    { $$ = { type: '!', expr: $2 }; }

  | '-' expression %prec UMINUS
    { $$ = { type: 'neg', expr: $2 }; }
  | '~' expression
    { $$ = { type: '~', expr: $2 }; }
  | '(' expression ')'
    { $$ = $2; }

  | expression INC  %prec INC
    { console.log("    → Pós-incremento"); $$ = { type: 'post++', expr: $1 }; }
  | expression DEC  %prec DEC
    { console.log("    → Pós-decremento"); $$ = { type: 'post--', expr: $1 }; }
  | INC expression
    { console.log("    → Pré-incremento"); $$ = { type: 'pre++', expr: $2 }; }
  | DEC expression
    { console.log("    → Pré-decremento"); $$ = { type: 'pre--', expr: $2 }; }

  | '&' expression  %prec ADDR
    { console.log("    → Endereço de"); $$ = { type: 'address_of', expr: $2 }; }
  | '*' expression  %prec DEREF
    { console.log("    → Derreferência"); $$ = { type: 'deref', expr: $2 }; }

  | expression '='             expression
    { console.log("    → Atribuição =");   $$ = { type: '=',   left: $1, right: $3 }; }
  | expression ADD_ASSIGN      expression
    { console.log("    → Atribuição +=");  $$ = { type: '+=',  left: $1, right: $3 }; }
  | expression SUB_ASSIGN      expression
    { console.log("    → Atribuição -=");  $$ = { type: '-=',  left: $1, right: $3 }; }
  | expression MUL_ASSIGN      expression
    { console.log("    → Atribuição *=");  $$ = { type: '*=',  left: $1, right: $3 }; }
  | expression DIV_ASSIGN      expression
    { console.log("    → Atribuição /=");  $$ = { type: '/=',  left: $1, right: $3 }; }
  | expression MOD_ASSIGN      expression
    { console.log("    → Atribuição %=");  $$ = { type: '%=',  left: $1, right: $3 }; }
  | expression AND_ASSIGN      expression
    { console.log("    → Atribuição &=");  $$ = { type: '&=',  left: $1, right: $3 }; }
  | expression OR_ASSIGN       expression
    { console.log("    → Atribuição |=");  $$ = { type: '|=',  left: $1, right: $3 }; }
  | expression XOR_ASSIGN      expression
    { console.log("    → Atribuição ^=");  $$ = { type: '^=',  left: $1, right: $3 }; }
  | expression LSHIFT_ASSIGN   expression
    { console.log("    → Atribuição <<="); $$ = { type: '<<=', left: $1, right: $3 }; }
  | expression RSHIFT_ASSIGN   expression
    { console.log("    → Atribuição >>="); $$ = { type: '>>=', left: $1, right: $3 }; }

  | SIZEOF '(' type ')'
    { console.log("    → sizeof tipo: " + $3); $$ = { type: 'sizeof', arg: $3 }; }
  | SIZEOF '(' type '*' ')'
    { console.log("    → sizeof tipo*: " + $3 + "*"); $$ = { type: 'sizeof', arg: $3 + '*' }; }
  | SIZEOF '(' expression ')'
    { console.log("    → sizeof expressão"); $$ = { type: 'sizeof_expr', arg: $3 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  BLOCO
══════════════════════════════════════════════════════════════
*/

block
  : '{' statement_list '}'
    { $$ = { type: 'block', body: $2 }; }
  ;
