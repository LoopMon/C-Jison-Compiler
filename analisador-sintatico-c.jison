/*
Definição de Expressões Regulares para Tokens
*/

%lex
%%

\s+ /* ignora espaços */

/* Operadores e Símbolos */
"//" return "//";
"/*" return "/*";
"*/" return "*/";
"++" return "++";
"--" return "--";
"+=" return "+=";
"-=" return "-=";
"*=" return "*=";
"/=" return "/=";
"%=" return "%=";
"&=" return "&=";
"|=" return "|=";
"^=" return "^=";
"<<=" return "<<=";
"<<" return "<<";
">>" return ">>";
"->" return "->";
"+" return "+";
"-" return "-";
"*" return "*";
"/" return "/";
"%" return "%";
"==" return "==";
"!=" return "!=";
"<=" return "<=";
">=" return ">=";
"<" return "<";
">" return ">";
"&&" return "&&";
"||" return "||";
"!" return "!";
"=" return "=";
"&" return "&";
"|" return "|";
"^" return "^";
"~" return "~";
"," return ",";
";" return ";";
"?" return "?";
":" return ":";
"." return ".";
"(" return "(";
")" return ")";
"[" return "[";
"]" return "]";
"{" return "{";
"}" return "}";
'"' return '"';
"'" return "'";

/* Tipos de dados primitivos */
"char" return "CHAR";
"double" return "DOUBLE";
"float" return "FLOAT";
"int" return "INT";
"long" return "LONG";
"short" return "SHORT";
"unsigned" return "UNSIGNED";
"signed" return "SIGNED";
"void" return "VOID";

/* Controle de fluxo */
"if" return "if";
"else" return "else";
"switch" return "switch";
"case" return "case";
"default" return "default";
"while" return "while";
"do" return "do";
"for" return "for";
"break" return "break";
"continue" return "continue";
"goto" return "goto";

/* Modificadores de armazenamento */
"auto" return "auto";
"extern" return "extern";
"register" return "register";
"static" return "static";
"typedef" return "typedef";
"sizeof" return "sizeof";

/* Manipulação de estrutura de dados */
"struct" return "struct";
"union" return "union";
"enum" return "enum";

/* Outros */
"return" return "return";
"const" return "const";
"volatile" return "volatile";
"#define" return "#define";
"#include" return "#include";

[0-9]+("."[0-9]+)? return "NUMBER";
[a-zA-Z0-9]+"."[a-zA-Z0-9]+ return "FILE";
[a-zA-Z"_"][a-zA-Z0-9"_"]* return "ID";

<<EOF>> return "EOF";
. return "INVALID";

/lex

%start program
%%

program
: statement_list EOF
  { 
    console.log("✅ Programa completo reconhecido!");
    return $1; 
  }
;

statement_list
: /* vazio */ 
  { $$ = []; }
| statement_list statement 
  { $$ = $1.concat([$2]); }
;

statement
: declaration
  { console.log("📝 Declaração encontrada"); }
| assignment
  { console.log("📋 Atribuição encontrada"); }
| if_statement
  { console.log("🔀 Estrutura if encontrada"); }
| while_statement
  { console.log("🔄 Estrutura while encontrada"); }
| for_statement
  { console.log("🔁 Estrutura for encontrada"); }
| preprocessor_directive
  { console.log("📦 Diretiva de pré-processador encontrada"); }
| expression ';'
  { console.log("📊 Expressão encontrada"); }
| block
  { console.log("📦 Bloco de código encontrado"); }
;

declaration
: type ID ';'
  { 
    console.log(`  → Declaração simples: ${$2}`);
    $$ = { type: 'declaration', varType: $1, name: $2 };
  }
| type ID '=' expression ';'
  { 
    console.log(`  → Declaração com inicialização: ${$2}`);
    $$ = { type: 'declaration', varType: $1, name: $2, init: $4 };
  }
| type ID '[' NUMBER ']' ';'
  { 
    console.log(`  → Declaração de array: ${$2}[${$4}]`);
    $$ = { type: 'array_declaration', varType: $1, name: $2, size: $4 };
  }
;

assignment
: ID '=' expression ';'
  { 
    console.log(`  → Atribuição para variável: ${$1}`);
    $$ = { type: 'assignment', target: $1, value: $3 };
  }
| ID '[' expression ']' '=' expression ';'
  { 
    console.log(`  → Atribuição para array: ${$1}[...]`);
    $$ = { type: 'array_assignment', array: $1, index: $3, value: $6 };
  }
;

