# 04 - Trabalho Final: a Vortex recria sua infraestrutura com um push

> **Mês 4. Segunda-feira, 8h.**
> Você é Platform Engineer na **Vortex Mobility**, a startup de micromobilidade que saiu de 3 para 30 cidades em um ano. Nos três últimos meses você transformou a infraestrutura: virou código com Terraform (Mês 1), configurou o GitLab Runner com Ansible (Mês 2) e montou o pipeline de CI/CD com gate de segurança (Mês 3).
> **Helena Marques**, Head de Engenharia de Plataforma, te chama para uma conversa antes do conselho:
>
> > *— "Aprendemos cada peça separada. Agora preciso de uma prova de que tudo se conecta. Quero um projeto único, end-to-end, que mostre que a Vortex consegue recriar e validar a infraestrutura do zero com um `git push`. Esse é o material que vou levar ao board para justificar o investimento em plataforma."*
>
> Diego Tavares, seu mentor SRE, passa na sua mesa e completa:
>
> > *— "É o momento de responder, de verdade, a pergunta que perseguiu a gente o ano inteiro: **quanto tempo a Vortex leva para recriar toda a sua infraestrutura do zero, de forma confiável e auditável?** No começo a resposta era 'dias, na mão, e ninguém tinha certeza'. Mostra que hoje é 'um push, automatizado e validado'."*

Este é o **Trabalho Final** da disciplina. Ele consolida tudo que você praticou nos módulos 01 (Terraform), 02 (Ansible) e 03 (CI/CD) em **um único projeto entregável**: um repositório no GitLab que, a cada `push` na branch principal, valida o código Terraform, barra configuração insegura e provisiona a infraestrutura da Vortex de forma reproduzível e auditável.

> [!WARNING]
> **Pré-requisitos obrigatórios antes de começar:**
>
> - [ ] Módulo **01 - Terraform** concluído (você sabe rodar `plan`/`apply`, criar módulos, usar `count`, state remoto no S3 e workspaces)
> - [ ] Módulo **02 - Ansible** concluído (você entende como o GitLab Runner é provisionado, aqui você **não** o sobe na mão, um script faz isso na Parte 0)
> - [ ] Módulo **03 - CI/CD** concluído (você fez ao menos um pipeline rodar `plan`/`apply` com etapa de validação)
> - [ ] Credenciais AWS do Academy atualizadas no Codespaces
> - [ ] Acesso ao seu GitLab com permissão para criar repositório e runner
>
> **Valide rapidamente que o essencial está de pé:**
>
> ```bash
> aws sts get-caller-identity
> terraform -version
> ```
>
> Se o primeiro retornar o JSON com seu `Account`/`Arn` e o segundo mostrar `Terraform v1.10` ou superior, você está pronto.
>
> **Tempo estimado total: 3 a 5 horas** (execução pura ~1h30 + tempo para depurar o pipeline, observar os jobs no GitLab e validar `dev`/`prod`). Recomendamos dividir em duas sessões.

## Objetivo

Provar, com um artefato funcional, que a infraestrutura da Vortex é **código versionado, reproduzível e validado automaticamente**: um `push` valida, barra o inseguro e provisiona tudo sozinho.

## O que você vai entregar

Ao final, você terá um **repositório GitLab** que:

- transforma a demo Count em um **módulo Terraform reutilizável** que recebe a quantidade de nós atrás do load balancer como parâmetro;
- nomeia os recursos por **workspace/ambiente** (ex: `nginx-prod-002`, `alb-dev`, `vortex-sg-prod`);
- guarda o **estado remoto no S3**, permitindo trabalho em time sem corromper o `terraform.tfstate`;
- separa **dev** e **prod** em workspaces distintos;
- roda um **pipeline de 3 etapas** (validar → revisar/gate de segurança → aplicar) no seu GitLab Runner.

A **entrega** (Parte 4) é um `.zip` com esse código Terraform e alguns **prints que provam que o pipeline rodou** (o código já é a prova do resto).

Sempre que encontrar um bloco **💡 Clique para entender**, abra-o: traz a anatomia do requisito, o porquê da escolha e links oficiais. Não é obrigatório para concluir, mas aprofunda.

## Mapa do trabalho

