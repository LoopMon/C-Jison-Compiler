/*
  Analisador Semântico — C Simplificado
  Implementado com Jison (LALR)

  Componentes implementados:
    1. Tabela de símbolos com suporte a múltiplos escopos
    2. Verificação semântica (tipos, redeclaração, variáveis não declaradas)
    3. Construção de árvore de expressões
    4. Geração de código intermediário de três endereços
*/

%{
  /* ════════════════════════════════════════════════════════════
     1. ESTRUTURA: Símbolo (variável/parâmetro/função)
     ════════════════════════════════════════════════════════════ */
  class Symbol {
    constructor(name, type, scopeId, value, kind) {
      this.name    = name    // nome do identificador
      this.type    = type    // tipo declarado (string)
      this.scopeId = scopeId // id do escopo onde foi declarado
      this.value   = value   // valor inicial (se existir)
      this.kind    = kind    // 'var' | 'param' | 'func'
    }
  }

  /* ════════════════════════════════════════════════════════════
     2. ESTRUTURA: Escopo
     ════════════════════════════════════════════════════════════ */
  class Scope {
    constructor(id, name, parent, depth, entry) {
      this.id        = id
      this.name      = name
      this.parent    = parent   // referência ao escopo pai
      this.depth     = depth    // profundidade de aninhamento
      this.entry     = entry    // timestamp de entrada (para vivência)
      this.exit      = null     // timestamp de saída
      this.symbols   = new Map()
    }
  }

  /* ════════════════════════════════════════════════════════════
     3. ESTRUTURA: Nó da árvore de expressões
     ════════════════════════════════════════════════════════════ */
  class ExprNode {
    constructor(kind, value, left, right, extra) {
      this.kind  = kind   // 'num' | 'str' | 'char' | 'id' | 'op' | 'unary' | 'call' | 'index' | ...
      this.value = value  // valor literal ou nome do operador
      this.left  = left   // filho esquerdo
      this.right = right  // filho direito
      this.extra = extra  // dados extras (args, etc.)
      this.exprType = null // tipo inferido após verificação semântica
    }
  }

  /* ════════════════════════════════════════════════════════════
     4. GERADOR DE TEMPORÁRIOS
     ════════════════════════════════════════════════════════════ */
  class TempGen {
    constructor() {
      this._count = 0
    }
    next() {
      this._count += 1
      return 't' + this._count
    }
  }

  /* ════════════════════════════════════════════════════════════
     5. GERADOR DE CÓDIGO INTERMEDIÁRIO (três endereços)
     ════════════════════════════════════════════════════════════ */
  class CodeGen {
    constructor() {
      this._instructions = []
      this._tempGen = new TempGen()
      this._labelCount = 0
    }

    /* Emite: result = left op right */
    emit(result, left, op, right) {
      let instr
      if (op === null && right === null) {
        // atribuição simples: result = left
        instr = result + ' = ' + left
      } else if (right === null) {
        // unário: result = op left
        instr = result + ' = ' + op + ' ' + left
      } else {
        // binário
        instr = result + ' = ' + left + ' ' + op + ' ' + right
      }
      this._instructions.push(instr)
      return instr
    }

    emitLabel(label) {
      this._instructions.push(label + ':')
    }

    emitGoto(label) {
      this._instructions.push('goto ' + label)
    }

    emitIfFalse(cond, label) {
      this._instructions.push('if_false ' + cond + ' goto ' + label)
    }

    emitParam(val) {
      this._instructions.push('param ' + val)
    }

    emitCall(fname, argCount, result) {
      if (result) {
        this._instructions.push(result + ' = call ' + fname + ', ' + argCount)
      } else {
        this._instructions.push('call ' + fname + ', ' + argCount)
      }
    }

    emitReturn(val) {
      if (val !== null && val !== undefined) {
        this._instructions.push('return ' + val)
      } else {
        this._instructions.push('return')
      }
    }

    newTemp() {
      return this._tempGen.next()
    }

    newLabel() {
      this._labelCount += 1
      return 'L' + this._labelCount
    }

    getCode() {
      return this._instructions
    }

    printCode() {
      console.log('\n' + '='.repeat(40))
      console.log('CÓDIGO INTERMEDIÁRIO (TRÊS ENDEREÇOS)')
      console.log('='.repeat(40))
      for (const instr of this._instructions) {
        // indenta labels de forma diferente
        if (instr.endsWith(':')) {
          console.log(instr)
        } else {
          console.log('  ' + instr)
        }
      }
    }
  }

  /* ════════════════════════════════════════════════════════════
     6. ANALISADOR DE ESCOPOS + VERIFICAÇÃO SEMÂNTICA
     ════════════════════════════════════════════════════════════ */
  class ScopeAnalyzer {
    constructor() {
      this.scopes      = []
      this.stack       = []
      this.nextScopeId = 0
      this.time        = 0
      this.errors      = []
      this.codeGen     = new CodeGen()
    }

    /* ── Utilidades internas ── */
    _tick() {
      this.time += 1
      return this.time
    }

    _semanticError(msg) {
      this.errors.push(msg)
      console.log(' ERRO SEMÂNTICO: ' + msg)
    }

    /* ── Controle de escopos ── */
    openScope(name) {
      const parent = this.stack.length > 0
        ? this.stack[this.stack.length - 1]
        : null
      const depth = parent ? parent.depth + 1 : 0
      const scope = new Scope(
        this.nextScopeId, name, parent, depth, this._tick()
      )
      this.nextScopeId += 1
      this.scopes.push(scope)
      this.stack.push(scope)
      console.log('\nABRIU ESCOPO: ' + scope.name +
        ' id=' + scope.id + ', profundidade=' + scope.depth)
      return scope
    }

    closeScope() {
      const scope = this.stack.pop()
      scope.exit = this._tick()
      console.log('\nFECHOU ESCOPO: ' + scope.name +
        ' id=' + scope.id + ', saída=' + scope.exit)
      return scope
    }

    currentScope() {
      return this.stack[this.stack.length - 1]
    }

    /* ── Inserção de símbolo ── */
    declareVar(type, name, value, kind) {
      kind = kind || 'var'
      const scope = this.currentScope()
      console.log('\nDECLARAÇÃO [' + kind + ']: ' + type + ' ' + name +
        (value !== null && value !== undefined ? ' = ' + value : '') +
        ' (escopo: ' + scope.name + ' id=' + scope.id + ')')

      if (scope.symbols.has(name)) {
        this._semanticError(
          "variável '" + name + "' já declarada no escopo '" +
          scope.name + "' (id=" + scope.id + ")"
        )
        return null
      }

      const sym = new Symbol(name, type, scope.id, value !== undefined ? value : null, kind)
      scope.symbols.set(name, sym)
      console.log(' OK: "' + name + '" registrada no escopo ' + scope.id)
      return sym
    }

    /* ── Busca de símbolo (resolução léxica) ── */
    resolveVar(name) {
      const sym = this.tryResolve(name)
      if (!sym) {
        this._semanticError("identificador '" + name + "' não declarado")
      }
      return sym
    }

    /* ── Busca silenciosa (não registra erro se não encontrar) ── */
    tryResolve(name) {
      for (let i = this.stack.length - 1; i >= 0; i--) {
        const scope = this.stack[i]
        if (scope.symbols.has(name)) {
          const sym = scope.symbols.get(name)
          console.log(' Encontrada "' + name + '" no escopo ' +
            scope.name + ' id=' + scope.id + ', tipo=' + sym.type)
          return sym
        }
      }
      return null
    }

    /* ── Compatibilidade de tipos ── */
    isTypeCompatible(target, source) {
      // Normaliza removendo qualificadores
      const norm = t => t.replace(/\b(const|static|extern|volatile|register)\s*/g, '').trim()
      const t = norm(target)
      const s = norm(source)
      if (t === s) return true
      // Promoções numéricas permitidas (sem perda de informação)
      const numericHierarchy = ['char', 'short', 'int', 'long', 'long long', 'float', 'double', 'long double']
      const ti = numericHierarchy.indexOf(t)
      const si = numericHierarchy.indexOf(s)
      if (ti !== -1 && si !== -1 && ti >= si) return true
      // Unsigned <-> signed do mesmo tamanho
      if (t.replace('unsigned ', '') === s.replace('unsigned ', '')) return true
      return false
    }

    /* ── Inferência de tipo de literal ── */
    inferLiteralType(value) {
      if (typeof value === 'string') {
        if (value.startsWith('"')) return 'char*'
        if (value.startsWith("'")) return 'char'
        // número
        if (value.includes('.')) return 'double'
        if (value.startsWith('0x') || value.startsWith('0X')) return 'int'
        return 'int'
      }
      if (typeof value === 'number') {
        return Number.isInteger(value) ? 'int' : 'double'
      }
      return 'unknown'
    }

    /* ── Tipo resultante de operação binária ── */
    binaryResultType(op, leftType, rightType) {
      const relational = ['==','!=','<','>','<=','>=','&&','||']
      if (relational.includes(op)) return 'int' // bool em C é int
      // Promoção numérica: retorna o tipo "maior"
      const hierarchy = ['char','short','int','long','long long','float','double','long double']
      const lt = (leftType  || '').replace(/\b(const|static|extern|volatile|register|unsigned|signed)\s*/g,'').trim()
      const rt = (rightType || '').replace(/\b(const|static|extern|volatile|register|unsigned|signed)\s*/g,'').trim()
      const li = hierarchy.indexOf(lt)
      const ri = hierarchy.indexOf(rt)
      if (li === -1 || ri === -1) return lt || rt || 'int'
      return li >= ri ? lt : rt
    }

    /* ════════════════════════════════════════════════════════
       ANÁLISE SEMÂNTICA E GERAÇÃO DE CÓDIGO — EXPRESSÕES
       ════════════════════════════════════════════════════════ */

    /*
     * analyzeExpr: percorre a árvore de expressões, verifica tipos
     * e emite código intermediário de três endereços.
     * Retorna { place, type } onde place é o nome do local
     * (temporário, variável ou literal) que contém o valor.
     */
    analyzeExpr(node) {
      if (!node) return { place: null, type: null }

      switch (node.kind) {

        /* ── Literais ── */
        case 'num': {
          node.exprType = this.inferLiteralType(String(node.value))
          return { place: String(node.value), type: node.exprType }
        }
        case 'str': {
          node.exprType = 'char*'
          return { place: node.value, type: 'char*' }
        }
        case 'char': {
          node.exprType = 'char'
          return { place: node.value, type: 'char' }
        }

        /* ── Identificador ── */
        case 'id': {
          const sym = this.resolveVar(node.value)
          if (!sym) {
            node.exprType = 'error'
            return { place: node.value, type: 'error' }
          }
          node.exprType = sym.type
          return { place: node.value, type: sym.type }
        }

        /* ── Operadores binários aritméticos, relacionais e lógicos ── */
        case 'binop': {
          const { place: lp, type: lt } = this.analyzeExpr(node.left)
          const { place: rp, type: rt } = this.analyzeExpr(node.right)

          // Verificação de compatibilidade
          if (lt === 'error' || rt === 'error') {
            node.exprType = 'error'
            return { place: null, type: 'error' }
          }
          if (!this.isTypeCompatible(lt, rt) && !this.isTypeCompatible(rt, lt)) {
            this._semanticError(
              "operação '" + node.value + "' entre tipos incompatíveis: '" +
              lt + "' e '" + rt + "'"
            )
            node.exprType = 'error'
            return { place: null, type: 'error' }
          }

          const resultType = this.binaryResultType(node.value, lt, rt)
          node.exprType = resultType
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, lp, node.value, rp)
          return { place: tmp, type: resultType }
        }

        /* ── Operadores unários ── */
        case 'unary': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          if (et === 'error') {
            node.exprType = 'error'
            return { place: null, type: 'error' }
          }
          node.exprType = et
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, ep, node.value, null)
          return { place: tmp, type: et }
        }

        /* ── Atribuição (=, +=, -= ...) ── */
        case 'assign': {
          const { place: lp, type: lt } = this.analyzeExpr(node.left)
          const { place: rp, type: rt } = this.analyzeExpr(node.right)

          if (lt === 'error' || rt === 'error') {
            node.exprType = 'error'
            return { place: lp, type: 'error' }
          }

          // Verifica que lado esquerdo é lvalue (id, index, deref)
          if (node.left.kind !== 'id' && node.left.kind !== 'index' &&
              node.left.kind !== 'deref' && node.left.kind !== 'member') {
            this._semanticError("lado esquerdo da atribuição não é um lvalue válido")
            node.exprType = 'error'
            return { place: lp, type: 'error' }
          }

          // Verifica compatibilidade de tipos
          if (!this.isTypeCompatible(lt, rt)) {
            this._semanticError(
              "atribuição inválida: não é possível atribuir '" +
              rt + "' em '" + lt + "'"
            )
            node.exprType = 'error'
            return { place: lp, type: 'error' }
          }

          // Operadores compostos (+=, -= etc.) são expandidos
          let rhsPlace = rp
          if (node.value !== '=') {
            const baseOp = node.value.replace('=', '')
            const tmp = this.codeGen.newTemp()
            this.codeGen.emit(tmp, lp, baseOp, rp)
            rhsPlace = tmp
          }

          this.codeGen.emit(lp, rhsPlace, null, null)
          node.exprType = lt
          return { place: lp, type: lt }
        }

        /* ── Chamada de função ── */
        case 'call': {
          // Resolve função: aceita funções não declaradas como externas (printf, etc.)
          let retType = 'int'
          const sym = this.tryResolve(node.value)
          if (sym && sym.kind === 'func') {
            retType = sym.type
          }

          // Avalia e emite parâmetros
          const args = node.extra || []
          const argPlaces = []
          for (const arg of args) {
            const { place: ap } = this.analyzeExpr(arg)
            argPlaces.push(ap)
          }
          for (const ap of argPlaces) {
            this.codeGen.emitParam(ap)
          }
          const tmp = this.codeGen.newTemp()
          this.codeGen.emitCall(node.value, args.length, tmp)
          node.exprType = retType
          return { place: tmp, type: retType }
        }

        /* ── Acesso a array ── */
        case 'index': {
          const { place: ap, type: at } = this.analyzeExpr(node.left)
          const { place: ip }           = this.analyzeExpr(node.right)
          // Remove o '[]' do tipo para obter o tipo elemento
          const elemType = at ? at.replace(/\[\]$/, '').trim() : 'int'
          node.exprType = elemType
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, ap + '[' + ip + ']', null, null)
          return { place: tmp, type: elemType }
        }

        /* ── Acesso a membro (. e ->) ── */
        case 'member': {
          const { place: op } = this.analyzeExpr(node.left)
          node.exprType = 'int' // tipo do membro não é rastreado neste nível
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, op + '.' + node.value, null, null)
          return { place: tmp, type: 'int' }
        }

        case 'arrow': {
          const { place: op } = this.analyzeExpr(node.left)
          node.exprType = 'int'
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, op + '->' + node.value, null, null)
          return { place: tmp, type: 'int' }
        }

        /* ── Cast explícito ── */
        case 'cast': {
          const { place: ep } = this.analyzeExpr(node.left)
          node.exprType = node.value
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, '(' + node.value + ') ' + ep, null, null)
          return { place: tmp, type: node.value }
        }

        /* ── Sizeof ── */
        case 'sizeof': {
          node.exprType = 'int'
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, 'sizeof(' + node.value + ')', null, null)
          return { place: tmp, type: 'int' }
        }

        /* ── Endereço-de e deref ── */
        case 'address_of': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          node.exprType = et + '*'
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, '&' + ep, null, null)
          return { place: tmp, type: et + '*' }
        }

        case 'deref': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          const baseType = et ? et.replace(/\*$/, '').trim() : 'int'
          node.exprType = baseType
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, '*' + ep, null, null)
          return { place: tmp, type: baseType }
        }

        /* ── Incremento/decremento ── */
        case 'post++': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, ep, null, null)         // preserva valor original
          this.codeGen.emit(ep, ep, '+', '1')            // incrementa
          node.exprType = et
          return { place: tmp, type: et }
        }
        case 'post--': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          const tmp = this.codeGen.newTemp()
          this.codeGen.emit(tmp, ep, null, null)
          this.codeGen.emit(ep, ep, '-', '1')
          node.exprType = et
          return { place: tmp, type: et }
        }
        case 'pre++': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          this.codeGen.emit(ep, ep, '+', '1')
          node.exprType = et
          return { place: ep, type: et }
        }
        case 'pre--': {
          const { place: ep, type: et } = this.analyzeExpr(node.left)
          this.codeGen.emit(ep, ep, '-', '1')
          node.exprType = et
          return { place: ep, type: et }
        }

        default:
          return { place: String(node.value || '?'), type: 'unknown' }
      }
    }

    /* ════════════════════════════════════════════════════════
       GERAÇÃO DE CÓDIGO PARA ESTRUTURAS DE CONTROLE
       ════════════════════════════════════════════════════════ */

    genIfCode(condNode, thenCode, elseCode) {
      const { place: cp } = this.analyzeExpr(condNode)
      const labelElse = this.codeGen.newLabel()
      const labelEnd  = this.codeGen.newLabel()

      this.codeGen.emitIfFalse(cp, elseCode ? labelElse : labelEnd)
      if (thenCode) thenCode()
      if (elseCode) {
        this.codeGen.emitGoto(labelEnd)
        this.codeGen.emitLabel(labelElse)
        elseCode()
      }
      this.codeGen.emitLabel(labelEnd)
    }

    genWhileCode(condNode, bodyCode) {
      const labelStart = this.codeGen.newLabel()
      const labelEnd   = this.codeGen.newLabel()

      this.codeGen.emitLabel(labelStart)
      const { place: cp } = this.analyzeExpr(condNode)
      this.codeGen.emitIfFalse(cp, labelEnd)
      if (bodyCode) bodyCode()
      this.codeGen.emitGoto(labelStart)
      this.codeGen.emitLabel(labelEnd)
    }

    genDoWhileCode(bodyCode, condNode) {
      const labelStart = this.codeGen.newLabel()

      this.codeGen.emitLabel(labelStart)
      if (bodyCode) bodyCode()
      const { place: cp } = this.analyzeExpr(condNode)
      this.codeGen.emitIfFalse(cp, 'after_' + labelStart)
      this.codeGen.emitGoto(labelStart)
      this.codeGen.emitLabel('after_' + labelStart)
    }

    /* ── Impressão das tabelas ── */
    printSymbolTable() {
      console.log('\n' + '='.repeat(40))
      console.log('TABELA DE SÍMBOLOS')
      console.log('='.repeat(40))
      console.log(
        'Nome'.padEnd(20) +
        'Tipo'.padEnd(20) +
        'Valor'.padEnd(15) +
        'Kind'.padEnd(8) +
        'Escopo'
      )
      console.log('-'.repeat(75))
      for (const scope of this.scopes) {
        for (const sym of scope.symbols.values()) {
          console.log(
            sym.name.padEnd(20) +
            sym.type.padEnd(20) +
            String(sym.value).padEnd(15) +
            sym.kind.padEnd(8) +
            scope.name + ' (id=' + scope.id + ')'
          )
        }
      }
    }

    printScopeTable() {
      console.log('\n' + '='.repeat(40))
      console.log('TABELA DE ESCOPOS')
      console.log('='.repeat(40))
      for (const scope of this.scopes) {
        const parentId = scope.parent ? scope.parent.id : null
        console.log(
          'Escopo id=' + scope.id + ', nome=' + scope.name +
          ', pai=' + parentId + ', profundidade=' + scope.depth +
          ', entrada=' + scope.entry + ', saída=' + scope.exit
        )
        if (scope.symbols.size > 0) {
          for (const sym of scope.symbols.values()) {
            console.log(
              '  ' + sym.kind + ' ' + sym.name +
              ' : ' + sym.type +
              (sym.value !== null ? ' = ' + sym.value : '')
            )
          }
        } else {
          console.log('  (nenhum símbolo)')
        }
      }
    }

    printErrors() {
      if (this.errors.length === 0) {
        console.log('\n✓ Nenhum erro semântico detectado.')
      } else {
        console.log('\n' + '='.repeat(40))
        console.log('ERROS SEMÂNTICOS (' + this.errors.length + ')')
        console.log('='.repeat(40))
        for (let i = 0; i < this.errors.length; i++) {
          console.log((i + 1) + '. ' + this.errors[i])
        }
      }
    }
  }

  /* ════════════════════════════════════════════════════════════
     HELPERS GLOBAIS para construção da árvore de expressões
     ════════════════════════════════════════════════════════════ */

  /* Cria nó folha */
  function leaf(kind, value) {
    return new ExprNode(kind, value, null, null, null)
  }

  /* Cria nó de operação binária */
  function binop(op, left, right) {
    return new ExprNode('binop', op, left, right, null)
  }

  /* Cria nó de operação unária */
  function unary(op, operand) {
    return new ExprNode('unary', op, operand, null, null)
  }

  /* Cria nó de atribuição */
  function assign(op, left, right) {
    return new ExprNode('assign', op, left, right, null)
  }

  /* Instância global do analisador */
  console.clear()
  var analyzer = null
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