if_statement
: IF '(' condition ')' statement
  { 
    console.log("  → If simples");
    $$ = { type: 'if', condition: $3, then: $5 };
  }
| IF '(' condition ')' statement ELSE statement
  { 
    console.log("  → If-else");
    $$ = { type: 'if_else', condition: $3, then: $5, else: $7 };
  }
;

while_statement
: WHILE '(' condition ')' statement
  { 
    console.log("  → While loop");
    $$ = { type: 'while', condition: $3, body: $5 };
  }
;

for_statement
: FOR '(' for_init ';' condition ';' for_update ')' statement
  { 
    console.log("  → For loop");
    $$ = { type: 'for', init: $3, condition: $5, update: $7, body: $9 };
  }
;

for_init
: /* vazio */ { $$ = null; console.log("    → For sem inicialização"); }
| declaration { $$ = $1; console.log("    → For com declaração"); }
| assignment { $$ = $1; console.log("    → For com atribuição"); }
| expression { $$ = $1; console.log("    → For com expressão"); }
;

for_update
: /* vazio */ { $$ = null; }
| expression { $$ = $1; }
;

preprocessor_directive
: DEFINE ID NUMBER
  { 
    console.log(`  → Define: ${$2} = ${$3}`);
    $$ = { type: 'define', name: $2, value: $3 };
  }
| DEFINE ID expression
  { 
    console.log(`  → Define com expressão: ${$2}`);
    $$ = { type: 'define', name: $2, value: $3 };
  }
| INCLUDE '<' FILE '>'
  { 
    console.log(`  → Include sistema: ${$3}`);
    $$ = { type: 'include', file: $3, system: true };
  }
| INCLUDE '"' FILE '"'
  { 
    console.log(`  → Include local: ${$3}`);
    $$ = { type: 'include', file: $3, system: false };
  }
;

condition
: expression EQ expression
  { console.log(`    → Condição: ==`); $$ = { type: 'eq', left: $1, right: $3 }; }
| expression NEQ expression
  { console.log(`    → Condição: !=`); $$ = { type: 'neq', left: $1, right: $3 }; }
| expression LT expression
  { console.log(`    → Condição: <`); $$ = { type: 'lt', left: $1, right: $3 }; }
| expression GT expression
  { console.log(`    → Condição: >`); $$ = { type: 'gt', left: $1, right: $3 }; }
| expression LE expression
  { console.log(`    → Condição: <=`); $$ = { type: 'le', left: $1, right: $3 }; }
| expression GE expression
  { console.log(`    → Condição: >=`); $$ = { type: 'ge', left: $1, right: $3 }; }
| expression AND expression
  { console.log(`    → Condição: &&`); $$ = { type: 'and', left: $1, right: $3 }; }
| expression OR expression
  { console.log(`    → Condição: ||`); $$ = { type: 'or', left: $1, right: $3 }; }
| expression
  { console.log(`    → Condição simples`); $$ = $1; }
;

expression
: NUMBER
  { $$ = { type: 'number', value: $1 }; }
| ID
  { $$ = { type: 'identifier', name: $1 }; }
| expression '+' expression
  { console.log(`    → Operação: +`); $$ = { type: 'add', left: $1, right: $3 }; }
| expression '-' expression
  { console.log(`    → Operação: -`); $$ = { type: 'sub', left: $1, right: $3 }; }
| expression '*' expression
  { console.log(`    → Operação: *`); $$ = { type: 'mul', left: $1, right: $3 }; }
| expression '/' expression
  { console.log(`    → Operação: /`); $$ = { type: 'div', left: $1, right: $3 }; }
| '(' expression ')'
  { $$ = $2; }
| ID '++'
  { console.log(`    → Pós-incremento: ${$1}`); $$ = { type: 'post_inc', var: $1 }; }
| ID '--'
  { console.log(`    → Pós-decremento: ${$1}`); $$ = { type: 'post_dec', var: $1 }; }
| '++' ID
  { console.log(`    → Pré-incremento: ${$2}`); $$ = { type: 'pre_inc', var: $2 }; }
| '--' ID
  { console.log(`    → Pré-decremento: ${$2}`); $$ = { type: 'pre_dec', var: $2 }; }
;

type
: INT    { $$ = 'int'; }
| FLOAT  { $$ = 'float'; }
| CHAR   { $$ = 'char'; }
| DOUBLE { $$ = 'double'; }
| VOID   { $$ = 'void'; }
;

block
: '{' statement_list '}'
  { $$ = { type: 'block', statements: $2 }; }
;