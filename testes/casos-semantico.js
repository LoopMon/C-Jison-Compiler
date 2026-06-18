/*
  Casos de teste do ANALISADOR SEMÂNTICO.

  Todos os casos aqui são SINTATICAMENTE válidos.
  Verifica regras semânticas:
    - Variáveis declaradas antes do uso
    - Redeclaração no mesmo escopo
    - Compatibilidade de tipos
    - Uso correto de funções (parâmetros, retorno)
*/

module.exports = [
  /* ───────── Casos que DEVEM ser aceitos (semântica válida) ───────── */
  {
    nome: 'Declaração e uso correto de variável',
    esperado: 'aceita',
    codigo: `int main() {
  int n1 = 12;
  int n2 = n1;
}`,
  },
  {
    nome: 'Função com protótipo e definição',
    esperado: 'aceita',
    codigo: `int somar();

int main() {
  int n1 = 12;
}`,
  },
  {
    nome: 'Função com parâmetros usados no corpo',
    esperado: 'aceita',
    codigo: `int soma(int a, int b) {
  int resultado = a;
}

int main() {
  int x = 10;
}`,
  },
  {
    nome: 'Múltiplas variáveis no mesmo escopo',
    esperado: 'aceita',
    codigo: `int main() {
  int a = 1;
  int b = 2;
  int c = a;
}`,
  },

  /* ───────── Casos que DEVEM ser rejeitados (erro semântico) ───────── */
  {
    nome: 'Variável não declarada',
    esperado: 'rejeita',
    codigo: `int main() {
  int n1 = n2;
}`,
  },
  {
    nome: 'Uso de variável antes da declaração',
    esperado: 'rejeita',
    codigo: `int main() {
  int x = y;
  int y = 10;
}`,
  },
  {
    nome: 'Redeclaração no mesmo escopo',
    esperado: 'rejeita',
    codigo: `int main() {
  int x = 1;
  int x = 2;
}`,
  },
];
