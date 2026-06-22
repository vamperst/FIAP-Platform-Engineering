# Exercício 01.A - Count na prática: filas SQS para a Vortex

> **Mês 1 na Vortex Mobility — sua vez de praticar.**
> O time de pagamentos da Vortex vai processar transações de forma assíncrona e precisa de **várias filas SQS** idênticas (uma por tipo de evento). Diego te passa a tarefa:
>
> > *— "Você já viu `count` na demo da frota de servidores. Agora aplica sozinho: quero criar N filas SQS parametrizando o número, sem copiar e colar o recurso. Me mostra o console com as filas criadas e me diz quantas você subiu."*

Os comandos `bash` rodam **no terminal do Codespaces**. A verificação é feita **no console da AWS** (SQS).

> [!WARNING]
> **Pré-requisitos obrigatórios antes de começar:**
>
> - [ ] [Lab 01.3 — Count](../../demos/03-Count/README.md) concluído (você entende `variable` + `count`)
> - [ ] Credenciais AWS do Academy atualizadas no Codespaces
> - [ ] Terraform instalado (`terraform -version` → 1.x)
>
> **Valide rapidamente:**
>
> ```bash
> aws sts get-caller-identity && terraform -version
> ```
>
> **O que você vai fazer:** escrever do zero um arquivo Terraform que cria N filas SQS, parametrizando a quantidade com `variable` + `count`. **Tempo estimado: ~25 min.**

## Principais pontos de aprendizagem

- escrever HCL do zero a partir da documentação oficial
- parametrizar a quantidade de recursos com `variable` + `count`
- usar `count.index` para diferenciar os nomes das filas

## O que você terá ao final

Um arquivo Terraform que sobe a quantidade desejada de filas SQS mudando só uma variável — e um pequeno registro de decisão (ADR) defendendo sua escolha.

> [!TIP]
> Este é um exercício **autoral**: você escreve o código. As dicas apontam a documentação certa; o HCL é seu.

## Mapa do exercício

