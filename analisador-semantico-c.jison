/*
  Analisador Semântico — C Simplificado
  Implementado com Jison (LALR)
*/

%{
  class Variable {
    constructor(name, type, scopeId, value = null) {
      this.name = name
      this.type = type
      this.scopeId = scopeId
      this.value = value
    }
  }

  class Scope {
    constructor(id, name, parent, depth, entry = null) {
      this.id = id
      this.name = name
      this.parent = parent
      this.depth = depth
      this.entry = entry
      this.exit = null
      this.variables = new Map()
    }
  }

  class ScopeAnalyzer {
    constructor() {
      this.scopes = []
      this.stack = []
      this.nextScopeId = 0
      this.time = 0 // famoso contador de escopo
    }

    _tick() {
      this.time += 1
      return this.time
    }

    openScope(name) {
      const parent = this.stack.length > 0
        ? this.stack[this.stack.length - 1]
        : null

      const depth = parent ? parent.depth + 1 : 0

      const scope = new Scope(
        this.nextScopeId,
        name,
        parent,
        depth,
        this._tick()
      )

      this.nextScopeId += 1

      this.scopes.push(scope)
      this.stack.push(scope)

      console.log(`\nABRIU ESCOPO: ${scope.name}`)
      console.log(
        ` id=${scope.id}, profundidade=${scope.depth}, entrada=${scope.entry}`
      )

      return scope
    }

    closeScope() {
      const scope = this.stack.pop()

      scope.exit = this._tick()

      console.log(`\nFECHOU ESCOPO: ${scope.name}`)
      console.log(
        ` id=${scope.id}, entrada=${scope.entry}, saída=${scope.exit}`
      )

      return scope
    }

    currentScope() {
      return this.stack[this.stack.length - 1]
    }

    declareVar(type, name, value = null) {
      const scope = this.currentScope()

      console.log(
        `\nDECLARAÇÃO: ${type} ${name}` +
        (value !== null ? ` = ${value}` : "")
      )

      console.log(` Escopo atual: ${scope.name} id=${scope.id}`)

      if (scope.variables.has(name)) {
        console.log(
          ` ERRO: variável '${name}' já declarada neste mesmo escopo.`
        )
        return null
      }

      const variable = new Variable(
        name,
        type,
        scope.id,
        value
      )

      scope.variables.set(name, variable)

      console.log(
        ` OK: variável '${name}' registrada no escopo ${scope.id}.`
      )

      return variable
    }

    isTypeCompatible(targetType, sourceType) {
      // mesmos tipos
      if (targetType === sourceType) {
        return true
      }

      // int pode virar float
      if (targetType === "float" && sourceType === "int") {
        return true
      }

      return false
    }

    inferType(value) {
      if (typeof value === "boolean") {
        return "bool"
      }

      if (typeof value === "string") {
        return "string"
      }

      if (typeof value === "number") {
        return Number.isInteger(value)
          ? "int"
          : "float"
      }

      return "unknown"
    }

    resolveVar(name) {
      console.log(` Procurando variável '${name}'...`)

      for (let i = this.stack.length - 1; i >= 0; i--) {
        const scope = this.stack[i]

        if (scope.variables.has(name)) {
          const variable = scope.variables.get(name)

          console.log(
            ` Encontrada '${name}' no escopo ${scope.name} ` +
            `id=${scope.id}, profundidade=${scope.depth}, valor=${variable.value}`
          )

          return [variable, scope]
        }
      }

      console.log(
        ` ERRO: variável '${name}' não declarada ou fora de escopo.`
      )

      return [null, null]
    }

    assignExpression(targetName, expressionTokens) {
      const current = this.currentScope()

      console.log("\nATRIBUIÇÃO:")
      console.log(
        ` Comando: ${targetName} = ${expressionTokens.join(" ")}`
      )

      console.log(
        ` Escopo de uso: ${current.name} id=${current.id}`
      )

      const [targetVar, targetScope] = this.resolveVar(targetName)

      if (targetVar === null) {
        console.log(
          ` ERRO: lado esquerdo '${targetName}' não é visível.`
        )
        return
      }

      const valuesForEval = []

      for (const token of expressionTokens) {
        if (["+", "-", "*", "/", "(", ")"].includes(token)) {
          valuesForEval.push(token)
        } else if (!isNaN(token)) {
          valuesForEval.push(token)
        } else {
          const [variable] = this.resolveVar(token)

          if (variable === null) {
            console.log(
              ` ERRO: variável '${token}' não é visível na expressão.`
            )
            return
          }

          if (variable.value === null) {
            console.log(
              ` ERRO: variável '${token}' não possui valor definido.`
            )
            return
          }

          valuesForEval.push(String(variable.value))
        }
      }

      const expressionAsText = valuesForEval.join(" ")

      let result

      try {
        result = eval(expressionAsText)
        const resultType = this.inferType(result)

        console.log(` Tipo do resultado: ${resultType}`)

        if (!this.isTypeCompatible(targetVar.type, resultType)) {
          console.log(
            ` ERRO DE TIPOS: não é possível atribuir '${resultType}' em '${targetVar.type}'.`
          )
          return
        }
      } catch (error) {
        console.log(` ERRO ao calcular expressão: ${error}`)
        return
      }

      console.log(
        ` Expressão resolvida: ${expressionTokens.join(" ")}`
      )

      console.log(` Expressão numérica: ${expressionAsText}`)
      console.log(` Resultado: ${result}`)

      const oldValue = targetVar.value

      targetVar.value = result

      console.log(
        ` Atribuição válida: '${targetName}' do escopo ${targetScope.id} ` +
        `mudou de ${oldValue} para ${targetVar.value}`
      )
    }

    printScopeTable() {
      console.log("\n" + "=".repeat(30))
      console.log("TABELA DE ESCOPOS")
      console.log("=".repeat(30))

      for (const scope of this.scopes) {
        const parentId = scope.parent
          ? scope.parent.id
          : null

        console.log(
          `Escopo id=${scope.id}, nome=${scope.name}, pai=${parentId}, ` +
          `profundidade=${scope.depth}, entrada=${scope.entry}, saída=${scope.exit}`
        )

        if (scope.variables.size > 0) {
          for (const variable of scope.variables.values()) {
            console.log(
              ` variável ${variable.name}, valor=${variable.value}, ` +
              `declarada no escopo ${variable.scopeId}`
            )
          }
        } else {
          console.log(" nenhuma variável declarada")
        }
      }
    }
  }
%}

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