/* ── Identificador ─────────────────────────────────────────── */
[a-zA-Z_][a-zA-Z0-9_]*   return 'ID';

/* ── Outros ────────────────────────────────────────────────── */
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
      analyzer.closeScope();
      analyzer.printScopeTable();
      analyzer.printSymbolTable();
      analyzer.codeGen.printCode();
      analyzer.printErrors();
      if (analyzer.errors.length > 0) {
        throw new Error('Erros semânticos encontrados: ' + analyzer.errors.length);
      }
      return $1;
    }
  ;

statement_list
  : /* vazio */ {
      if (!analyzer) {
        analyzer = new ScopeAnalyzer();
        analyzer.openScope("global");
      }
      $$ = [];
    }
  | statement_list statement {
      $$ = $1.concat([$2]);
    }
  ;

statement
  : declaration          { $$ = $1; }
  | struct_definition    { $$ = $1; }
  | union_definition     { $$ = $1; }
  | enum_definition      { $$ = $1; }
  | typedef_declaration  { $$ = $1; }
  | function_definition  { $$ = $1; }
  | if_statement         { $$ = $1; }
  | switch_statement     { $$ = $1; }
  | while_statement      { $$ = $1; }
  | do_while_statement   { $$ = $1; }
  | for_statement        { $$ = $1; }
  | return_statement     { $$ = $1; }
  | break_statement      { $$ = $1; }
  | continue_statement   { $$ = $1; }
  | goto_statement       { $$ = $1; }
  | label_statement      { $$ = $1; }
  | preprocessor_directive { $$ = $1; }
  | expression_statement { $$ = $1; }
  | open_block statement_list close_block {
      $$ = { type: 'block', body: $2 };
    }
  ;

