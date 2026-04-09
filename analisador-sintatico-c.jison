/*
  Analisador Sintático — C Simplificado
  Implementado com Jison (LALR)
  ─────────────────────────────────────────────────────────────
  Cobre:
    - Declarações de variáveis e arrays
    - Definição e declaração de funções
    - Atribuições simples e compostas (+=, -=, *=, /=)
    - Alocação (malloc) e desalocação (free) via chamada de função
    - if / if-else
    - while / do-while / for
    - return / break / continue
    - Operadores de comparação e lógicos (via expressão)
    - #define / #include
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

/* ── Modificadores ─────────────────────────────────────────── */
"const"      return 'CONST';
"static"     return 'STATIC';
"extern"     return 'EXTERN';
"volatile"   return 'VOLATILE';
"sizeof"     return 'SIZEOF';
"struct"     return 'STRUCT';
"typedef"    return 'TYPEDEF';

/* ── Operadores compostos (mais longos primeiro) ───────────── */
"<<="        return 'LSHIFT_ASSIGN';
">>="        return 'RSHIFT_ASSIGN';
"+="         return 'ADD_ASSIGN';
"-="         return 'SUB_ASSIGN';
"*="         return 'MUL_ASSIGN';
"/="         return 'DIV_ASSIGN';
"%="         return 'MOD_ASSIGN';
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
"("          return '(';
")"          return ')';
"["          return '[';
"]"          return ']';
"{"          return '{';
"}"          return '}';

/* ── Literais ──────────────────────────────────────────────── */
[0-9]+(\.[0-9]+)?    return 'NUMBER';
\"[^\"]*\"           return 'STRING';
\'[^\']*\'           return 'CHAR_LIT';

/* ID: aceita ponto para suportar nomes de arquivo (stdio.h) */
[a-zA-Z_][a-zA-Z0-9_.]*   return 'ID';

<<EOF>>      return 'EOF';
.            return 'INVALID';

/lex

/* ──────────────────────────────────────────────────────────────
  Precedência e associatividade (do MENOR para o MAIOR)
  Resolve conflitos shift/reduce em expressões
  ────────────────────────────────────────────────────────────── */
%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
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
%right NOT '~' UMINUS
%left  INC DEC ARROW

/* Resolve o clássico conflito do "else suspenso" (dangling else) */
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
    { console.log("Declaração encontrada");            $$ = $1; }
  | function_definition
    { console.log("Definição de função encontrada");   $$ = $1; }
  | assignment_stmt
    { console.log("Reconhecida atribuição");              $$ = $1; }
  | if_statement
    { console.log("Entrou em estrutura IF");              $$ = $1; }
  | while_statement
    { console.log("Loop WHILE identificado");             $$ = $1; }
  | do_while_statement
    { console.log("Loop DO-WHILE identificado");          $$ = $1; }
  | for_statement
    { console.log("Loop FOR identificado");               $$ = $1; }
  | return_statement
    { console.log("  Return encontrado");               $$ = $1; }
  | break_statement
    { console.log("  Break encontrado");                  $$ = $1; }
  | continue_statement
    { console.log("  Continue encontrado");             $$ = $1; }
  | preprocessor_directive
    { console.log("  Diretiva de pré-processador");      $$ = $1; }
  | expression ';'
    { console.log("  Expressão como instrução");         $$ = $1; }
  | block
    { console.log("Bloco de código");                  $$ = $1; }
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
  | LONG                   { $$ = "long"; }                    // long int
  | LONG INT               { $$ = "long int"; }
  | LONG LONG              { $$ = "long long"; }              // long long int
  | LONG LONG INT          { $$ = "long long int"; }
  | SHORT                  { $$ = "short"; }                  // short int
  | SHORT INT              { $$ = "short int"; }
  | VOID                   { $$ = "void"; }
  | UNSIGNED               { $$ = "unsigned"; }               // unsigned int
  | UNSIGNED INT           { $$ = "unsigned int"; }
  | UNSIGNED CHAR          { $$ = "unsigned char"; }
  | UNSIGNED SHORT         { $$ = "unsigned short"; }         // unsigned short int
  | UNSIGNED SHORT INT     { $$ = "unsigned short int"; }
  | UNSIGNED LONG          { $$ = "unsigned long"; }          // unsigned long int
  | UNSIGNED LONG INT      { $$ = "unsigned long int"; }
  | UNSIGNED LONG LONG     { $$ = "unsigned long long"; }     // unsigned long long int
  | UNSIGNED LONG LONG INT { $$ = "unsigned long long int"; }
  | SIGNED                 { $$ = "signed"; }                 // signed int
  | SIGNED INT             { $$ = "signed int"; }
  | SIGNED CHAR            { $$ = "signed char"; }
  | SIGNED SHORT           { $$ = "signed short"; }           // signed short int
  | SIGNED SHORT INT       { $$ = "signed short int"; }
  | SIGNED LONG            { $$ = "signed long"; }            // signed long int
  | SIGNED LONG INT        { $$ = "signed long int"; }
  | SIGNED LONG LONG       { $$ = "signed long long"; }       // signed long long int
  | SIGNED LONG LONG INT   { $$ = "signed long long int"; }
  | LONG DOUBLE            { $$ = "long double"; }
  | CONST type             { $$ = "const " + $2; }
  ;