/* ── Identicador ──────────────────────────────────────────────── */
[a-zA-Z_][a-zA-Z0-9_]*   return 'ID';

/* ── Outros ──────────────────────────────────────────────── */
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
  : statement_list EOF {
    analyzer.closeScope()
    analyzer.printScopeTable();
    return $1;
  }
  ;

statement_list
  : /* vazio */ { 
    analyzer = new ScopeAnalyzer();
    analyzer.openScope("global");
    $$ = []; 
  } | statement_list statement { 
    $$ = $1.concat([$2]); 
  }
  ;

statement
  : declaration { 
    $$ = $1; 
  } | struct_definition { 
    $$ = $1; 
  } | union_definition { 
    $$ = $1; 
  } | enum_definition { 
    $$ = $1; 
  } | typedef_declaration { 
    $$ = $1; 
  } | function_definition { 
    $$ = $1; 
  } | if_statement { 
    $$ = $1; 
  } | switch_statement { 
    $$ = $1; 
  } | while_statement { 
    $$ = $1; 
  } | do_while_statement { 
    $$ = $1; 
  } | for_statement { 
    $$ = $1; 
  } | return_statement { 
    $$ = $1; 
  } | break_statement { 
    $$ = $1;
  } | continue_statement { 
    $$ = $1; 
  } | goto_statement { 
    $$ = $1; 
  } | label_statement { 
    $$ = $1; 
  } | preprocessor_directive { 
    $$ = $1; 
  } | expression ';' { 
    $$ = $1; 
  } | block { 
    $$ = $1; 
  }
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
  : type declarator_list ';' { 
    $$ = { type: 'declaration', varType: $1, declarators: $2 }; 
  }
  | ID declarator_list ';' { 
    $$ = { type: 'declaration', varType: $1, declarators: $2 };
  }
  ;

declarator_list
  : declarator { $$ = [$1]; }
  | declarator_list ',' declarator { $$ = $1.concat([$3]); }
  ;

