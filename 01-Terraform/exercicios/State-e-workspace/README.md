# Exercício 01.B - State remoto e Workspaces: EC2 por ambiente na Vortex

> **Fim do Mês 1 na Vortex Mobility — sua vez de praticar.**
> Helena quer ver você juntar as duas últimas peças sozinho: estado remoto + workspaces, criando EC2 que sabem em qual ambiente nasceram.
>
> > *— "Me cria duas EC2 por ambiente, com a AMI descoberta dinamicamente (nada de ID fixo que expira), o nome carregando o workspace (`ec2-dev`, `ec2-prod`), e o estado no nosso bucket S3. Quero provar que dev e prod não se misturam."*

Os comandos `bash` rodam **no terminal do Codespaces**. A verificação é feita **no console da AWS** (EC2 / S3) e no terminal.

> [!WARNING]
> **Pré-requisitos obrigatórios antes de começar:**
>
> - [ ] [Lab 01.4 — State remoto](../../demos/04-State/README.md) e [Lab 01.5 — Workspaces](../../demos/05-Workspaces/README.md) concluídos
> - [ ] Credenciais AWS do Academy atualizadas no Codespaces
> - [ ] Bucket S3 do setup (descubra com `aws s3 ls`)
>
> **Valide rapidamente:**
>
> ```bash
> aws sts get-caller-identity && aws s3 ls
> ```
>
> **O que você vai fazer:** escrever do zero um projeto que cria 2 EC2 por workspace, com AMI dinâmica e estado remoto no S3, e provar o isolamento dev/prod. **Tempo estimado: ~35 min.**

## Principais pontos de aprendizagem

- escrever HCL do zero a partir da documentação oficial
- usar um `data source` de AMI dinâmica (Amazon Linux 2)
- interpolar `terraform.workspace` no nome dos recursos
- configurar backend S3 e provar que o estado remoto funciona

## O que você terá ao final

Um projeto Terraform que sobe 2 EC2 por ambiente, com nome carregando o workspace e estado no S3 — mais um registro de decisão (ADR) defendendo workspaces vs. diretórios separados.

> [!TIP]
> Exercício **autoral**: você escreve o código. As dicas apontam a documentação; o HCL é seu.

## Mapa do exercício

