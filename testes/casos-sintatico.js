/*
  Casos de teste do ANALISADOR SINTÁTICO.

  Verifica apenas a ESTRUTURA GRAMATICAL do código:
    - Tokens na ordem correta
    - Delimitadores balanceados (parênteses, chaves, colchetes)
    - Construções válidas da linguagem

  NÃO verifica semântica (variáveis declaradas, tipos, etc.).
*/

module.exports = [
  /* ───────── Casos que DEVEM ser aceitos (sintaxe válida) ───────── */
  {
    nome: 'Protótipo sem parâmetros',
    esperado: 'aceita',
    codigo: `int somar();

int main() {
  int n1 = 12;
}`,
  },
  {
    nome: 'Definição sem parâmetros',
    esperado: 'aceita',
    codigo: `int soma() {
  printf('as');
}

int main() {
  int n1 = 12;
}`,
  },
  {
    nome: 'Protótipo com parâmetros',
    esperado: 'aceita',
    codigo: `int soma(int a, float b, char s3);

int main() {
  int n1 = 12;
}`,
  },
  {
    nome: 'Definição com parâmetros',
    esperado: 'aceita',
    codigo: `int soma(int a, int b) {
  printf('as');
}

int main() {
  int n1 = 12;
}`,
  },
  {
    nome: 'Função void e retorno por ponteiro',
    esperado: 'aceita',
    codigo: `void imprime(void);

int* aloca(int n) {
  int x = n;
}`,
  },
  {
    nome: 'Uso de identificador não declarado (válido sintaticamente)',
    esperado: 'aceita',
    codigo: `int main() {
  int n1 = n2;
}`,
  },

  /* ───────── Casos que DEVEM ser rejeitados (erro de sintaxe) ───────── */
  {
    nome: 'Declaração sem identificador',
    esperado: 'rejeita',
    codigo: `int ;`,
  },
  {
    nome: 'Parâmetro sem nome',
    esperado: 'rejeita',
    codigo: `int soma(int, int) {
  int x = 1;
}`,
  },
  {
    nome: 'Chave não fechada',
    esperado: 'rejeita',
    codigo: `int main() {
  int n1 = 12;`,
  },
  {
    nome: 'Ponto e vírgula ausente',
    esperado: 'rejeita',
    codigo: `int main() {
  int n1 = 12
}`,
  },
  {
    nome: 'Parêntese não fechado na chamada',
    esperado: 'rejeita',
    codigo: `int main() {
  printf("hello";
}`,
  },
  {
    nome: 'Dois tipos seguidos',
    esperado: 'rejeita',
    codigo: `int float x;`,
  },
];