declarator
  : ID { 
    $$ = { type: 'variable', name: $1, init: null }; 
  }
  | ID '=' expression { 
    $$ = { type: 'variable', name: $1, init: $3 };
  }
  | ID '=' '{' initializer_list '}' { 
    $$ = { type: 'variable', name: $1, init: { type: 'init_list', values: $4 } };
  }
  | '*' ID { 
    $$ = { type: 'pointer', name: $2, init: null }; 
  }
  | '*' ID '=' expression { 
    $$ = { type: 'pointer', name: $2, init: $4 }; 
  }
  | '*' ID '=' '{' initializer_list '}' { 
    $$ = { type: 'pointer', name: $2, init: { type: 'init_list', values: $5 } }; 
  }
  | '*' '*' ID { 
    $$ = { type: 'double_pointer', name: $3, init: null }; 
  }
  | '*' '*' ID '=' expression { 
    $$ = { type: 'double_pointer', name: $3, init: $5 }; 
  }
  | '*' '*' ID '=' '{' initializer_list '}' { 
    $$ = { type: 'double_pointer', name: $3, init: { type: 'init_list', values: $6 } }; 
  }
  | ID '[' expression ']' { 
    $$ = { type: 'array', name: $1, size: $3, init: null }; 
  }
  | ID '[' ']' { 
    $$ = { type: 'array', name: $1, size: null, init: null }; 
  }
  | ID '[' ']' '=' '{' initializer_list '}' { 
    $$ = { type: 'array', name: $1, size: null, init: $6 }; 
  }
  | ID '[' ']' '=' expression { 
    $$ = { type: 'array', name: $1, size: null, init: $5 }; 
  }
  | ID '[' expression ']' '=' '{' initializer_list '}' { 
    $$ = { type: 'array', name: $1, size: $3, init: $7 }; 
  }
  | ID '[' expression ']' '=' expression { 
    $$ = { type: 'array', name: $1, size: $3, init: $6 }; 
  }
  | ID '[' expression ']' '[' expression ']' { 
    $$ = { type: 'matrix', name: $1, rows: $3, cols: $6, init: null }; 
  }
  | ID '[' expression ']' '[' expression ']' '=' '{' initializer_list '}' { 
    $$ = { type: 'matrix', name: $1, rows: $3, cols: $6, init: $10 }; 
  }
  | ID '[' ']' '[' expression ']' { 
    $$ = { type: 'matrix', name: $1, rows: null, cols: $5, init: null }; 
  }
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
  : type ID '(' VOID ')' block { 
    $$ = { type: 'function', returnType: $1, name: $2, params: [], body: $6 }; 
  }
  | type '*' ID '(' VOID ')' block { 
    $$ = { type: 'function', returnType: $1 + '*', name: $3, params: [], body: $7 }; 
  }
  | type ID '(' VOID ')' ';' { 
    $$ = { type: 'prototype', returnType: $1, name: $2, params: [] }; 
  }
  | type '*' ID '(' VOID ')' ';' { 
    $$ = { type: 'prototype', returnType: $1 + '*', name: $3, params: [] }; 
  }
  | type ID '(' param_list ')' block { 
    $$ = { type: 'function', returnType: $1, name: $2, params: $4, body: $6 }; 
  }
  | type '*' ID '(' param_list ')' block { 
    $$ = { type: 'function', returnType: $1 + '*', name: $3, params: $5, body: $7 }; 
  }
  | type ID '(' param_list ')' ';' { 
    $$ = { type: 'prototype', returnType: $1, name: $2, params: $4 }; 
  }
  | type '*' ID '(' param_list ')' ';' { 
    $$ = { type: 'prototype', returnType: $1 + '*', name: $3, params: $5 }; 
  }
  ;

/*
══════════════════════════════════════════════════════════════
  STRUCT
══════════════════════════════════════════════════════════════
*/

