/*
  Runner de testes da gramática Jison.

  Uso:
    node testes/run.js [arquivo.jison]

  Sem argumento, usa 'analisador-semantico-c.jison'.

  Como funciona:
    1. Gera o parser a partir da gramática (uma vez).
    2. Para cada caso, recarrega o parser do zero (o analisador
       semântico guarda estado global, então isolamos cada caso).
    3. Compara o resultado (aceita/rejeita) com o esperado.
*/

const fs = require('fs');
const path = require('path');

const RAIZ = path.join(__dirname, '..');
const gramaticaArg = process.argv[2] || 'analisador-semantico-c.jison';
const caminhoGramatica = path.join(RAIZ, gramaticaArg);

if (!fs.existsSync(caminhoGramatica)) {
  console.error(`Gramática não encontrada: ${caminhoGramatica}`);
  process.exit(2);
}

let jison;
try {
  jison = require('jison');
} catch (e) {
  console.error("Jison não instalado. Rode 'npm install' antes dos testes.");
  process.exit(2);
}

// Silencia toda a saída (tabelas de símbolos, código gerado, relatório de
// conflitos do Jison, etc.). Mexe direto no stdout/stderr porque o Jison
// captura a função de impressão no carregamento do módulo.
function comSaidaSilenciada(fn) {
  const { log, clear, error, warn } = console;
  const out = process.stdout.write;
  const err = process.stderr.write;
  const noop = () => {};
  console.log = console.clear = console.error = console.warn = noop;
  process.stdout.write = noop;
  process.stderr.write = noop;
  try {
    return fn();
  } finally {
    Object.assign(console, { log, clear, error, warn });
    process.stdout.write = out;
    process.stderr.write = err;
  }
}

// 1. Gera o código-fonte do parser a partir da gramática.
const fonteGramatica = fs.readFileSync(caminhoGramatica, 'utf8');
const parserGerado = comSaidaSilenciada(() =>
  new jison.Parser(fonteGramatica).generate()
);

// 2. Escreve o parser gerado em um arquivo temporário (ignorado pelo git).
const dirGerado = path.join(__dirname, '.gerado');
if (!fs.existsSync(dirGerado)) fs.mkdirSync(dirGerado);
const caminhoParser = path.join(dirGerado, 'parser.js');
fs.writeFileSync(caminhoParser, parserGerado);

const casos = require('./casos.js');

// Recarrega o parser do zero para isolar o estado global entre casos.
function parserNovo() {
  delete require.cache[require.resolve(caminhoParser)];
  return require(caminhoParser).parser;
}

function analisa(codigo) {
  return comSaidaSilenciada(() => {
    try {
      parserNovo().parse(codigo);
      return { aceito: true };
    } catch (e) {
      return { aceito: false, erro: String((e && e.message) || e).split('\n')[0] };
    }
  });
}

console.log(`\nTestando gramática: ${gramaticaArg}\n${'─'.repeat(50)}`);

let passou = 0;
let falhou = 0;

for (const caso of casos) {
  const r = analisa(caso.codigo);
  const aceitoEsperado = caso.esperado === 'aceita';
  const ok = r.aceito === aceitoEsperado;

  if (ok) {
    passou++;
    console.log(`  OK    [${caso.esperado}] ${caso.nome}`);
  } else {
    falhou++;
    const obtido = r.aceito ? 'aceitou' : `rejeitou (${r.erro})`;
    console.log(`  FALHA [${caso.esperado}] ${caso.nome}  ->  parser ${obtido}`);
  }
}

console.log(`${'─'.repeat(50)}`);
console.log(`Total: ${casos.length} | Passaram: ${passou} | Falharam: ${falhou}\n`);

process.exit(falhou ? 1 : 0);
