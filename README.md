# Analisador Léxico e Sintático para Linguagem C

## 📋 Descrição

Este projeto implementa um **analisador léxico** e um **analisador sintático** para a linguagem C, utilizando **Jison** (gerador de analisadores para JavaScript). Os analisadores são capazes de reconhecer tokens e estruturas sintáticas da linguagem C, servindo como base para entender o processo de compilação e análise de código.

## 📁 Estrutura do Projeto

```
.
├── analisador-lexico-c.jison      # Analisador léxico - reconhece tokens da linguagem C
├── analisador-sintatico-c.jison   # Analisador sintático - reconhece instruções completas
└── arquivos/                      # Diretório para arquivos de teste em C
        └── (exemplos de código C para testar os analisadores)
```

## 🔍 Funcionalidades

### Analisador Léxico (`analisador-lexico-c.jison`)

- Reconhece todas as **palavras reservadas** da linguagem C
- Identifica **tokens** como:
  - Palavras-chave (`int`, `char`, `if`, `while`, `return`, etc.)
  - Operadores (`+`, `-`, `*`, `/`, `=`, `==`, etc.)
  - Símbolos (`;`, `,`, `(`, `)`, `{`, `}`, etc.)
  - Identificadores e números
- Exibe cada token reconhecido

### Analisador Sintático (`analisador-sintatico-c.jison`)

- Realiza a **análise sintática** de instruções completas
- Reconhece estruturas como:
  - Declarações de variáveis (`int var;`)
  - Declarações de structs
  - Expressões e comandos
- Valida a **estrutura gramatical** do código

## 🚀 Como Testar

Você pode testar os analisadores online usando o **Jison Debugger**:

1. Acesse: https://nolanlawson.github.io/jison-debugger/
2. Copie o conteúdo do arquivo `.jison` desejado para a seção de **Grammar**
3. Digite ou cole um código C de exemplo na seção de **Input**
4. Clique em **Parse** e veja o resultado

### Exemplo de código C para teste:

```c
int valor = 0;
```

## 📝 Exemplos de Saída

### Analisador Léxico

```
[
  {
    "token": "int",
    "lexeme": "int"
  },
  {
    "token": "valor",
    "lexeme": "valor"
  },
  {
    "token": "=",
    "lexeme": "="
  },
  {
    "token": "0",
    "lexeme": "0"
  },
  {
    "token": ";",
    "lexeme": ";"
  }
]
```

### Analisador Sintático

```
[
  {
    "type": "declaration",
    "varType": "int",
    "declarators": [
      {
        "type": "variable",
        "name": "valor",
        "init": {
          "type": "number",
          "value": "0"
        }
      }
    ]
  }
]
```

## 🔧 Diferenças entre os Analisadores

| Característica       | Analisador Léxico   | Analisador Sintático             |
| -------------------- | ------------------- | -------------------------------- |
| **Nível de análise** | Tokenização         | Estrutura gramatical             |
| **Reconhece**        | Tokens individuais  | Instruções completas             |
| **Saída**            | Lista de tokens     | Árvore sintática                 |
| **Exemplo**          | `"int"` → token INT | `"int var;"` → declaração válida |

## 📚 Referências

- [Jison GitHub Repository](https://github.com/zaach/jison)
- [Jison Debugger Online](https://nolanlawson.github.io/jison-debugger/)

## 👨‍💻 Autores

- **João Lucas da Costa** [LoopMon](https://github.com/LoopMon)
- **Fernando Teixeira** [oteixeiras](https://github.com/oteixeiras)

## 📄 Licença

Este projeto está sob licença livre para uso educacional.