struct_definition
  : STRUCT ID '{' struct_member_list '}' ';' { 
    $$ = { type: 'struct_def', name: $2, members: $4 }; 
  }
  | STRUCT ID ID "=" '{' struct_member_values '}' ';' { 
    $$ = { type: 'struct_def', name: $2, members: $4 }; 
  }
  | STRUCT ID '{' struct_member_list '}' declarator_list ';' { 
    $$ = { type: 'struct_def', name: $2, members: $4, vars: $6 }; 
  }
  | STRUCT '{' struct_member_list '}' declarator_list ';' { 
    $$ = { type: 'struct_def', name: null, members: $3, vars: $5 }; 
  }
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
  : UNION ID '{' struct_member_list '}' ';' { 
    $$ = { type: 'union_def', name: $2, members: $4 }; 
  }
  | UNION ID '{' struct_member_list '}' declarator_list ';' { 
    $$ = { type: 'union_def', name: $2, members: $4, vars: $6 }; 
  }
  | UNION '{' struct_member_list '}' declarator_list ';' { 
    $$ = { type: 'union_def', name: null, members: $3, vars: $5 }; 
  }
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
  : ENUM ID '{' enum_member_list '}' ';' { 
    $$ = { type: 'enum_def', name: $2, members: $4 }; 
  }
  | ENUM ID '{' enum_member_list '}' declarator_list ';' { 
    $$ = { type: 'enum_def', name: $2, members: $4, vars: $6 }; 
  }
  | ENUM '{' enum_member_list '}' ';' { 
    $$ = { type: 'enum_def', name: null, members: $3 }; 
  }
  | ENUM '{' enum_member_list '}' declarator_list ';' { 
    $$ = { type: 'enum_def', name: null, members: $3, vars: $5 }; 
  }
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
  : TYPEDEF type ID ';' { 
    $$ = { type: 'typedef', base: $2, alias: $3 }; 
  }
  | TYPEDEF type '*' ID ';' { 
    $$ = { type: 'typedef', base: $2 + '*', alias: $4 }; 
  }
  | TYPEDEF STRUCT '{' struct_member_list '}' ID ';' { 
    $$ = { type: 'typedef_struct', name: null, members: $4, alias: $6 }; 
  }
  | TYPEDEF STRUCT ID '{' struct_member_list '}' ID ';' { 
    $$ = { type: 'typedef_struct', name: $3, members: $5, alias: $7 }; 
  }
  | TYPEDEF UNION '{' struct_member_list '}' ID ';' { 
    $$ = { type: 'typedef_union', name: null, members: $4, alias: $6 }; 
  }
  | TYPEDEF ENUM '{' enum_member_list '}' ID ';' { 
    $$ = { type: 'typedef_enum', name: null, members: $4, alias: $6 };
  }
  ;

/*
══════════════════════════════════════════════════════════════
  ESTRUTURAS CONDICIONAIS
══════════════════════════════════════════════════════════════
*/

if_statement
  : IF '(' expression ')' statement %prec LOWER_THAN_ELSE { 
    $$ = { type: 'if', condition: $3, then: $5 }; 
  }
  | IF '(' expression ')' statement ELSE statement { 
    $$ = { type: 'if_else', condition: $3, then: $5, else: $7 }; 
  }
  ;

/*
══════════════════════════════════════════════════════════════
  SWITCH / CASE / DEFAULT
══════════════════════════════════════════════════════════════
*/

switch_statement
  : SWITCH '(' expression ')' '{' case_list '}' { 
    $$ = { type: 'switch', condition: $3, cases: $6 }; 
  }
  ;

case_list
  : /* vazio */
    { $$ = []; }
  | case_list case_clause
    { $$ = $1.concat([$2]); }
  ;

case_clause
  : CASE expression ':' statement_list { 
    $$ = { type: 'case', value: $2, body: $4 }; 
  }
  | DEFAULT ':' statement_list { 
    $$ = { type: 'default', body: $3 }; 
  }
  ;

/*
══════════════════════════════════════════════════════════════
  ESTRUTURAS DE REPETIÇÃO
══════════════════════════════════════════════════════════════
*/

while_statement
  : WHILE '(' expression ')' statement { 
    $$ = { type: 'while', condition: $3, body: $5 }; 
  }
  ;

do_while_statement
  : DO statement WHILE '(' expression ')' ';' { 
    $$ = { type: 'do_while', body: $2, condition: $5 }; 
  }
  ;

for_statement
  : FOR '(' for_init ';' for_cond ';' for_update ')' statement { 
    $$ = { type: 'for', init: $3, condition: $5, update: $7, body: $9 }; 
  }
  ;

for_init
  : /* vazio */
    { $$ = null; }
  | type declarator_list { 
    $$ = { type: 'declaration', varType: $1, declarators: $2 }; 
  }
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
  : RETURN ';' { 
    $$ = { type: 'return', value: null }; 
  }
  | RETURN expression ';' { 
    $$ = { type: 'return', value: $2 }; 
  }
  ;

break_statement
  : BREAK ';'
    { $$ = { type: 'break' }; }
  ;

continue_statement
  : CONTINUE ';'
    { $$ = { type: 'continue' }; }
  ;

goto_statement
  : GOTO ID ';'
    { $$ = { type: 'goto', label: $2 }; }
  ;