/*
  expression_statement: avalia a expressão e gera código.
  Separado de 'expression ;' para poder chamar analyzeExpr aqui.
*/
expression_statement
  : expression ';' {
      analyzer.analyzeExpr($1);
      $$ = { type: 'expr_stmt', expr: $1 };
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
  Ação semântica: registra cada declarador na tabela de símbolos
  e, quando houver inicializador, gera código de atribuição.
══════════════════════════════════════════════════════════════
*/

declaration
  : type declarator_list ';' {
      for (const decl of $2) {
        // Resolve o valor inicial para literais simples
        var initVal = null;
        if (decl.init && decl.init.kind === 'num') {
          initVal = Number(decl.init.value);
        } else if (decl.init && decl.init.kind === 'str') {
          initVal = decl.init.value;
        }

        var sym = analyzer.declareVar($1, decl.name, initVal, 'var');

        // Gera código de inicialização quando houver
        if (sym && decl.init) {
          var res = analyzer.analyzeExpr(decl.init);
          if (res && res.place !== null) {
            analyzer.codeGen.emit(decl.name, res.place, null, null);
          }
        }
      }
      $$ = { type: 'declaration', varType: $1, declarators: $2 };
    }
  | ID declarator_list ';' {
      /* Declaração com typedef (tipo é um ID) */
      for (const decl of $2) {
        analyzer.declareVar($1, decl.name, null, 'var');
      }
      $$ = { type: 'declaration', varType: $1, declarators: $2 };
    }
  ;

declarator_list
  : declarator                        { $$ = [$1]; }
  | declarator_list ',' declarator    { $$ = $1.concat([$3]); }
  ;

declarator
  : ID {
      $$ = { type: 'variable', name: $1, init: null };
    }
  | ID '=' expression {
      $$ = { type: 'variable', name: $1, init: $3 };
    }
  | ID '=' '{' initializer_list '}' {
      $$ = { type: 'variable', name: $1, init: { kind: 'init_list', values: $4 } };
    }
  | '*' ID {
      $$ = { type: 'pointer', name: $2, init: null };
    }
  | '*' ID '=' expression {
      $$ = { type: 'pointer', name: $2, init: $4 };
    }
  | '*' ID '=' '{' initializer_list '}' {
      $$ = { type: 'pointer', name: $2, init: { kind: 'init_list', values: $5 } };
    }
  | '*' '*' ID {
      $$ = { type: 'double_pointer', name: $3, init: null };
    }
  | '*' '*' ID '=' expression {
      $$ = { type: 'double_pointer', name: $3, init: $5 };
    }
  | '*' '*' ID '=' '{' initializer_list '}' {
      $$ = { type: 'double_pointer', name: $3, init: { kind: 'init_list', values: $6 } };
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
  : initializer                           { $$ = [$1]; }
  | initializer_list ',' initializer      { $$ = $1.concat([$3]); }
  ;

initializer
  : expression                            { $$ = $1; }
  | '{' initializer_list '}'             { $$ = { kind: 'init_list', values: $2 }; }
  ;

/*
══════════════════════════════════════════════════════════════
  FUNÇÕES
  Ação semântica:
    - Registra a função na tabela de símbolos do escopo atual
    - Abre escopo de função
    - Declara parâmetros no novo escopo
    - Fecha escopo ao final
══════════════════════════════════════════════════════════════
*/

param_list
  : /* vazio */           { $$ = []; }
  | param                 { $$ = [$1]; }
  | param_list ',' param  { $$ = $1.concat([$3]); }
  ;

param
  : type ID {
      analyzer.declareVar($1, $2, null, 'param');
      $$ = { paramType: $1, name: $2 };
    }
  | type '*' ID {
      analyzer.declareVar($1 + '*', $3, null, 'param');
      $$ = { paramType: $1 + '*', name: $3 };
    }
  | type '*' '*' ID {
      analyzer.declareVar($1 + '**', $4, null, 'param');
      $$ = { paramType: $1 + '**', name: $4 };
    }
  | type ID '[' ']' {
      analyzer.declareVar($1 + '[]', $2, null, 'param');
      $$ = { paramType: $1 + '[]', name: $2 };
    }
  | type ID '[' ']' '[' expression ']' {
      analyzer.declareVar($1 + '[][]', $2, null, 'param');
      $$ = { paramType: $1 + '[][]', name: $2 };
    }
  | type '*' ID '[' ']' {
      analyzer.declareVar($1 + '*[]', $3, null, 'param');
      $$ = { paramType: $1 + '*[]', name: $3 };
    }
  ;

/*
  Marcador vazio que abre o escopo da função logo após '('.
  Como TODAS as produções de função passam por 'open_scope' no
  mesmo ponto, não há conflito reduce/reduce (ao contrário da
  versão antiga, que mantinha dois caminhos distintos para os
  parâmetros: 'param_list' direto para protótipos e
  'function_scope function_params' para definições). Esse conflito
  fazia o Jison rejeitar 'int f();' e 'int f(int a){...}').
*/
open_scope
  : /* vazio */ {
      analyzer.openScope("function");
    }
  ;

/*
  Cauda da função: distingue protótipo (';') de definição
  ('{ ... }') por um único token de lookahead — totalmente
  compatível com LALR(1).
*/
func_tail
  : ';' {
      $$ = { proto: true, body: [] };
    }
  | '{' statement_list '}' {
      $$ = { proto: false, body: $2 };
    }
  ;

function_definition
  /*
    Funções e protótipos com lista de parâmetros (que pode ser
    vazia, cobrindo 'int f()'). Os parâmetros se auto-declaram em
    'param' porque 'open_scope' já abriu o escopo da função.
  */
  : type ID '(' open_scope param_list ')' func_tail {
      analyzer.closeScope();
      analyzer.declareVar($1, $2, null, 'func');
      $$ = {
        type: $7.proto ? 'func_proto' : 'func_def',
        retType: $1, name: $2, params: $5, body: $7.body
      };
    }

  | type '*' ID '(' open_scope param_list ')' func_tail {
      analyzer.closeScope();
      analyzer.declareVar($1 + '*', $3, null, 'func');
      $$ = {
        type: $8.proto ? 'func_proto' : 'func_def',
        retType: $1 + '*', name: $3, params: $6, body: $8.body
      };
    }

  /* Funções e protótipos com 'void' explícito */
  | type ID '(' open_scope VOID ')' func_tail {
      analyzer.closeScope();
      analyzer.declareVar($1, $2, null, 'func');
      $$ = {
        type: $7.proto ? 'func_proto' : 'func_def',
        retType: $1, name: $2, params: [], body: $7.body
      };
    }

  | type '*' ID '(' open_scope VOID ')' func_tail {
      analyzer.closeScope();
      analyzer.declareVar($1 + '*', $3, null, 'func');
      $$ = {
        type: $8.proto ? 'func_proto' : 'func_def',
        retType: $1 + '*', name: $3, params: [], body: $8.body
      };
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
  | STRUCT ID ID '=' '{' struct_member_values '}' ';' {
      $$ = { type: 'struct_def', name: $2, instance: $3, values: $6 };
    }
  | STRUCT ID '{' struct_member_list '}' declarator_list ';' {
      $$ = { type: 'struct_def', name: $2, members: $4, vars: $6 };
    }
  | STRUCT '{' struct_member_list '}' declarator_list ';' {
      $$ = { type: 'struct_def', name: null, members: $3, vars: $5 };
    }
  ;

struct_member_values
  : struct_member_v                         { $$ = [$1]; }
  | struct_member_values ',' struct_member_v { $$ = $1.concat([$3]); }
  ;

struct_member_v
  : NUMBER { $$ = { value: $1 }; }
  | STRING { $$ = { value: $1 }; }
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
  : /* vazio */                           { $$ = []; }
  | struct_member_list struct_member      { $$ = $1.concat([$2]); }
  ;

struct_member
  : type declarator_list ';' {
      $$ = { type: 'member', varType: $1, declarators: $2 };
    }
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
  : enum_member                           { $$ = [$1]; }
  | enum_member_list ',' enum_member      { $$ = $1.concat([$3]); }
  | enum_member_list ','                  { $$ = $1; }
  ;

enum_member
  : ID              { $$ = { name: $1, value: null }; }
  | ID '=' expression { $$ = { name: $1, value: $3 }; }
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
  Ação semântica: gera labels e saltos condicionais
══════════════════════════════════════════════════════════════
*/

if_statement
  : IF '(' expression ')' statement %prec LOWER_THAN_ELSE {
      var condRes = analyzer.analyzeExpr($3);
      var labelEnd = analyzer.codeGen.newLabel();
      analyzer.codeGen.emitIfFalse(condRes.place, labelEnd);
      /* O corpo já foi gerado (statement é processado antes desta ação
         em LALR, mas a expressão-condição é avaliada antes do corpo) */
      analyzer.codeGen.emitLabel(labelEnd);
      $$ = { type: 'if', condition: $3, then: $5 };
    }
  | IF '(' expression ')' statement ELSE statement {
      var condRes2 = analyzer.analyzeExpr($3);
      var labelElse = analyzer.codeGen.newLabel();
      var labelEnd2 = analyzer.codeGen.newLabel();
      analyzer.codeGen.emitIfFalse(condRes2.place, labelElse);
      analyzer.codeGen.emitGoto(labelEnd2);
      analyzer.codeGen.emitLabel(labelElse);
      analyzer.codeGen.emitLabel(labelEnd2);
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
      var condRes = analyzer.analyzeExpr($3);
      $$ = { type: 'switch', condition: $3, cases: $6 };
    }
  ;

case_list
  : /* vazio */             { $$ = []; }
  | case_list case_clause   { $$ = $1.concat([$2]); }
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
  Para while/do-while/for, geramos os labels de controle.
  A limitação do LALR impede ações intermediárias, então
  usamos produções auxiliares (while_head, for_head) para
  emitir os labels antes de processar o corpo.
══════════════════════════════════════════════════════════════
*/

/* Produção auxiliar: emite o label de início do while e avalia condição */
while_head
  : WHILE '(' expression ')' {
      var labelStart = analyzer.codeGen.newLabel();
      var labelEnd   = analyzer.codeGen.newLabel();
      analyzer.codeGen.emitLabel(labelStart);
      var condRes = analyzer.analyzeExpr($3);
      analyzer.codeGen.emitIfFalse(condRes.place, labelEnd);
      $$ = { cond: $3, labelStart: labelStart, labelEnd: labelEnd };
    }
  ;

while_statement
  : while_head statement {
      analyzer.codeGen.emitGoto($1.labelStart);
      analyzer.codeGen.emitLabel($1.labelEnd);
      $$ = { type: 'while', condition: $1.cond, body: $2 };
    }
  ;

do_while_statement
  : DO statement WHILE '(' expression ')' ';' {
      var res = analyzer.analyzeExpr($5);
      $$ = { type: 'do_while', body: $2, condition: $5 };
    }
  ;

for_statement
  : FOR '(' for_init ';' for_cond ';' for_update ')' statement {
      if ($5) {
        var condRes = analyzer.analyzeExpr($5);
      }
      $$ = { type: 'for', init: $3, condition: $5, update: $7, body: $9 };
    }
  ;

for_init
  : /* vazio */           { $$ = null; }
  | type declarator_list {
      for (const decl of $2) {
        analyzer.declareVar($1, decl.name, null, 'var');
        if (decl.init) {
          var res = analyzer.analyzeExpr(decl.init);
          if (res && res.place) {
            analyzer.codeGen.emit(decl.name, res.place, null, null);
          }
        }
      }
      $$ = { type: 'declaration', varType: $1, declarators: $2 };
    }
  | for_expression_list   { $$ = $1; }
  ;

for_cond
  : /* vazio */  { $$ = null; }
  | expression   { $$ = $1; }
  ;

for_update
  : /* vazio */        { $$ = null; }
  | for_expression_list { $$ = $1; }
  ;

for_expression_list
  : expression                          { $$ = $1; }
  | for_expression_list ',' expression  {
      $$ = { kind: 'binop', value: ',', left: $1, right: $3 };
    }
  ;

/*
══════════════════════════════════════════════════════════════
  COMANDOS DE CONTROLE
══════════════════════════════════════════════════════════════
*/

return_statement
  : RETURN ';' {
      analyzer.codeGen.emitReturn(null);
      $$ = { type: 'return', value: null };
    }
  | RETURN expression ';' {
      var res = analyzer.analyzeExpr($2);
      analyzer.codeGen.emitReturn(res.place);
      $$ = { type: 'return', value: $2 };
    }
  ;

break_statement
  : BREAK ';' {
      $$ = { type: 'break' };
    }
  ;

continue_statement
  : CONTINUE ';' {
      $$ = { type: 'continue' };
    }
  ;

goto_statement
  : GOTO ID ';' {
      analyzer.codeGen.emitGoto($2);
      $$ = { type: 'goto', label: $2 };
    }
  ;

label_statement
  : ID ':' statement {
      analyzer.codeGen.emitLabel($1);
      $$ = { type: 'label', name: $1, body: $3 };
    }
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
  : ID                        { $$ = $1; }
  | include_path '.' ID       { $$ = $1 + '.' + $3; }
  | include_path '/' ID       { $$ = $1 + '/' + $3; }
  ;

/*
══════════════════════════════════════════════════════════════
  EXPRESSÕES
  Todas as produções constroem nós ExprNode.
  A análise semântica e a geração de código são acionadas
  em expression_statement (para expressões como comandos)
  e nos pontos que precisam do valor (if, while, return…).
══════════════════════════════════════════════════════════════
*/

arg_list
  : /* vazio */               { $$ = []; }
  | expression                { $$ = [$1]; }
  | arg_list ',' expression   { $$ = $1.concat([$3]); }
  ;

expression
  /* ── Literais ── */
  : NUMBER    { $$ = leaf('num', $1); }
  | STRING    { $$ = leaf('str', $1); }
  | CHAR_LIT  { $$ = leaf('char', $1); }

  /* ── Identificador ── */
  | ID        { $$ = leaf('id', $1); }

  /* ── Chamada de função ── */
  | ID '(' arg_list ')' {
      var n = new ExprNode('call', $1, null, null, $3);
      $$ = n;
    }

  /* ── Acesso a array ── */
  | expression '[' expression ']' {
      $$ = new ExprNode('index', null, $1, $3, null);
    }

  /* ── Acesso a membros ── */
  | expression '.' ID {
      $$ = new ExprNode('member', $3, $1, null, null);
    }
  | expression ARROW ID {
      $$ = new ExprNode('arrow', $3, $1, null, null);
    }

  /* ── Casts ── */
  | '(' type ')' expression %prec UMINUS {
      $$ = new ExprNode('cast', $2, $4, null, null);
    }
  | '(' type '*' ')' expression %prec UMINUS {
      $$ = new ExprNode('cast', $2 + '*', $5, null, null);
    }
  | '(' type '*' '*' ')' expression %prec UMINUS {
      $$ = new ExprNode('cast', $2 + '**', $6, null, null);
    }

  /* ── Aritméticos ── */
  | expression '+' expression   { $$ = binop('+', $1, $3); }
  | expression '-' expression   { $$ = binop('-', $1, $3); }
  | expression '*' expression   { $$ = binop('*', $1, $3); }
  | expression '/' expression   { $$ = binop('/', $1, $3); }
  | expression '%' expression   { $$ = binop('%', $1, $3); }

  /* ── Bit a bit ── */
  | expression LSHIFT expression  { $$ = binop('<<', $1, $3); }
  | expression RSHIFT expression  { $$ = binop('>>', $1, $3); }
  | expression '|' expression     { $$ = binop('|',  $1, $3); }
  | expression '^' expression     { $$ = binop('^',  $1, $3); }
  | expression '&' expression     { $$ = binop('&',  $1, $3); }

  /* ── Relacionais ── */
  | expression EQ  expression   { $$ = binop('==', $1, $3); }
  | expression NEQ expression   { $$ = binop('!=', $1, $3); }
  | expression LT  expression   { $$ = binop('<',  $1, $3); }
  | expression GT  expression   { $$ = binop('>',  $1, $3); }
  | expression LE  expression   { $$ = binop('<=', $1, $3); }
  | expression GE  expression   { $$ = binop('>=', $1, $3); }

  /* ── Lógicos ── */
  | expression AND expression   { $$ = binop('&&', $1, $3); }
  | expression OR  expression   { $$ = binop('||', $1, $3); }
  | NOT expression              { $$ = unary('!', $2); }

  /* ── Unários ── */
  | '-' expression %prec UMINUS { $$ = unary('-', $2); }
  | '~' expression              { $$ = unary('~', $2); }
  | '(' expression ')'          { $$ = $2; }

  /* ── Incremento/decremento ── */
  | expression INC %prec INC  { $$ = new ExprNode('post++', null, $1, null, null); }
  | expression DEC %prec DEC  { $$ = new ExprNode('post--', null, $1, null, null); }
  | INC expression             { $$ = new ExprNode('pre++',  null, $2, null, null); }
  | DEC expression             { $$ = new ExprNode('pre--',  null, $2, null, null); }

  /* ── Ponteiros ── */
  | '&' expression %prec ADDR  { $$ = new ExprNode('address_of', null, $2, null, null); }
  | '*' expression %prec DEREF { $$ = new ExprNode('deref',      null, $2, null, null); }

  /* ── Atribuições ── */
  | expression '='           expression { $$ = assign('=',   $1, $3); }
  | expression ADD_ASSIGN    expression { $$ = assign('+=',  $1, $3); }
  | expression SUB_ASSIGN    expression { $$ = assign('-=',  $1, $3); }
  | expression MUL_ASSIGN    expression { $$ = assign('*=',  $1, $3); }
  | expression DIV_ASSIGN    expression { $$ = assign('/=',  $1, $3); }
  | expression MOD_ASSIGN    expression { $$ = assign('%=',  $1, $3); }
  | expression AND_ASSIGN    expression { $$ = assign('&=',  $1, $3); }
  | expression OR_ASSIGN     expression { $$ = assign('|=',  $1, $3); }
  | expression XOR_ASSIGN    expression { $$ = assign('^=',  $1, $3); }
  | expression LSHIFT_ASSIGN expression { $$ = assign('<<=', $1, $3); }
  | expression RSHIFT_ASSIGN expression { $$ = assign('>>=', $1, $3); }

  /* ── Sizeof ── */
  | SIZEOF '(' type ')' {
      $$ = new ExprNode('sizeof', $3, null, null, null);
    }
  | SIZEOF '(' type '*' ')' {
      $$ = new ExprNode('sizeof', $3 + '*', null, null, null);
    }
  | SIZEOF '(' expression ')' {
      $$ = new ExprNode('sizeof', null, $3, null, null);
    }
  ;

/*
══════════════════════════════════════════════════════════════
  BLOCO
  open_block e close_block gerenciam escopo de bloco.
  A produção 'block' sem escopo próprio é mantida para
  compatibilidade com os locais onde não há controle de escopo
  explícito (ex.: corpo de funções via func_tail).
══════════════════════════════════════════════════════════════
*/

open_block
  : '{' {
      analyzer.openScope("block");
    }
  ;

close_block
  : '}' {
      analyzer.closeScope();
    }
  ;
