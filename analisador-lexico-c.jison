/*
Definição de Expressões Regulares para Tokens

Na primeira parte, o aluno deverá definir expressões regulares para os tokens da linguagem, incluindo:
- Palavras reservadas
- Identificadores
- Números inteiros e de ponto flutuante
- Strings e caracteres
- Operadores e símbolos especiais
O objetivo é garantir que o lexer consiga reconhecer corretamente os tokens da linguagem C
*/

%lex
%%

\s+ /* ignora espaços */
/* =-=-= Operadores e Símbolos =-=-= */
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
"<<=" return ">>=";
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
"." return ".";
"(" return "(";
")" return ")";
"["return "[";
"]" return "]";
"{" return "{";
"}" return "}";
'"' return '"';
"'" return "'";
/* =-=-= Tipos de dados primitivos =-=-= */
"char" return "char";
"double" return "double";
"float" return "float";
"int" return "int";
"long" return "long";
"short" return "short";
"unsigned" return "unsigned";
"signed" return "signed";
"void" return "void";
/* =-=-= Controle de fluxo =-=-= */
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
/* =-=-= Modificadores de armazenamento =-=-= */
"auto" return "auto";
"extern" return "extern";
"register" return "register";
"static" return "static";
"typedef" return "typedef";
"sizeof" return "sizeof";
/* =-=-= Manipulação de estrutura de dados =-=-= */
"struct" return "struct";
"union" return "union";
"enum" return "enum";
/* =-=-= Outros =-=-= */
"return" return "return";
"const" return "const";
"volatile" return "volatile";
"#define" return "#define";
"#include" return "#include";
[0-9]+("."[0-9]+)? return "NUMBER";
[a-zA-Z"_"][a-zA-Z0-9"_"]* return "ID";

<<EOF>> return "EOF";
. return "INVALID";

/lex

%start tokens
%%

tokens
: e EOF { return $1; }
| INVALID { throw new Error("Token Inválido") }
;

e
: "//" {$$ = yytext;} 
|"/*" {$$ = yytext;} 
|"*/" {$$ = yytext;} 
|"++" {$$ = yytext;} 
|"--" {$$ = yytext;} 
|"+=" {$$ = yytext;} 
|"-=" {$$ = yytext;} 
|"*=" {$$ = yytext;} 
|"/=" {$$ = yytext;} 
|"%=" {$$ = yytext;} 
|"&=" {$$ = yytext;} 
|"|=" {$$ = yytext;} 
|"^=" {$$ = yytext;} 
|"<<=" {$$ = yytext;} 
|"<<" {$$ = yytext;} 
|">>" {$$ = yytext;} 
|"->" {$$ = yytext;} 
|"+" {$$ = yytext;} 
|"-" {$$ = yytext;} 
|"*" {$$ = yytext;} 
|"/" {$$ = yytext;} 
|"%" {$$ = yytext;} 
|"==" {$$ = yytext;} 
|"!=" {$$ = yytext;} 
|"<=" {$$ = yytext;} 
|">=" {$$ = yytext;} 
|"<" {$$ = yytext;} 
|">" {$$ = yytext;} 
|"&&" {$$ = yytext;} 
|"||" {$$ = yytext;} 
|"!" {$$ = yytext;} 
|"=" {$$ = yytext;} 
|"&" {$$ = yytext;} 
|"|" {$$ = yytext;} 
|"^" {$$ = yytext;} 
|"~" {$$ = yytext;} 
|"," {$$ = yytext;} 
|";" {$$ = yytext;} 
|"." {$$ = yytext;} 
|"(" {$$ = yytext;} 
|")" {$$ = yytext;} 
|"[" {$$ = yytext;} 
|"]" {$$ = yytext;} 
|"{" {$$ = yytext;} 
|"}" {$$ = yytext;} 
|'"' {$$ = yytext;} 
|"'" {$$ = yytext;} 
|NUMBER {$$ = yytext;} 
|ID {$$ = yytext;} 
|"char" {$$ = yytext;} 
|"double" {$$ = yytext;} 
|"float" {$$ = yytext;} 
|"int" {$$ = yytext;} 
|"long" {$$ = yytext;} 
|"short" {$$ = yytext;} 
|"unsigned" {$$ = yytext;} 
|"signed" {$$ = yytext;} 
|"void" {$$ = yytext;} 
|"if" {$$ = yytext;} 
|"else" {$$ = yytext;} 
|"switch" {$$ = yytext;} 
|"case" {$$ = yytext;} 
|"default" {$$ = yytext;} 
|"while" {$$ = yytext;} 
|"do" {$$ = yytext;} 
|"for" {$$ = yytext;} 
|"break" {$$ = yytext;} 
|"continue" {$$ = yytext;} 
|"goto" {$$ = yytext;} 
|"auto" {$$ = yytext;} 
|"extern" {$$ = yytext;} 
|"register" {$$ = yytext;} 
|"static" {$$ = yytext;} 
|"typedef" {$$ = yytext;} 
|"sizeof" {$$ = yytext;} 
|"struct" {$$ = yytext;} 
|"union" {$$ = yytext;} 
|"enum" {$$ = yytext;} 
|"return" {$$ = yytext;} 
|"const" {$$ = yytext;} 
|"volatile" {$$ = yytext;} 
|"#define" {$$ = yytext;} 
|"#include" {$$ = yytext;} 
;