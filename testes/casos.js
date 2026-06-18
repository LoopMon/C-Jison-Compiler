/*
  Casos de teste da gramática.

  Cada caso tem:
    - nome:     descrição curta
    - esperado: 'aceita' (deve parsear sem erro) ou 'rejeita' (deve dar erro de sintaxe)
    - codigo:   o trecho de código C a ser analisado
*/

module.exports = [
  /* ───────── Definição/declaração de funções e variáveis ───────── */
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

  /* ───────── Casos que DEVEM ser rejeitados ───────── */
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
    nome: 'Variável não declarada',
    esperado: 'rejeita',
    codigo: `int main() {
  int n1 = n2;
}`,
  },
];
