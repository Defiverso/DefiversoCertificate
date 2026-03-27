# DefiversoCertificate 🎓

[![Tests](https://github.com/defiverso/DefiversoCertificate/actions/workflows/test.yml/badge.svg)](https://github.com/defiverso/DefiversoCertificate/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://book.getfoundry.sh/)

Uma infraestrutura de certificação on-chain robusta, segura e **100% compatível com a privacidade**, projetada para o ecossistema Web3 do **Defiverso**.

## Destaques Técnicos

- **Zero-Exposure PII**: Nenhum dado pessoal (nome, Octacode, etc.) toca o blockchain em texto claro durante a assinatura. Usamos um modelo de "Ancoragem de Hash" off-chain.
- **Segurança Reforçada**: Validação rigorosa de endereços e sistema de pausa de emergência.
- **Gas Optimized**: Uso intensivo de `Custom Errors` e `Unchecked Increments` para minimizar custos de transação.

## Funcionalidades

- **Gestão de Professores**: O `owner` controla quem pode assinar certificados.
- **Assinatura em Lote**: Emita múltiplos certificados em uma única transação usando hashes pré-calculados.
- **Verificação Pública**: Qualquer pessoa pode validar um certificado se possuir os dados originais (**Octacode + Nome + Curso**).

## 🛠️ Guia de Desenvolvimento

### Pré-requisitos
- [Foundry / Forge](https://book.getfoundry.sh/getting-started/installation)

### Instalação e Testes

```bash
# Compilar
forge build

# Rodar testes com relatório de cobertura (100% atingido)
forge test
forge coverage
```

## 📝 Integração Off-chain (Exemplo Ethers.js v6)

Para garantir a privacidade total, o hash deve ser gerado separadamente.

```javascript
const { ethers } = require("ethers");

/**
 * Gera o hash compatível com o contrato DefiversoCertificate
 */
function generateHash(octacode, name, course) {
  const abiCoder = new ethers.AbiCoder();
  const encodedData = abiCoder.encode(
    ["string", "string", "string"],
    [octacode, name, course]
  );
  return ethers.keccak256(encodedData);
}

const hash = generateHash("OCTA0001", "John Doe", "Formação Defiverso");

// O professor então assina no contrato:
// await contract.signCertificates([hash], [studentWallet], "Formação Defiverso");
```

### Verificando no Frontend

```javascript
// Retorna true se os dados forem válidos
const isValid = await contract.verify(octacode, name, course);
```

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---
Desenvolvido com 👽 pelo time **Defiverso**.