/* 
══════════════════════════════════════════════════════════════
  DECLARAÇÕES DE VARIÁVEIS
══════════════════════════════════════════════════════════════ 
*/

declaration
  : type declarator_list ';'
    { console.log("  → Declaração múltipla");
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
      $$ = { type: 'variable', name: $1, init: null, size: null }; }
  | ID '=' expression
    { console.log("    → Variável com inicialização: " + $1);
      $$ = { type: 'variable', name: $1, init: $3, size: null }; }
  | '*' ID
    { console.log("    → Ponteiro: *" + $2);
      $$ = { type: 'pointer', name: $2, init: null, size: null }; }
  | '*' ID '=' expression
    { console.log("    → Ponteiro com inicialização: *" + $2);
      $$ = { type: 'pointer', name: $2, init: $4, size: null }; }
  | ID '[' expression ']'
    { console.log("    → Array: " + $1 + "[...]");
      $$ = { type: 'array', name: $1, size: $3, init: null }; }
  | ID '[' ']'
    { console.log("    → Array sem tamanho: " + $1 + "[]");
      $$ = { type: 'array', name: $1, size: null, init: null }; }
  | ID '[' ']' '=' '{' initializer_list '}'
    { console.log("    → Array sem tamanho com inicialização: " + $1 + "[] = {...}");
      $$ = { type: 'array', name: $1, size: null, init: $6 }; }
  | ID '[' expression ']' '=' '{' initializer_list '}'
    { console.log("    → Array com tamanho e inicialização: " + $1 + "[...] = {...}");
      $$ = { type: 'array', name: $1, size: $3, init: $7 }; }
  ;

initializer_list
  : expression
    { $$ = [$1]; }
  | initializer_list ',' expression
    { $$ = $1.concat([$3]); }
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
  : type ID                   { $$ = { paramType: $1, name: $2 }; }
  | type '*' ID               { $$ = { paramType: $1 + '*', name: $3 }; }
  | type ID '[' ']'           { $$ = { paramType: $1 + '[]', name: $2 }; }
  | VOID                      { $$ = { paramType: 'void', name: '' }; }
  ;

function_definition
  : type ID '(' param_list ')' block
    { console.log("  → Função definida: " + $2 + "()");
      $$ = { type: 'function', returnType: $1, name: $2, params: $4, body: $6 }; }

  | type '*' ID '(' param_list ')' block
    { console.log("  → Função definida (retorna ponteiro): " + $3 + "()");
      $$ = { type: 'function', returnType: $1 + '*', name: $3, params: $5, body: $7 }; }
  ;

