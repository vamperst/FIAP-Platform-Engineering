# 03 — CI/CD com GitLab

Módulo prático sobre **integração e entrega contínua de infraestrutura** com **GitLab CI/CD** rodando no seu próprio **GitLab Runner** (o mesmo que você provisionou com Ansible no módulo 02). A ideia central: transformar o `terraform plan` / `terraform apply` que você rodava na mão em um **pipeline automático**, acionado a cada `push` na branch `master`, com um **gate de segurança** que barra configuração insegura **antes** dela chegar na nuvem.

São **2 demos sequenciais**, ambas sobre o repositório `primeiro-projeto` no GitLab e o runner registrado no módulo anterior.

## Mês 3 do arco da Vortex Mobility

> **Segunda-feira, 10h. Três meses depois da sua entrada na Vortex Mobility.**
> A infraestrutura já é toda código (módulo 01) e o provisionamento de servidores já é repetível com Ansible (módulo 02). **Diego Tavares**, seu mentor SRE, te chama numa call rápida:
>
> > *— "Temos o runner de pé. Mas ainda tem gente rodando `terraform apply` do laptop. Isso me tira o sono: ninguém revisa o `plan`, ninguém valida se a config é segura, e quando dá ruim a gente descobre na fatura da AWS. Quero que **todo push na master** rode `plan` e `apply` sozinho — e que tenha um **gate de segurança** que **barre configuração insegura ANTES** de chegar na nuvem."*

Este é o terceiro mês do arco. A pergunta-âncora do repositório inteiro — *"quanto tempo a Vortex leva para recriar toda a sua infraestrutura do zero, de forma confiável e auditável?"* — chega à sua resposta final aqui: **um push, automatizado e validado**.

## Os 2 itens deste módulo

| # | Item | O que você faz | Tempo estimado |
|---|------|----------------|----------------|
| **03.1** | **[Primeiro pipeline](01-Primeiro-pipeline/README.md)** | Cria o `.gitlab-ci.yml` com dois stages — `plan` (CI) e `apply` (CD) — e vê o pipeline subir uma **API serverless** (API Gateway + Lambda + DynamoDB) sozinho a cada push na `master`. | 30-45 min |
| **03.2** | **[Validando e gerando relatórios](02-Validando-e-gerando-relatorios/README.md)** | Adiciona um stage `validate` com `terraform fmt`/`validate`, **TFLint**, **Checkov**, **terraform test** e validação do código da Lambda — um gate de qualidade e segurança que gera relatório JUnit visível na aba **Tests** do GitLab. | 30-45 min |

> [!TIP]
> Faça na ordem: 03.1 → 03.2. A demo 03.2 evolui o mesmo `.gitlab-ci.yml` da 03.1, adicionando o gate de validação antes do `plan`.

## Pré-requisitos do módulo

> [!WARNING]
> Este módulo **depende dos módulos 01 e 02**. Antes de começar **qualquer** item daqui:
>
> - [ ] **Módulo 01 concluído** — você sabe rodar `terraform init/plan/apply` e configurar estado remoto no S3.
> - [ ] **Módulo 02 concluído** — você tem um **GitLab Runner registrado** com a tag `shell`, e o repositório **`primeiro-projeto`** existe na sua conta do GitLab com o código Terraform versionado.
> - [ ] **Chave SSH do GitLab** configurada no Codespaces (`/home/vscode/.ssh/gitlab`) — criada no módulo 02.
> - [ ] **Credenciais AWS do Academy atualizadas** no Codespaces.
>
> **Valide rapidamente** (no terminal do Codespaces):
>
> ```bash
> aws sts get-caller-identity
> ```
>
> E confira, no GitLab, em **Settings → CI/CD → Runners**, que existe um runner online com a tag `shell`. Se não tiver, volte ao [módulo 02](../02-Ansible/01-provisionando-gitlab-runner/README.md).

## Storytelling: a empresa fictícia Vortex Mobility

Para amarrar o repositório inteiro, seguimos a narrativa da **Vortex Mobility** — startup brasileira de micromobilidade (e-scooters e e-bikes) escalando de 3 para 30 cidades:

- **Helena Marques** (Head de Engenharia de Plataforma) — abriu os módulos 01 e 02 com demandas de negócio.
- **Diego Tavares** (SRE sênior, seu mentor) — abre **este módulo** e aparece nos checkpoints cobrando automação e segurança.
- **Você** (Platform Engineer recém-contratado) — implementa o pipeline.

Cada demo vira **uma resposta concreta** ao pedido do Diego: primeiro o pipeline roda sozinho e sobe a API da Vortex (03.1), depois ele vira **confiável** com um gate de validação e testes antes do `apply` (03.2).

## Decisões pedagógicas

1. **Por que GitLab CI/CD e não GitHub Actions?** Você já registrou um GitLab Runner próprio no módulo 02. Manter a continuidade (mesmo runner, mesmo `primeiro-projeto`) deixa o arco coeso e mostra o runner self-hosted em uso real.
2. **Por que `tags: shell`?** O runner do módulo 02 foi registrado com o executor `shell`, rodando direto no servidor EC2 (com Terraform, AWS CLI, TFLint e Checkov já instalados via Ansible). É isso que faz cada job encontrar `terraform` no PATH.
3. **Por que um gate de validação?** O stage `validate` reúne ferramentas amplamente adotadas no mercado — `terraform fmt`/`validate`, **TFLint**, **Checkov** e **terraform test** — que transformam "config insegura ou mal feita" em algo objetivo e automatizável, barrando o problema **antes** de chegar na nuvem (exatamente o que o Diego pediu).
4. **Por que uma API serverless (Lambda + API Gateway + DynamoDB)?** É um deploy free-tier, rápido (apply em segundos) e que entrega algo **navegável** ao final — uma URL que responde. Mais próximo de um deploy real de aplicação do que provisionar um recurso isolado.

## Custo do módulo

O pipeline cria a **API serverless** do `primeiro-projeto`: uma função **Lambda**, uma **API Gateway HTTP** e uma tabela **DynamoDB** on-demand — todas no **free-tier**. O que custa de verdade é o **runner** do módulo 02 (a EC2 `t3.small`, ~$0,02/h), que fica ligado para executar os pipelines deste módulo.

> [!CAUTION]
> **Não destrua o runner antes de terminar o módulo 03** — os pipelines dependem dele. O `terraform destroy` da API **e** do runner está no **passo final do Lab 03.2** (Parte 5). Rode lá, ao concluir o CI/CD, para zerar o custo.

## Próximo passo

Após concluir os 3 itens deste módulo, você terá o fio condutor do repositório fechado. Prossiga para:

**[Trabalho Final](../Trabalho-final/README.md)** — onde você junta Terraform, Ansible e CI/CD para entregar a infraestrutura da Vortex de ponta a ponta.