| Parte | O que você faz | Passos | Tempo |
|-------|----------------|--------|-------|
| [Parte 1](#parte-1---escrevendo-o-código) | Escrevendo o código das filas | [1](#passo-1) · [2](#passo-2) · [3](#passo-3) · [4](#passo-4) | ~18 min |
| [Parte 2](#parte-2---validando-e-limpando) | Validando, registrando a decisão e limpando | [5](#passo-5) · [6](#passo-6) · [7](#passo-7) | ~7 min |

---

## Parte 1 - Escrevendo o código

### Resultado esperado desta parte

Um arquivo `.tf` que cria N filas SQS, onde N é uma variável.

---

<a id="passo-1"></a>

**1.** Entre na pasta do exercício:

```bash
cd /workspaces/FIAP-Platform-Engineering/01-Terraform/exercicios/count
```

---

<a id="passo-2"></a>

**2.** Crie um arquivo Terraform que defina o provider AWS na região `us-east-1` e fixe as versões. Modele pelo `versions.tf`/`provider.tf` que você viu nas demos:

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

---

<a id="passo-3"></a>

**3.** Crie uma `variable` para controlar quantas filas criar e o recurso de fila SQS usando `count`. Consulte a [documentação oficial do recurso `aws_sqs_queue`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue). Use **apenas** os atributos `name` e `tags`.

<details>
<summary><b>💡 Clique para entender: o caminho (sem a resposta pronta)</b></summary>
<blockquote>

Este é um exercício autoral — o HCL é **seu**. Use estas pistas para chegar lá sozinho:

- Defina uma **`variable`** (ex.: `queue_count`) com um `default` numérico para controlar quantas filas criar.
- No `resource "aws_sqs_queue"`, aplique **`count`** apontando para essa variável — é o **mesmo padrão** do `count` que você usou na frota de EC2 da demo 01.3 (volte lá se precisar relembrar a forma).
- Para os nomes não colidirem, diferencie cada fila pelo **`count.index`** (0, 1, 2...). A função `format()` ajuda a numerar (ex.: `...-001`, `-002`).
- Use **apenas** os atributos `name` e `tags`, como pede o enunciado.

Documentação oficial: [aws_sqs_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) · [count](https://developer.hashicorp.com/terraform/language/meta-arguments/count) · [função format](https://developer.hashicorp.com/terraform/language/functions/format)

</blockquote>
</details>

---

<a id="passo-4"></a>

**4.** Inicialize e aplique:

```bash
terraform init && terraform apply -auto-approve
```

### Checkpoint

Se chegou até aqui:

- o `apply` terminou com sucesso
- o Terraform reporta N filas criadas (o N da sua variável)

---

## Parte 2 - Validando e limpando

### Resultado esperado desta parte

As filas confirmadas no console, sua decisão registrada e tudo destruído.

---

<a id="passo-5"></a>

**5.** No [console do SQS](https://us-east-1.console.aws.amazon.com/sqs/v3/home?region=us-east-1#/queues), confirme que as filas foram criadas. Deve ficar parecido com:

![](img/sqs-to-be.png)

> [!TIP]
> Para tirar o print no macOS: `Cmd+Shift+4`. No Windows: `Print Screen` ou ferramenta de captura.

---

<a id="passo-6"></a>

**6.** Registre sua decisão num arquivo curto `DECISION.md` nesta pasta (estilo ADR). Responda, em 1-2 linhas cada:

- **Contexto:** por que filas SQS idênticas em vez de uma só?
- **Decisão:** por que `count` e não `for_each`? (dica: as filas são idênticas exceto pelo índice)
- **Quantas filas você subiu** e como mudaria esse número
- **Pergunta para validar com o stakeholder:** o que você confirmaria com o time de pagamentos antes de ir para produção (ex.: visibility timeout, dead-letter queue)?

---

<a id="passo-7"></a>

**7.** Destrua todas as filas criadas:

```bash
terraform destroy -auto-approve
```

### Checkpoint

Se chegou até aqui:

- você confirmou as filas no console
- registrou a decisão em `DECISION.md`
- destruiu todas as filas

---

## Conclusão

Você aplicou `count` sozinho, do zero, parametrizando a quantidade de recursos — o mesmo padrão da frota de servidores, agora em filas. Mais importante: registrou **por que** escolheu essa abordagem, hábito que separa engenheiro júnior de sênior.

> [!CAUTION]
> **Custo:** SQS é praticamente grátis no volume deste exercício, mas rode `terraform destroy -auto-approve` mesmo assim — higiene de laboratório. Confirme no console que as filas sumiram.

---

<details>
<summary><b>💡 Glossário rápido</b></summary>
<blockquote>

| Termo | O que é |
|-------|---------|
| **SQS** | Simple Queue Service — serviço de filas gerenciadas da AWS para processamento assíncrono. |
| **`count`** | Meta-argumento que cria N cópias indexadas de um recurso. |
| **`count.index`** | Índice da cópia atual (0, 1, 2...), usado para diferenciar nomes. |
| **`for_each`** | Alternativa ao `count` quando os recursos diferem por chave (mapa/set), não só por índice. |
| **ADR** | Architecture Decision Record — documento curto que registra uma decisão técnica e seu porquê. |

</blockquote>
</details>

<details>
<summary><b>💡 Como pedir ajuda se travou</b></summary>
<blockquote>

Antes de pedir ajuda, colete: (1) em que passo está, (2) erro literal do terminal, (3) o conteúdo do seu `.tf`, (4) o que já tentou.

Canais (em ordem de prioridade):

- **Issues do repositório**: [github.com/vamperst/FIAP-Platform-Engineering/issues](https://github.com/vamperst/FIAP-Platform-Engineering/issues)
- **E-mail do professor**: `Rafael@rfbarbosa.com`

</blockquote>
</details>