| Parte | O que você faz | Passos | Tempo |
|-------|----------------|--------|-------|
| [Parte 1](#parte-1---escrevendo-o-projeto) | Escrevendo o projeto (AMI + EC2 + backend) | [1](#passo-1) · [2](#passo-2) · [3](#passo-3) · [4](#passo-4) | ~18 min |
| [Parte 2](#parte-2---workspaces-validação-e-limpeza) | Workspaces, validação do estado remoto e limpeza | [5](#passo-5) · [6](#passo-6) · [7](#passo-7) · [8](#passo-8) · [9](#passo-9) | ~17 min |

---

## Parte 1 - Escrevendo o projeto

### Resultado esperado desta parte

Arquivos `.tf` que definem: provider, data source de AMI, 2 EC2 com nome por workspace, e backend S3.

---

<a id="passo-1"></a>

**1.** Entre na pasta do exercício:

```bash
cd /workspaces/FIAP-Platform-Engineering/01-Terraform/exercicios/State-e-workspace
```

---

<a id="passo-2"></a>

**2.** Crie o `versions.tf`/`provider.tf` (provider `aws ~> 6.0`, região `us-east-1`) e um **data source de AMI** que busque a Amazon Linux 2 mais recente. Consulte a [documentação do data source `aws_ami`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami). Parâmetros pedidos:

- `name = amzn2-ami-hvm-2.0.202*-x86_64-gp2`
- `owners = ["amazon"]`
- `virtualization-type = hvm`
- a mais recente (`most_recent = true`)

<details>
<summary><b>💡 Clique para entender: o caminho (sem a resposta pronta)</b></summary>
<blockquote>

Este é um exercício autoral — o HCL é **seu**. Use estas pistas para chegar lá sozinho:

- O bloco é um **`data "aws_ami"`** (não um `resource` — você está *descobrindo* uma AMI, não criando).
- Olhe como as **demos** descobrem a Amazon Linux 2023 por `data "aws_ami"` (ex.: demo 01.1) — a estrutura é a **mesma**; aqui só muda o filtro de `name` para a família AL2 pedida.
- Os filtros usam blocos `filter { name = "..."; values = [...] }`. Você precisa de um para o `name` (o padrão `amzn2-ami-hvm-...` do enunciado) e um para `virtualization-type`. Some `owners` e `most_recent`, conforme os parâmetros pedidos acima.

Documentação oficial: [aws_ami data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)

</blockquote>
</details>

---

<a id="passo-3"></a>

**3.** Crie **2 instâncias** EC2 `t2.micro` usando a AMI do data source, com o nome carregando o workspace (`ec2-dev`, `ec2-prod`, `ec2-homol`). Use `count = 2` e `terraform.workspace` na tag `Name`.

<details>
<summary><b>💡 Clique para entender: o caminho (sem a resposta pronta)</b></summary>
<blockquote>

Este é um exercício autoral — o HCL é **seu**. Use estas pistas para chegar lá sozinho:

- Use o `resource "aws_instance"` com **`count = 2`** (mesma mecânica da frota da demo 01.3).
- O `ami` vem do **data source que você criou no passo 2** (referencie-o, não cole um ID fixo).
- O nome no `tags.Name` deve **interpolar `terraform.workspace`** para virar `ec2-dev-...`, `ec2-prod-...` conforme o ambiente. Pense em como combinar o nome do workspace com o `count.index` para diferenciar as duas instâncias.

Dica oficial sobre interpolação do workspace: [Current workspace interpolation](https://developer.hashicorp.com/terraform/language/state/workspaces#current-workspace-interpolation)

</blockquote>
</details>

---

<a id="passo-4"></a>

**4.** Crie o `state.tf` com backend S3, usando o seu bucket e a chave `ex-state-workspace`:

```hcl
terraform {
  backend "s3" {
    bucket = "SEU-BUCKET-AQUI"
    key    = "ex-state-workspace"
    region = "us-east-1"
  }
}
```

### Checkpoint

Se chegou até aqui, você tem: provider, data source de AMI, recurso de 2 EC2 com nome por workspace e backend S3 configurado.

---

## Parte 2 - Workspaces, validação e limpeza

### Resultado esperado desta parte

2 workspaces aplicados, prova de que o estado remoto funciona, e tudo destruído.

---

<a id="passo-5"></a>

**5.** Inicialize, crie ao menos 2 workspaces e aplique em cada um:

```bash
terraform init
terraform workspace new dev
terraform apply -auto-approve
terraform workspace new prod
terraform apply -auto-approve
```

No [painel EC2](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:) você verá `ec2-dev-1/2` e `ec2-prod-1/2`.

![](img/ec2-list.png)

---

<a id="passo-6"></a>

**6.** Prove que o estado remoto funciona: apague a cópia local e reinicialize:

```bash
rm -rf .terraform && terraform init
```

---

<a id="passo-7"></a>

**7.** Em cada workspace, confirme que um `apply` **não cria nada novo** (o estado veio do S3):

```bash
terraform workspace select dev && terraform apply -auto-approve
terraform workspace select prod && terraform apply -auto-approve
```

![](img/teste-apply.png)

> [!NOTE]
> "Nada a fazer" em ambos é a prova: o estado de cada ambiente está no S3 (`env:/dev/`, `env:/prod/`), não no seu laptop.

---

<a id="passo-8"></a>

**8.** Registre sua decisão num `DECISION.md` curto (estilo ADR), respondendo em 1-2 linhas cada:

- **Contexto:** por que separar dev/prod com workspaces aqui?
- **Alternativa descartada:** por que **não** usar diretórios/repos separados neste caso?
- **Consequência:** uma limitação dos workspaces que você aceitou.
- **Pergunta para validar com o stakeholder:** o que confirmaria com Helena antes de levar esse padrão para a produção real da Vortex?

---

<a id="passo-9"></a>

**9.** Destrua as instâncias em **todos** os workspaces:

```bash
terraform workspace select dev && terraform destroy -auto-approve
terraform workspace select prod && terraform destroy -auto-approve
```

### Checkpoint

Se chegou até aqui:

- 2 EC2 por workspace foram criadas com nome por ambiente
- você provou que o estado vem do S3
- registrou a decisão e destruiu tudo

---

## Conclusão

Você juntou estado remoto, workspaces, AMI dinâmica e `count` num único projeto autoral — e defendeu a escolha por escrito. É o fechamento prático do Mês 1 da Vortex.

> [!CAUTION]
> **Custo:** até 4 EC2 `t2.micro` (~$0,01/h cada). Confirme no painel EC2 que **nenhuma** instância ficou `running` em nenhum workspace após o passo 9.

---

<details>
<summary><b>💡 Glossário rápido</b></summary>
<blockquote>

| Termo | O que é |
|-------|---------|
| **Data source `aws_ami`** | Bloco que descobre dinamicamente a AMI mais recente que casa com os filtros. |
| **`terraform.workspace`** | Expressão que devolve o nome do workspace atual. |
| **Backend S3** | Armazenamento remoto do estado num bucket S3. |
| **`env:/<ws>/<key>`** | Caminho que o backend S3 usa para isolar o estado de cada workspace. |
| **ADR** | Architecture Decision Record — registro curto de uma decisão técnica e seu porquê. |

</blockquote>
</details>

<details>
<summary><b>💡 Como pedir ajuda se travou</b></summary>
<blockquote>

Antes de pedir ajuda, colete: (1) em que passo está, (2) erro literal do terminal, (3) `terraform workspace list` + `aws s3 ls`, (4) o que já tentou.

Canais (em ordem de prioridade):

- **Issues do repositório**: [github.com/vamperst/FIAP-Platform-Engineering/issues](https://github.com/vamperst/FIAP-Platform-Engineering/issues)
- **E-mail do professor**: `Rafael@rfbarbosa.com`

</blockquote>
</details>