| Parte | O que você faz | Requisitos | Tempo |
|-------|----------------|------------|-------|
| [Parte 0](#parte-0---preparação-provisionamento-entregue) | Preparação: repositório + chave SSH + runner (script pronto) | [P1](#prep-1) · [P2](#prep-2) · [P3](#prep-3) · [P4](#prep-4) · [P5](#prep-5) | ~20 min |
| [Parte 1](#parte-1---modularizar-a-demo-count) | Modularizar a demo Count | [1](#req-1) · [2](#req-2) | ~60 min |
| [Parte 2](#parte-2---estado-remoto-e-ambientes-devprod) | Estado remoto e ambientes dev/prod | [3](#req-3) · [4](#req-4) · [5](#req-5) · [6](#req-6) | ~60 min |
| [Parte 3](#parte-3---pipeline-de-cicd-end-to-end) | Pipeline de CI/CD end-to-end | [7](#req-7) · [8](#req-8) | ~90 min |
| [Parte 4](#parte-4---empacotar-e-submeter) | Empacotar e submeter | [9](#req-9) | ~15 min |

Se travou em algum requisito, clique no número na coluna **Requisitos** acima para ir direto.

## Contexto

Cada conceito foi praticado isolado (um lab para `count`, um para state, um para o pipeline). Aqui eles coexistem no **mesmo repositório**, sob o mesmo fluxo — o que mais se parece com o dia a dia de um Platform Engineer: juntar peças soltas num sistema reproduzível.

A base é a **demo Count** ([`01-Terraform/demos/03-Count`](../01-Terraform/demos/03-Count/README.md)): N instâncias EC2 com Nginx atrás de um **ALB**. Você a evolui de "demo que roda na sua máquina" para "projeto que roda sozinho via pipeline, em dois ambientes, auditável".

<details>
<summary><b>💡 Clique para entender: por que essa integração existe</b></summary>
<blockquote>

| Aspecto | Resposta curta |
|---------|----------------|
| **Problema de negócio** | A Vortex aprendeu as ferramentas, mas precisa provar ao board que elas se combinam em um fluxo confiável. |
| **Pergunta que responde bem** | "Conseguimos recriar tudo do zero, sem clicar no console, e com alguém revisando antes?" |
| **Pergunta que responde mal** | "Qual o desenho ótimo de rede multi-conta?" — isso é arquitetura avançada, fora do escopo aqui. |
| **Quando acontece na vida real** | Toda empresa que sai de "infra clicada" para "infra como código" passa por este projeto de consolidação. |

Documentação oficial:
- [Terraform modules](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform backends — S3](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [GitLab CI/CD pipelines](https://docs.gitlab.com/ee/ci/pipelines/)

</blockquote>
</details>

### A arquitetura que você vai construir

Quando o trabalho estiver concluído, é isto que estará no ar: um `git push` que, sozinho, valida, revisa a segurança e provisiona a infraestrutura da Vortex. Este é o destino; as partes a seguir te levam até ele, peça por peça.

![Arquitetura final do Trabalho Final: um git push no repositório GitLab dispara o pipeline de 3 stages (validar, revisar com Checkov, aplicar) no GitLab Runner próprio (EC2 com LabRole); o terraform apply lê/grava o state no S3 e provisiona, na VPC fiap-lab, um ALB com Target Group distribuindo tráfego para as EC2 nginx (1 nó em dev, 3 em prod) sob um Security Group.](img/arquitetura-final.png)

---

## Parte 0 - Preparação (provisionamento entregue)

### Resultado esperado desta parte

Seu **runner próprio** de pé e **online** no GitLab, pronto para rodar o pipeline, sem você configurar servidor na mão. Esta parte **não é o foco do trabalho** (subir o runner você já aprendeu no Módulo 02); por isso ela é a mais automatizada possível: você cria o repositório, garante sua chave SSH, gera o token do runner e roda **um script** que provisiona tudo.

O que **vale nota** no Trabalho Final é o **código** que você escreve a partir da Parte 1 (o módulo Terraform, os workspaces e o `.gitlab-ci.yml`). O provisionamento do runner é só o palco: deixamos pronto de propósito para você gastar seu tempo no que importa.

> [!IMPORTANT]
> **Como o pipeline se autentica na AWS (autorização do CI/CD):** ao contrário do CI/CD "de mercado", você **não** vai cadastrar `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` como *CI/CD Variables* no GitLab. O pipeline roda **no seu runner**, que é uma EC2 com o **`LabRole`** anexado (instance profile). O `terraform` do pipeline herda essa permissão automaticamente: **nenhum segredo da AWS entra no GitLab**. É por isso que basta o runner estar online: ele já está autorizado a criar a infra.

---

<a id="prep-1"></a>

<dl>
<dt>

**Passo 0.1. Crie o repositório no GitLab**

</dt>
<dd>

Acesse **[Novo projeto](https://gitlab.com/projects/new)** → **Create blank project**, nomeie **`trabalho-final`**, deixe **Public** e **desmarque** "Initialize repository with a README". Ao criar, **guarde a URL SSH** do projeto (`git@gitlab.com:<seu-usuario>/trabalho-final.git`); você a usa no `git push` da Parte 3.

</dd>
</dl>

<details>
<summary><b>💡 Não lembra onde clicar?</b></summary>
<blockquote>

É o mesmo passo a passo que você fez ao criar o `primeiro-projeto` no **[Módulo 02 — Parte 4](../02-Ansible/01-provisionando-gitlab-runner/README.md#parte-4---criando-o-primeiro-projeto-no-gitlab)**. A única diferença é o nome do projeto (`trabalho-final`). A URL SSH aparece no botão azul **Code → Clone with SSH** da página do projeto.

</blockquote>
</details>

---

<a id="prep-2"></a>

<dl>
<dt>

**Passo 0.2. Garanta a chave SSH**

</dt>
<dd>

O `git push` para o GitLab usa uma **chave SSH sua**. **Se você abriu um Codespaces novo, a chave do Módulo 02 sumiu**; garanta a chave agora, no **terminal do Codespaces**:

```bash
# Se o .pub existir, a chave já está aqui: pule para o passo 0.3.
# Se NÃO existir (Codespaces novo), o comando abaixo cria a chave:
ls /home/vscode/.ssh/gitlab.pub 2>/dev/null || ssh-keygen -t rsa -b 2048 -C "gitlab key" -f /home/vscode/.ssh/gitlab -N ""

# Carrega a chave na sessão e mostra a parte pública para você copiar:
eval "$(ssh-agent -s)" && ssh-add /home/vscode/.ssh/gitlab
cat /home/vscode/.ssh/gitlab.pub
```

Copie a saída do `cat` e cole em **[Chaves SSH do GitLab](https://gitlab.com/-/user_settings/ssh_keys)** → **Add new key** (se ela já estava lá, pode pular).

</dd>
</dl>

<details>
<summary><b>💡 Detalhes do fluxo de chave SSH</b></summary>
<blockquote>

É exatamente o que você fez no **[Módulo 02 — Parte 3](../02-Ansible/01-provisionando-gitlab-runner/README.md#parte-3---configurando-o-acesso-ao-gitlab)** (passo 5). Lembre que o `ssh-agent` vive **por sessão de terminal**: se abrir um terminal novo, rode de novo `eval "$(ssh-agent -s)" && ssh-add /home/vscode/.ssh/gitlab`. Se o `git push` reclamar `Permission denied (publickey)`, é porque a chave não está carregada nesta sessão ou não foi colada no GitLab.

</blockquote>
</details>

---

<a id="prep-3"></a>

<dl>
<dt>

**Passo 0.3. Crie o runner e copie o token**

</dt>
<dd>

Ainda no GitLab, no projeto `trabalho-final`, vá em **Settings → CI/CD → Runners → Create project runner**, marque as **tags `shell` e `terraform`** e **copie o token** (`glrt-...`). É o mesmo fluxo do [Módulo 02](../02-Ansible/01-provisionando-gitlab-runner/README.md#parte-5---gerando-o-token-do-runner-e-guardando-no-ssm); como o projeto é novo, o token também é novo.

</dd>
</dl>

<details>
<summary><b>💡 Por que tags `shell` e `terraform`?</b></summary>
<blockquote>

O `.gitlab-ci.yml` que você vai escrever roteia os jobs com `tags: [shell]`. O runner precisa ter essa tag para pegar os jobs; por isso a marcamos aqui, na criação. É o mesmo par de tags do runner do Módulo 02.

</blockquote>
</details>

---

<a id="prep-4"></a>

<dl>
<dt>

**Passo 0.4. Guarde o token no SSM**

</dt>
<dd>

No **terminal do Codespaces**, guarde o token no **SSM Parameter Store**, no parâmetro **`/fiap/gitlab-runner/token`** (é dele que o script e o playbook leem, sem segredo em arquivo). Troque o `glrt-COLE-SEU-TOKEN-AQUI` pelo token que você copiou no passo 0.3:

```bash
aws ssm put-parameter --name /fiap/gitlab-runner/token \
  --type SecureString --value "glrt-COLE-SEU-TOKEN-AQUI" \
  --region us-east-1 --overwrite
```

</dd>
</dl>

> 📚 **Você já fez exatamente isso no Módulo 02** ao registrar o seu runner; o mesmo comando está na **[Parte 5 do Módulo 02](../02-Ansible/01-provisionando-gitlab-runner/README.md#parte-5---gerando-o-token-do-runner-e-guardando-no-ssm)** (passo 16).

---

<a id="prep-5"></a>

<dl>
<dt>

**Passo 0.5. Rode o script de provisionamento**

</dt>
<dd>

Ele instala o tooling, sobe a EC2 do runner e a configura via Ansible, **tudo em um comando** (leva ~5 min):

```bash
bash /workspaces/FIAP-Platform-Engineering/Trabalho-final/provisionamento/subir-runner.sh
```

Ao terminar, confirme em **Settings → CI/CD → Runners** que o runner aparece **online**.

</dd>
</dl>

<details>
<summary><b>💡 Clique para entender: o que o script faz (e por que ele existe)</b></summary>
<blockquote>

O `subir-runner.sh` reaproveita **o mesmo código do Módulo 02** (o Terraform da EC2 + o playbook Ansible). Ele: descobre seu bucket de state, confirma o token no SSM, prepara o Ansible (venv + `boto3` + collections + `session-manager-plugin`), sobe a EC2 (`terraform apply`) e registra o runner (`ansible-playbook`, conectando via SSM, sem SSH).

Por que entregar isso pronto? Porque **subir o runner não é o que este trabalho avalia**; você já fez isso no Módulo 02. O valor do Trabalho Final está no código que vem a seguir. Automatizar o palco tira fricção do que não gera nota.

O runner roda numa EC2 com o `LabRole` (instance profile), então o `terraform` do pipeline já terá acesso à AWS **sem** nenhuma credencial no GitLab.

</blockquote>
</details>

<details>
<summary><b>⚠ Se der erro: <code>token nao encontrado</code> ou <code>bucket base-config-* nao encontrado</code></b></summary>
<blockquote>

- **Token**: refaça o passo 0.4 (o `put-parameter`). Confira com `aws ssm get-parameter --name /fiap/gitlab-runner/token --with-decryption --region us-east-1 --query 'Parameter.Value' --output text`.
- **Bucket**: o script procura um bucket começando com `base-config`. Confirme que o bucket do setup (Módulo 01) existe: `aws s3 ls | grep base-config`.

</blockquote>
</details>

### Checkpoint

- [ ] O repositório `trabalho-final` existe no seu GitLab e você tem a URL SSH dele.
- [ ] Sua chave SSH está carregada na sessão e cadastrada no GitLab (o `git push` da Parte 3 depende disso).
- [ ] O token do runner está no SSM (`/fiap/gitlab-runner/token`).
- [ ] O script terminou e o runner aparece **online** em Settings → CI/CD → Runners.

---

> [!IMPORTANT]
> ## ✋ Daqui em diante começa o trabalho que será avaliado
> A partir da Parte 1, é **você** que desenvolve: o módulo Terraform, os workspaces e o `.gitlab-ci.yml`. O palco (runner) já está pronto; o foco agora é **código e lógica**.

Você vai desenvolver **dentro do seu repositório** `trabalho-final` (o que você criou na Parte 0). **Clone-o** para o Codespaces e entre na pasta; é daqui que os comandos das próximas partes assumem que você está (troque `<seu-usuario>` pelo seu usuário do GitLab):

```bash
cd /workspaces
git clone git@gitlab.com:<seu-usuario>/trabalho-final.git
cd /workspaces/trabalho-final
```

**Por que clonar, e não usar a pasta `Trabalho-final/` do curso?** Porque no Requisito 8 você vai dar `git push` para o **seu** projeto no GitLab. Trabalhando já dentro do clone dele, o push é direto, sem mover arquivos entre pastas. A pasta `Trabalho-final/` do repositório do curso guarda só este enunciado e o script da Parte 0; o **código que você desenvolve** vive no seu repositório clonado.

---

## Parte 1 - Modularizar a demo Count

### Resultado esperado desta parte

A lógica da demo Count vira um **módulo reutilizável** que recebe a quantidade de nós como variável, chamado por um arquivo raiz.

---

<a id="req-1"></a>

**Requisito 1 — Transformar a demo Count em um módulo**

Você vai pegar a infra da demo Count (o ALB + as N EC2 com Nginx) e empacotá-la como um **módulo** que recebe a quantidade de nós por variável. Faça, nesta ordem:

<dl>
<dt>

**1.1. Crie a pasta do módulo**

</dt>
<dd>

Estando em `/workspaces/trabalho-final`:

```bash
mkdir -p modules/web-cluster
```

</dd>
<dt>

**1.2. Copie para dentro dela TODOS os arquivos da demo Count**

</dt>
<dd>

Todos os `.tf` **e** o `script.sh`, de [`01-Terraform/demos/03-Count`](../01-Terraform/demos/03-Count/README.md). Estando em `/workspaces/trabalho-final`, copie da demo (que fica no repositório do curso):

```bash
cp /workspaces/FIAP-Platform-Engineering/01-Terraform/demos/03-Count/*.tf \
   /workspaces/FIAP-Platform-Engineering/01-Terraform/demos/03-Count/script.sh \
   modules/web-cluster/
```

Copie tudo, não escolha recursos soltos: os arquivos dependem uns dos outros (além dos recursos óbvios, a demo tem os `data`/`locals` de AMI e subnet, o `aws_lb_target_group_attachment` que liga as EC2 ao ALB e o `terraform_data` que roda o `script.sh` para instalar o Nginx). Você ajusta esse conjunto nos passos seguintes.

</dd>
<dt>

**1.3. Apague do módulo o que pertence ao raiz**

</dt>
<dd>

Remova o bloco `backend` e o `provider "aws"`, se vieram junto; eles ficam no arquivo raiz (Requisito 2), nunca no módulo. Já o `versions.tf` (com o `required_providers`) e o `check.tf` (um health-check que verifica se o ALB responde 200 no fim do apply) **podem ficar no módulo**; não precisa mexer neles.

</dd>
<dt>

**1.4. Parametrize a quantidade de nós**

</dt>
<dd>

Crie a variável `node_count` e use-a no `count` das instâncias, no lugar do número fixo que a demo tinha.

</dd>
<dt>

**1.5. Exponha o DNS do ALB como um `output` do módulo**

</dt>
<dd>

No arquivo **`outputs.tf` do módulo** (ele já veio da demo Count no passo 1.2, é só editá-lo), o ALB é exposto no output `alb_public`. **Renomeie esse output para `alb_dns`** (ele devolve `aws_lb.<seu_alb>.dns_name`); o arquivo raiz vai consumi-lo no Requisito 2, e os comandos de teste (Requisito 8 e Parte 4) usam esse nome. O outro output do arquivo (`address`) pode ficar como está.

</dd>
</dl>

> 📚 Como criar um módulo (fronteira do módulo, variáveis de entrada, `source`): demo **[01.2 - Modules](../01-Terraform/demos/02-Modules/README.md)**.

<details>
<summary><b>💡 Clique para entender: por que parametrizar a quantidade de nós</b></summary>
<blockquote>

Na demo Count o número de instâncias estava fixo (`count = 2`). Um módulo bom é **agnóstico ao ambiente**: a mesma lógica serve para 1 nó em `dev` e 4 em `prod`. Promover o número a variável (`node_count`) transforma o módulo em um contrato: quem chama decide o tamanho, o módulo decide como construir.

Padrão mental: o módulo é uma "função"; as variáveis são seus parâmetros; os `outputs` são seu retorno.

Documentação oficial:
- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Module composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition)

</blockquote>
</details>

---

<a id="req-2"></a>

**Requisito 2 — Criar o arquivo raiz que chama o módulo**

No **arquivo raiz** (na pasta do trabalho, fora de `modules/`) você chama o módulo, diz quantos nós ele deve criar e reexpõe o DNS do ALB. Faça, nesta ordem:

<dl>
<dt>

**2.1. Declare o `provider "aws"` no raiz**

</dt>
<dd>

Com `region = "us-east-1"` (as variáveis da demo foram para o módulo, então fixe a região aqui). O provider fica no raiz, nunca no módulo; o `backend` você adiciona no Requisito 3, também no raiz.

</dd>
<dt>

**2.2. Chame o módulo**

</dt>
<dd>

Use um bloco `module`, apontando `source` para a pasta do módulo (`./modules/web-cluster`).

</dd>
<dt>

**2.3. Passe o `node_count` derivado do workspace**

</dt>
<dd>

Use uma expressão condicional sobre `terraform.workspace` (`dev` = 1, `prod` = 3). Assim o pipeline não precisa de `-var` nem `tfvars`; basta selecionar o workspace.

</dd>
<dt>

**2.4. Reexponha o DNS do ALB como `output` do raiz**

</dt>
<dd>

Num arquivo **`outputs.tf` na raiz do projeto** (fora de `modules/`), crie um `output` (também chamado **`alb_dns`**) que devolve o output do módulo: `module.<nome_do_modulo>.alb_dns`. É esse `alb_dns` do raiz que o `terraform output -raw alb_dns` lê nos testes da Parte 3 e 4.

</dd>
<dt>

**2.5. Valide a sintaxe localmente** (sem precisar de credenciais)

</dt>
<dd>

```bash
cd /workspaces/trabalho-final
terraform init -backend=false
terraform fmt          # formata seus arquivos
terraform validate
```

O `terraform fmt` (sem `-check`) **formata** o código; o stage `validar` do pipeline (Requisito 7) roda `terraform fmt -check`, que **reprova** se algum arquivo não estiver formatado. Formatando aqui, o pipeline passa.

</dd>
</dl>

> 📚 Chamar um módulo, passar variável e expor `output`: demo **[01.2 - Modules](../01-Terraform/demos/02-Modules/README.md)**. A condicional com `terraform.workspace`: demo **[01.5 - Workspaces](../01-Terraform/demos/05-Workspaces/README.md)**.

<details>
<summary><b>⚠ Se der erro: <code>Unsupported attribute ... does not have an attribute named ...</code></b></summary>
<blockquote>

O nome do output que você consumiu no raiz (`module.<nome>.<output>`) não bate com o nome que você declarou no módulo (Requisito 1, passo 1.5). Abra os dois arquivos e deixe os nomes **idênticos**.

</blockquote>
</details>

### Checkpoint

- [ ] Existe uma pasta de módulo com os recursos da demo Count.
- [ ] O módulo expõe `node_count` como variável de entrada.
- [ ] O arquivo raiz chama o módulo e `terraform validate` passa.

---

## Parte 2 - Estado remoto e ambientes dev/prod

### Resultado esperado desta parte

O state vive no S3 e existem dois ambientes (`dev` e `prod`) com recursos nomeados pelo workspace.

---

<a id="req-3"></a>

**Requisito 3 — Mover o estado para o S3**

O `terraform.tfstate` sai da sua máquina e passa a viver no S3, para o pipeline e o time compartilharem o mesmo estado. Faça, nesta ordem:

<dl>
<dt>

**3.1. Crie o `backend.tf` na raiz**

</dt>
<dd>

Um arquivo `backend.tf` na raiz do projeto, com um bloco `backend "s3"` e estes três valores:

- **bucket**: o seu `base-config-<SEU-RM>` (o mesmo do setup, Módulo 01);
- **key**: exatamente **`trabalho-final/terraform.tfstate`**;
- **region**: `us-east-1`.

</dd>
<dt>

**3.2. Rode `terraform init`**

</dt>
<dd>

Ele migra o state para o S3.

</dd>
<dt>

**3.3. Crie o `.gitignore`**

</dt>
<dd>

Antes do primeiro `push` (Requisito 8), garanta que o `.terraform/`, o state e artefatos locais **não** vão para o Git. Na raiz do projeto:

```bash
cat > .gitignore <<'EOF'
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
build/
plan.tfplan
checkov-report.xml
EOF
```

</dd>
</dl>

> 📚 O bloco `backend "s3"` e o `terraform init` migrando o state estão na demo **[01.4 - State](../01-Terraform/demos/04-State/README.md)** — use-a como referência para escrever o seu.

> [!CAUTION]
> Nomes de bucket S3 **não podem ter espaços** nem maiúsculas e são globais. **Não** versione `terraform.tfstate` no Git; adicione-o ao `.gitignore`.

<details>
<summary><b>⚠ Se der erro: <code>Error: Failed to get existing workspaces: S3 bucket does not exist</code></b></summary>
<blockquote>

O bucket precisa existir **antes** do `terraform init`. Crie-o uma vez:

```bash
aws s3 mb s3://base-config-<SEU-RM> --region us-east-1
```

Depois rode `terraform init` novamente; ele migra o state para o S3.

</blockquote>
</details>

---

<a id="req-4"></a>

**Requisito 4 — Nomear as máquinas por workspace**

<dl>
<dt>

**4.1. Concatene o workspace no nome das máquinas**

</dt>
<dd>

Na tag `Name` das `aws_instance` (dentro do módulo), inclua **`${terraform.workspace}`**. O resultado deve ficar assim: `nginx-prod-002`, `nginx-dev-001` (o `count.index` que gera o `002` já vem da demo Count).

</dd>
</dl>

> 📚 O padrão de concatenar `${terraform.workspace}` no nome do recurso está na demo **[01.5 - Workspaces](../01-Terraform/demos/05-Workspaces/README.md)**.

---

<a id="req-5"></a>

**Requisito 5 — Nomear ALB, Target Group e Security Group por workspace**

<dl>
<dt>

**5.1. Concatene o workspace no nome do ALB, do Target Group e do Security Group**

</dt>
<dd>

Inclua `${terraform.workspace}` no nome do **ALB** (`aws_lb`), do **Target Group** (`aws_lb_target_group`) e do **Security Group** do módulo (ex: `alb-prod`, `tg-prod`, `vortex-sg-prod`).

</dd>
</dl>

O nome de um `aws_lb` (ALB) e de um `aws_lb_target_group` aceita no máximo 32 caracteres e só letras, números e hífens; mantenha curto (`alb-${terraform.workspace}`, `tg-${terraform.workspace}`).

> [!CAUTION]
> O **nome do Security Group não pode começar com `sg-`**: a AWS reserva esse prefixo para os IDs (`sg-01ab...`) e recusa com `invalid value for name (cannot begin with sg-)`. Use um prefixo próprio, ex: `vortex-sg-${terraform.workspace}` (vira `vortex-sg-prod`). Descrições de Security Group também devem ser ASCII, sem acentos.

---

<a id="req-6"></a>

**Requisito 6 — Criar os ambientes dev e prod (workspaces)**

<dl>
<dt>

**6.1. Crie os dois workspaces e liste para conferir**

</dt>
<dd>

```bash
cd /workspaces/trabalho-final
terraform workspace new dev
terraform workspace new prod
terraform workspace list
```

</dd>
<dt>

**6.2. Confirme que os ambientes se diferenciam de verdade**

</dt>
<dd>

`dev` = 1 nó, `prod` = 3. Você **não** precisa configurar nada novo aqui: essa diferença já vem da condicional sobre `terraform.workspace` que você escreveu no arquivo raiz (Requisito 2, passo 2.3). Basta selecionar o workspace (`terraform workspace select prod`) e aplicar; nada de `-var` ou `tfvars`.

</dd>
</dl>

> 📚 A demo **[01.5 - Workspaces](../01-Terraform/demos/05-Workspaces/README.md)** mostra `terraform workspace new/select/list` e como um mesmo código gera ambientes isolados.

Use a flag `-auto-approve` nos `apply`/`destroy` deste trabalho para pular o "type 'yes' to confirm"; não ensina nada novo e tira fricção.

### Checkpoint

- [ ] `backend.tf` aponta para `s3://base-config-<SEU-RM>` e `terraform init` migrou o state.
- [ ] EC2, ALB, Target Group e Security Group carregam o workspace no nome.
- [ ] `terraform.tfstate` está no `.gitignore`.
- [ ] `terraform workspace list` mostra `dev` e `prod`, e os dois se diferenciam.

---

## Parte 3 - Pipeline de CI/CD end-to-end

### Resultado esperado desta parte

Um repositório no GitLab roda um pipeline de 3 etapas no seu Runner próprio, deixando as EC2s no ar e um relatório de validação disponível.

---

<a id="req-7"></a>

**Requisito 7 — Escrever o pipeline de 3 etapas**

<dl>
<dt>

**7.1. Crie o arquivo `.gitlab-ci.yml` na raiz do projeto**

</dt>
<dd>

Ele terá **3 stages** que rodam no seu runner próprio (Parte 0) e provisionam **um** ambiente (o do workspace escolhido, no exemplo `prod`):

- **validar** — `terraform fmt -check`, `terraform init`, `terraform validate`;
- **revisar/gate** — seleciona o workspace, gera o `terraform plan` (artefato para o próximo stage) e roda o **Checkov** (igual ao Lab 03.2), publicando o relatório **JUnit** na aba **Tests**;
- **aplicar** — `terraform apply` do plano gerado, no mesmo workspace, deixando as EC2s no ar.

É o **mesmo padrão** dos labs de CI/CD; reaproveite o [Lab 03.1](../03-CICD/01-Primeiro-pipeline/README.md) (estrutura `plan`/`apply` + artefato) e o [Lab 03.2](../03-CICD/02-Validando-e-gerando-relatorios/README.md) (gate com Checkov + relatório JUnit). Use o esqueleto abaixo e adapte ao seu projeto:

```yaml
# .gitlab-ci.yml (esqueleto — adapte ao seu projeto)
stages:
  - validar
  - revisar
  - aplicar

variables:
  WORKSPACE: prod   # ambiente que o pipeline provisiona

validar:
  stage: validar
  script:
    - terraform fmt -check
    - terraform init
    - terraform validate
  tags: [shell]

revisar:
  stage: revisar
  script:
    - terraform init
    - terraform workspace select "$WORKSPACE" || terraform workspace new "$WORKSPACE"
    - terraform plan -out=plan.tfplan
    # gate de seguranca do Lab 03.2: roda o Checkov e publica o relatorio JUnit.
    # O "|| true" nao deixa os findings abortarem o job (mesma decisao do 03.2).
    - source /opt/venv/bin/activate
    - checkov --directory . --framework terraform -o junitxml > checkov-report.xml || true
  artifacts:
    when: always
    paths: [plan.tfplan, checkov-report.xml]
    reports:
      junit: checkov-report.xml
  tags: [shell]

aplicar:
  stage: aplicar
  script:
    - terraform init
    - terraform workspace select "$WORKSPACE"
    - terraform apply -auto-approve plan.tfplan
  dependencies: [revisar]
  tags: [shell]
```

</dd>
</dl>

O `source /opt/venv/bin/activate` funciona porque o **runner da Parte 0 já vem com o Checkov instalado** nesse venv (o playbook do Módulo 02 o instala em `/opt/venv`); você não instala nada, só ativa o ambiente antes de chamar o `checkov`, como no [Lab 03.2](../03-CICD/02-Validando-e-gerando-relatorios/README.md).

<details>
<summary><b>💡 Clique para entender: o gate, o workspace no CI e "reportar vs barrar"</b></summary>
<blockquote>

**Por que o gate vem antes do apply:** validar e revisar são baratos; aplicar cria recursos reais. Rodar o Checkov antes deixa a análise de segurança visível (aba **Tests**) **antes** de qualquer mudança chegar à nuvem: "falhe cedo, falhe pequeno".

**Reportar vs. barrar:** como no [Lab 03.2](../03-CICD/02-Validando-e-gerando-relatorios/README.md), usamos `|| true` para o Checkov **reportar sem abortar** o job: a infra da demo Count tem findings genéricos (SG aberto na 80, sem criptografia) que são **esperados**. Transformar o gate em bloqueio de verdade (remover o `|| true`, ou barrar só findings críticos) é uma **decisão sua**.

**Workspace no CI:** este é o ponto de integração novo (workspaces do [Lab 01.5](../01-Terraform/demos/05-Workspaces/README.md) dentro do pipeline do Módulo 03). O `terraform workspace select "$WORKSPACE" || terraform workspace new "$WORKSPACE"` garante que o `plan`/`apply` rodem no ambiente certo. Como cada stage roda num job separado, o `select` é repetido no `aplicar`.

Documentação oficial:
- [GitLab CI/CD stages](https://docs.gitlab.com/ee/ci/yaml/#stages)
- [Terraform workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)

</blockquote>
</details>

---

<a id="req-8"></a>

**Requisito 8 — Subir o código e disparar o pipeline**

<dl>
<dt>

**8.1. Faça o `git push` do seu código**

</dt>
<dd>

Você desenvolveu tudo dentro do clone do seu repositório (`/workspaces/trabalho-final`), então subir é um `git push`. O `.gitignore` do passo 3.3 já barra `.terraform/`, state e artefatos, vai só o código (módulo + raiz + `.gitlab-ci.yml`). O `push` **dispara o pipeline** automaticamente, no **runner da Parte 0**, igual ao [Módulo 03](../03-CICD/01-Primeiro-pipeline/README.md).

```bash
cd /workspaces/trabalho-final
terraform fmt          # formata TUDO antes de subir (o stage 'validar' roda 'fmt -check' e reprova se faltar)
git add .
git commit -m "trabalho final: modulo, workspaces e pipeline"
git push -u origin HEAD
```

</dd>
</dl>

> [!IMPORTANT]
> Confirme que o runner da Parte 0 está **online** em Settings → CI/CD → Runners. Como ele roda numa EC2 com o `LabRole`, o `terraform` no pipeline já tem acesso à AWS, sem `AWS_ACCESS_KEY_ID`/`SECRET` no repositório. Isso também evita o problema das credenciais do Academy, que são temporárias e expiram.

> [!CAUTION]
> **Nunca** faça commit do `terraform.tfstate` nem de segredos. Confira o `.gitignore` antes do primeiro push.

<details>
<summary><b>⚠ Se der erro: pipeline fica em <code>pending</code> e nunca roda</b></summary>
<blockquote>

O job está esperando um Runner. Verifique em **Settings → CI/CD → Runners** se o **runner da Parte 0** está **online** e habilitado para este projeto. Se ele tiver tags, o job precisa ter as mesmas tags (ou desmarque "Run untagged jobs").

</blockquote>
</details>

Quando o pipeline terminar, é aqui que você tira **os prints que vão na entrega** (Parte 4); eles são a prova de que o CI/CD rodou de verdade:

> 📸 **Print obrigatório** — salve como `prints/01-pipeline-verde.png`. Capture a página do pipeline no GitLab com os **3 stages verdes** (`validar → revisar → aplicar`), rodando no seu runner.

> 📸 **Print obrigatório** — salve como `prints/02-tests-checkov.png`. Abra a aba **Tests** do pipeline e capture o relatório do **Checkov** (o gate do stage `revisar`).

> 📸 **Print obrigatório** — salve como `prints/03-api-no-ar.png`. No terminal do Codespaces, rode `terraform workspace select prod && terraform output -raw alb_dns` para pegar o DNS, faça `curl http://<DNS>/` e capture a resposta do nginx (ou abra no navegador).

### Checkpoint

- [ ] O repositório no GitLab tem só o código deste trabalho (sem state, sem credenciais).
- [ ] O pipeline tem 3 etapas (`validar → revisar → aplicar`) e elas rodam no seu Runner próprio.
- [ ] O pipeline selecionou o workspace e as EC2s desse ambiente estão acessíveis pelo DNS do **ALB**.
- [ ] O relatório do **Checkov** (JUnit) aparece na aba **Tests** e o `plan.tfplan` está como artefato.
- [ ] Você tirou os 3 prints (`01-pipeline-verde`, `02-tests-checkov`, `03-api-no-ar`) para a entrega.

---

## Parte 4 - Empacotar e submeter

### Resultado esperado desta parte

Um `.zip` com **todo o Terraform que você desenvolveu** (do jeito que você organizou) + os **prints que provam que o pipeline rodou**, mais o link do repositório GitLab.

---

<a id="req-9"></a>

**Requisito 9 — Empacotar e submeter**

A entrega é **código + prints**. O **código** que você escreveu já é a prova do que você fez (módulo, workspaces, backend); por isso **não pedimos print do código**. O que o código *não* mostra é que o **pipeline rodou de verdade na nuvem**, e é isso que os prints provam.

#### O que entra no zip

Todo o código do trabalho, **na estrutura em que você o desenvolveu** — algo como:

```text
trabalho-final/
├── main.tf                 # raiz: provider + chamada do modulo (node_count por workspace)
├── outputs.tf              # raiz: output alb_dns (reexpoe o do modulo)
├── backend.tf              # state remoto no S3
├── .gitlab-ci.yml          # pipeline de 3 stages
├── .gitignore
├── modules/
│   └── web-cluster/        # o modulo que voce criou a partir da demo Count
│       ├── main.tf · securitygroup.tf · variables.tf · versions.tf · outputs.tf · check.tf · script.sh
└── prints/                 # as evidencias de que o pipeline rodou (adicionadas na sua maquina, passo 9.2)
    ├── 01-pipeline-verde.png
    ├── 02-tests-checkov.png
    └── 03-api-no-ar.png
```

#### Prints obrigatórios (foco em CI/CD — provar que rodou)

Você **não desenvolve nada de CI/CD além do `.gitlab-ci.yml`**, mas precisa **provar que o pipeline executou** no seu runner e entregou a infra. Tire estes três (salve em `prints/`):

- **`01-pipeline-verde.png`** — a página do pipeline no GitLab com os **3 stages verdes** (`validar → revisar → aplicar`), rodando no **seu** runner.
- **`02-tests-checkov.png`** — a **aba Tests** do pipeline mostrando o relatório do **Checkov** (o gate de segurança do stage `revisar`).
- **`03-api-no-ar.png`** — o terminal com o `curl http://<DNS-do-ALB>/` respondendo (ou a página no navegador) — a infra que o `apply` subiu, **no ar**.

#### Montando o zip (duas partes)

Suas coisas ficam em **dois lugares**: o **código** está no Codespaces (nuvem); os **prints** são `.png` na **sua máquina** (você os salvou com print de tela). Por isso:

<dl>
<dt>

**9.1. No Codespaces, empacote só o código**

</dt>
<dd>

Sem os artefatos pesados/locais (`.terraform/`, state, `build/`, `plan.tfplan`):

```bash
cd /workspaces/trabalho-final
zip -r trabalho-final-<SEU-RM>.zip . \
  -x '.terraform/*' -x '*/.terraform/*' \
  -x '*.tfstate*' -x '*.terraform.lock.hcl' \
  -x 'build/*' -x '*/build/*' \
  -x 'plan.tfplan' \
  -x '.git/*' -x '*/.git/*'
```

Precisa dos padrões com **e** sem `*/`: o `.terraform/` (e o `build/`) ficam na **raiz** do projeto, e `*/.terraform/*` só casaria os de subpasta. Confira o que entrou com `unzip -l trabalho-final-<SEU-RM>.zip`; se já tinha gerado um zip com o `.terraform` dentro, apague-o e rode de novo.

Para baixar: no explorer do Codespaces, abra a pasta do seu projeto (**File → Open Folder → `/workspaces/trabalho-final`** se ela ainda não estiver visível), clique com o botão direito em `trabalho-final-<SEU-RM>.zip` → **Download**.

</dd>
<dt>

**9.2. Na sua máquina, junte os prints e recompacte**

</dt>
<dd>

Descompacte o zip baixado, crie uma pasta `prints/` dentro dele, mova para lá os **3 prints** e recompacte. O `trabalho-final-<SEU-RM>.zip` final (código + `prints/`) é o que você entrega.

</dd>
</dl>

#### Submissão

<dl>
<dt>

**9.3. Envie no canal indicado pelo professor**

</dt>
<dd>

(Portal da FIAP / comunicado da turma), com:

- [ ] `trabalho-final-<SEU-RM>.zip` (código + `.gitlab-ci.yml` + `prints/`)
- [ ] **Link do repositório GitLab** (cole no campo de texto da entrega)
- [ ] Os **3 prints** dentro de `prints/`

</dd>
</dl>

> [!CAUTION]
> **Destrua a infraestrutura ao terminar**: este é o fim do arco, então derrube **tudo**: a infra do trabalho (EC2 + ALB em `dev` e `prod`) **e** o runner da Parte 0. Deixar ligado consome o orçamento do Learner Lab. Como a entrega é código + prints, **nada se perde** ao destruir.
>
> ```bash
> # 1) infra do trabalho, nos dois ambientes (o backend.tf do clone ja tem o seu bucket)
> cd /workspaces/trabalho-final
> terraform init
> terraform workspace select dev  && terraform destroy -auto-approve
> terraform workspace select prod && terraform destroy -auto-approve
>
> # 2) o runner da Parte 0 (a EC2 provisionada pelo script). O state.tf do runner usa
> #    um bucket placeholder; o bucket real entra via -backend-config (igual ao script).
> cd /workspaces/FIAP-Platform-Engineering/02-Ansible/01-provisionando-gitlab-runner/terraform-gitlab-runner
> BUCKET=$(aws s3 ls | awk '{print $3}' | grep '^base-config' | head -1)
> terraform init -reconfigure -backend-config="bucket=$BUCKET"
> terraform destroy -auto-approve
> ```

### Checkpoint

- [ ] O `.zip` tem o código Terraform completo (módulo + raiz + `.gitlab-ci.yml`), sem `.terraform/` nem `.tfstate`.
- [ ] A pasta `prints/` tem os 3 prints (pipeline verde, aba Tests/Checkov, API no ar).
- [ ] A submissão inclui o link do GitLab.
- [ ] A infraestrutura do trabalho foi destruída nos dois ambientes **e** o runner da Parte 0 também.

---

## Conclusão

Se você chegou até aqui, então construiu, em um único projeto, a resposta à pergunta que perseguiu a Vortex o ano inteiro:

- modularizou a demo Count em um módulo parametrizável;
- moveu o state para o S3, viabilizando trabalho em time;
- separou `dev` e `prod` com recursos nomeados por workspace;
- montou um pipeline de 3 etapas que valida, barra o inseguro e aplica, tudo no seu Runner.

**Mensagem para Helena**: *"A infraestrutura da Vortex hoje é código versionado. Um `push` na branch principal valida, revisa e provisiona tudo do zero, de forma confiável e auditável. A resposta para o board é: não são mais dias na mão, é um push."*

---

## Recursos de apoio

- [Como criar módulos reutilizáveis (Gruntwork)](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d)
- [Composição de módulos (Terraform)](https://developer.hashicorp.com/terraform/language/modules/develop/composition)
- [Módulos (Terraform)](https://developer.hashicorp.com/terraform/language/modules)
- [Data sources AWS (instances)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instances)

---

<details>
<summary><b>💡 Glossário rápido — termos que aparecem neste trabalho</b></summary>
<blockquote>

| Termo | O que é |
|-------|---------|
| **Módulo (Terraform)** | Conjunto de arquivos `.tf` em uma pasta que pode ser chamado por outros, com variáveis de entrada e outputs. É a unidade de reuso da IaC. |
| **State remoto** | O `terraform.tfstate` guardado fora da máquina (aqui no S3), para que vários engenheiros e o pipeline compartilhem o mesmo estado sem corromper. |
| **Workspace** | Mecanismo do Terraform para manter múltiplos states isolados a partir do mesmo código (ex: `dev` e `prod`). |
| **ALB (Application Load Balancer)** | Load balancer de camada 7 da AWS (`aws_lb` + `aws_lb_target_group` + `aws_lb_listener`), usado na demo Count para distribuir tráfego entre as EC2s com Nginx. |
| **Security Group** | Firewall virtual da AWS que controla o tráfego de entrada/saída de uma instância. |
| **Pipeline (CI/CD)** | Sequência de etapas automatizadas (stages/jobs) executadas pelo GitLab a cada push. |
| **GitLab Runner** | Agente que executa os jobs do pipeline. Aqui é o Runner próprio provisionado no Módulo 02 com Ansible. |
| **Gate de segurança** | Etapa que roda a análise de segurança (Checkov) antes do apply e publica o relatório. Neste trabalho ela **reporta** os findings sem abortar o pipeline (`\|\| true`, como no Lab 03.2); transformá-la em bloqueio de verdade é uma decisão sua. |
| **Artefato (CI/CD)** | Arquivo produzido por um job (ex: `plan.tfplan`, relatório) e disponibilizado para download no pipeline. |

</blockquote>
</details>

<details>
<summary><b>💡 Como pedir ajuda se travou</b></summary>
<blockquote>

Antes de abrir issue/perguntar, colete estas 4 informações: elas reduzem o tempo de resposta em 10×:

1. **Em que requisito você está** (ex: "Requisito 7, etapa `revisar` do pipeline")
2. **Mensagem de erro literal** (copia-cola completo do log do job no GitLab, não screenshot, texto é pesquisável)
3. **Saída de** `terraform workspace list` **e** `terraform validate` (mostra o estado real do projeto)
4. **O que você já tentou**

Canais (em ordem de prioridade):

- **Issues do repositório**: [github.com/vamperst/FIAP-Platform-Engineering/issues](https://github.com/vamperst/FIAP-Platform-Engineering/issues)
- **E-mail do professor**: `Rafael@rfbarbosa.com`
- **LinkedIn**: [rafael-barbosa-serverless](https://www.linkedin.com/in/rafael-barbosa-serverless/)
- **Antes de tudo**: confira se o Runner está online (~70% dos "pipeline pendente" são Runner offline ou tag incompatível) e se o bucket do backend existe.

</blockquote>
</details>