/* 
══════════════════════════════════════════════════════════════
  ATRIBUIÇÕES
  Obs.: malloc() e free() são cobertos pela regra
    expression → ID '(' arg_list ')'  (chamada de função)
══════════════════════════════════════════════════════════════ 
*/

assignment_stmt
  : ID '=' expression ';'
    { console.log("  → Atribuição: " + $1 + " = ...");
      $$ = { type: 'assignment', target: $1, op: '=', value: $3 }; }

  | ID '[' expression ']' '=' expression ';'
    { console.log("  → Atribuição em array: " + $1 + "[...]");
      $$ = { type: 'array_assign', array: $1, index: $3, value: $6 }; }

  | '*' ID '=' expression ';'
    { console.log("  → Atribuição via derreferência: *" + $2);
      $$ = { type: 'deref_assign', ptr: $2, value: $4 }; }

  | ID ADD_ASSIGN expression ';'
    { console.log("  → Atribuição composta +=: " + $1);
      $$ = { type: 'assignment', target: $1, op: '+=', value: $3 }; }

  | ID SUB_ASSIGN expression ';'
    { console.log("  → Atribuição composta -=: " + $1);
      $$ = { type: 'assignment', target: $1, op: '-=', value: $3 }; }

  | ID MUL_ASSIGN expression ';'
    { console.log("  → Atribuição composta *=: " + $1);
      $$ = { type: 'assignment', target: $1, op: '*=', value: $3 }; }

  | ID DIV_ASSIGN expression ';'
    { console.log("  → Atribuição composta /=: " + $1);
      $$ = { type: 'assignment', target: $1, op: '/=', value: $3 }; }
  ;

/* 
══════════════════════════════════════════════════════════════
  ESTRUTURAS CONDICIONAIS
  %prec LOWER_THAN_ELSE resolve o "dangling else"
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

/*
  for_init NÃO inclui o ';' final — ele é separador explícito
  na regra for_statement acima.
*/
for_init
  : /* vazio */
    { $$ = null; }
  | type ID
    { console.log("    → For: declaração de variável");
      $$ = { type: 'declaration', varType: $1, name: $2 }; }
  | type ID '=' expression
    { console.log("    → For: declaração com inicialização");
      $$ = { type: 'declaration', varType: $1, name: $2, init: $4 }; }
  | ID '=' expression
    { console.log("    → For: atribuição inicial");
      $$ = { type: 'assignment', target: $1, op: '=', value: $3 }; }
  | expression
    { $$ = $1; }
  ;

for_cond
  : /* vazio */    { $$ = null; }
  | expression     { $$ = $1; }
  ;

for_update
  : /* vazio */
    { $$ = null; }
  | ID '=' expression
    { $$ = { type: 'assignment', target: $1, op: '=', value: $3 }; }
  | ID ADD_ASSIGN expression
    { $$ = { type: 'assignment', target: $1, op: '+=', value: $3 }; }
  | ID SUB_ASSIGN expression
    { $$ = { type: 'assignment', target: $1, op: '-=', value: $3 }; }
  | expression
    { $$ = $1; }
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

  | INCLUDE '<' ID '>'
    { console.log("  → #include sistema: <" + $3 + ">");
      $$ = { type: 'include', file: $3, system: true }; }

  | INCLUDE STRING
    { console.log("  → #include local: " + $2);
      $$ = { type: 'include', file: $2, system: false }; }
  ;

/* 
══════════════════════════════════════════════════════════════
  EXPRESSÕES
  Inclui operadores de comparação e lógicos com precedência
  declarada no cabeçalho — evita regra "condition" separada
  e os conflitos que ela gerava.
══════════════════════════════════════════════════════════════ 
*/

arg_list
  : /* vazio */               { $$ = []; }
  | expression                { $$ = [$1]; }
  | arg_list ',' expression   { $$ = $1.concat([$3]); }
  ;