label_statement
  : ID ':' statement
    { $$ = { type: 'label', name: $1, body: $3 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  DIRETIVAS DE PRÉ-PROCESSADOR
══════════════════════════════════════════════════════════════
*/

preprocessor_directive
  : DEFINE ID expression { 
    $$ = { type: 'define', name: $2, value: $3 }; 
  }
  | DEFINE ID { 
    $$ = { type: 'define', name: $2, value: null }; 
  }
  | INCLUDE LT include_path GT { 
    $$ = { type: 'include', file: $3, system: true }; 
  }
  | INCLUDE STRING { 
    $$ = { type: 'include', file: $2, system: false }; 
  }
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

  | ID '(' arg_list ')' { 
    $$ = { type: 'call', name: $1, args: $3 }; 
  }

  | expression '[' expression ']' { 
    $$ = { type: 'index', array: $1, index: $3 }; 
  }

  | expression '.' ID { 
    $$ = { type: 'member', object: $1, member: $3 }; 
  }
  | expression ARROW ID { 
    $$ = { type: 'arrow', object: $1, member: $3 }; 
  }

  | '(' type ')' expression %prec UMINUS { 
    $$ = { type: 'cast', castType: $2, expr: $4 }; 
  }
  | '(' type '*' ')' expression %prec UMINUS { 
    $$ = { type: 'cast', castType: $2 + '*', expr: $5 }; 
  }
  | '(' type '*' '*' ')' expression %prec UMINUS { 
    $$ = { type: 'cast', castType: $2 + '**', expr: $6 }; 
  }

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
    { $$ = { type: '==', left: $1, right: $3 }; }
  | expression NEQ expression
    { $$ = { type: '!=', left: $1, right: $3 }; }
  | expression LT  expression
    { $$ = { type: '<',  left: $1, right: $3 }; }
  | expression GT  expression
    { $$ = { type: '>',  left: $1, right: $3 }; }
  | expression LE  expression
    { $$ = { type: '<=', left: $1, right: $3 }; }
  | expression GE  expression
    { $$ = { type: '>=', left: $1, right: $3 }; }

  | expression AND expression
    { $$ = { type: '&&', left: $1, right: $3 }; }
  | expression OR  expression
    { $$ = { type: '||', left: $1, right: $3 }; }
  | NOT expression
    { $$ = { type: '!', expr: $2 }; }

  | '-' expression %prec UMINUS
    { $$ = { type: 'neg', expr: $2 }; }
  | '~' expression
    { $$ = { type: '~', expr: $2 }; }
  | '(' expression ')'
    { $$ = $2; }

  | expression INC  %prec INC
    { $$ = { type: 'post++', expr: $1 }; }
  | expression DEC  %prec DEC
    { $$ = { type: 'post--', expr: $1 }; }
  | INC expression
    { $$ = { type: 'pre++', expr: $2 }; }
  | DEC expression
    { $$ = { type: 'pre--', expr: $2 }; }

  | '&' expression  %prec ADDR
    { $$ = { type: 'address_of', expr: $2 }; }
  | '*' expression  %prec DEREF
    { $$ = { type: 'deref', expr: $2 }; }

  | expression '=' expression
    { $$ = { type: '=',   left: $1, right: $3 }; }
  | expression ADD_ASSIGN expression
    { $$ = { type: '+=',  left: $1, right: $3 }; }
  | expression SUB_ASSIGN expression
    { $$ = { type: '-=',  left: $1, right: $3 }; }
  | expression MUL_ASSIGN expression
    { $$ = { type: '*=',  left: $1, right: $3 }; }
  | expression DIV_ASSIGN expression
    { $$ = { type: '/=',  left: $1, right: $3 }; }
  | expression MOD_ASSIGN expression
    { $$ = { type: '%=',  left: $1, right: $3 }; }
  | expression AND_ASSIGN expression
    { $$ = { type: '&=',  left: $1, right: $3 }; }
  | expression OR_ASSIGN expression
    { $$ = { type: '|=',  left: $1, right: $3 }; }
  | expression XOR_ASSIGN expression
    { $$ = { type: '^=',  left: $1, right: $3 }; }
  | expression LSHIFT_ASSIGN expression
    { $$ = { type: '<<=', left: $1, right: $3 }; }
  | expression RSHIFT_ASSIGN expression
    { $$ = { type: '>>=', left: $1, right: $3 }; }

  | SIZEOF '(' type ')'
    { $$ = { type: 'sizeof', arg: $3 }; }
  | SIZEOF '(' type '*' ')'
    { $$ = { type: 'sizeof', arg: $3 + '*' }; }
  | SIZEOF '(' expression ')'
    { $$ = { type: 'sizeof_expr', arg: $3 }; }
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