expression
  /* ── Literais ─────────────────────────────────────────────── */
  : NUMBER
    { $$ = { type: 'number', value: $1 }; }
  | STRING
    { $$ = { type: 'string', value: $1 }; }
  | CHAR_LIT
    { $$ = { type: 'char', value: $1 }; }
  | ID
    { $$ = { type: 'id', name: $1 }; }

  /* ── Chamadas de função — cobre malloc(), free(), etc. ────── */
  | ID '(' arg_list ')'
    { console.log("    → Chamada de função: " + $1 + "()");
      $$ = { type: 'call', name: $1, args: $3 }; }

  /* ── Acesso a array ────────────────────────────────────────── */
  | ID '[' expression ']'
    { console.log("    → Acesso a array: " + $1 + "[...]");
      $$ = { type: 'index', array: $1, index: $3 }; }

  /* ── Aritméticos ───────────────────────────────────────────── */
  | expression '+' expression   { $$ = { type: '+',  left: $1, right: $3 }; }
  | expression '-' expression   { $$ = { type: '-',  left: $1, right: $3 }; }
  | expression '*' expression   { $$ = { type: '*',  left: $1, right: $3 }; }
  | expression '/' expression   { $$ = { type: '/',  left: $1, right: $3 }; }
  | expression '%' expression   { $$ = { type: '%',  left: $1, right: $3 }; }

  /* ── Comparação ────────────────────────────────────────────── */
  | expression EQ  expression
    { console.log("    → Operador =="); $$ = { type: '==', left: $1, right: $3 }; }
  | expression NEQ expression
    { console.log("    → Operador !="); $$ = { type: '!=', left: $1, right: $3 }; }
  | expression '<'  expression
    { console.log("    → Operador <");  $$ = { type: '<',  left: $1, right: $3 }; }
  | expression '>'  expression
    { console.log("    → Operador >");  $$ = { type: '>',  left: $1, right: $3 }; }
  | expression LE   expression
    { console.log("    → Operador <="); $$ = { type: '<=', left: $1, right: $3 }; }
  | expression GE   expression
    { console.log("    → Operador >="); $$ = { type: '>=', left: $1, right: $3 }; }

  /* ── Lógicos ───────────────────────────────────────────────── */
  | expression AND expression
    { console.log("    → Operador &&"); $$ = { type: '&&', left: $1, right: $3 }; }
  | expression OR  expression
    { console.log("    → Operador ||"); $$ = { type: '||', left: $1, right: $3 }; }
  | '!' expression
    { $$ = { type: '!', expr: $2 }; }

  /* ── Unários ───────────────────────────────────────────────── */
  | '-' expression %prec UMINUS
    { $$ = { type: 'neg', expr: $2 }; }
  | '~' expression
    { $$ = { type: '~', expr: $2 }; }
  | '(' expression ')'
    { $$ = $2; }

  /* ── Incremento / decremento ───────────────────────────────── */
  | ID INC
    { console.log("    → Pós-incremento: " + $1); $$ = { type: 'post++', var: $1 }; }
  | ID DEC
    { console.log("    → Pós-decremento: " + $1); $$ = { type: 'post--', var: $1 }; }
  | INC ID
    { console.log("    → Pré-incremento: " + $2); $$ = { type: 'pre++', var: $2 }; }
  | DEC ID
    { console.log("    → Pré-decremento: " + $2); $$ = { type: 'pre--', var: $2 }; }

  /* ── Ponteiros ─────────────────────────────────────────────── */
  | '&' ID
    { console.log("    → Endereço de: " + $2); $$ = { type: 'address_of', var: $2 }; }
  | '*' ID %prec UMINUS
    { console.log("    → Derreferência: *" + $2); $$ = { type: 'deref', var: $2 }; }

  /* ── sizeof ────────────────────────────────────────────────── */
  | SIZEOF '(' type ')'
    { console.log("    → sizeof tipo"); $$ = { type: 'sizeof', arg: $3 }; }
  | SIZEOF '(' ID ')'
    { console.log("    → sizeof variável"); $$ = { type: 'sizeof', arg: $3 }; }
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
