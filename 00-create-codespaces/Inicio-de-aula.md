# 00 - Início de toda aula (atualizando credenciais)

> **Toda aula, 19h. Diego passa na sua mesa.**
> > *— "Antes de mexer em qualquer coisa da Vortex hoje: sincronizou o fork e recolocou as credenciais? A sessão do AWS Academy expira a cada 4 horas. Já vi gente perder meia hora debugando um `terraform plan` que falhava só porque o token tinha vencido. Faz o ritual primeiro, depois a gente trabalha."*

Toda aula começa com o mesmo ritual: sincronizar o seu fork com o repositório da disciplina e recolocar credenciais válidas da AWS no Codespaces. Você pode pular esta parte caso já tenha feito isso **hoje**.

Os comandos abaixo são executados em dois lugares: o **navegador** (GitHub e AWS Academy) e o **terminal do GitHub Codespaces**.

> [!WARNING]
> **Pré-requisitos obrigatórios antes de começar:**
>
> - [ ] Você já concluiu o [setup inicial do ambiente](./README.md) (fork, Codespaces, conta AWS Academy e bucket base criados)
> - [ ] Tem acesso à sua conta do AWS Academy Learner Lab
> - [ ] O Codespaces da disciplina existe na sua conta
>
> **O que você vai fazer:** sincronizar o fork, atualizar o repositório local e recolocar credenciais válidas da AWS no Codespaces.
>
> **Tempo estimado:** **5–10 min**.

Caso ainda **não** tenha feito o setup inicial (conta AWS Academy + Codespaces), siga primeiro o [tutorial de setup](./README.md). Este documento é o atalho que você repete no começo de cada aula.

## Principais pontos de aprendizagem

- sincronizar o seu fork com o repositório original da disciplina
- atualizar o repositório local dentro do Codespaces
- reiniciar a sessão do AWS Academy e recopiar as credenciais
- validar que o ambiente está pronto para os comandos da AWS

## O que você terá ao final

Um Codespaces atualizado com o material mais recente e credenciais AWS válidas — pronto para a aula do dia. **É o "destravar antes de começar" que o Diego cobra.**

> [!TIP]
> Sempre que encontrar um bloco com o título **💡 Clique para entender**, abra esse trecho para o contexto do passo.

## Mapa do lab

| Parte | O que você faz | Passos | Tempo |
|-------|----------------|--------|-------|
| [Parte 1](#parte-1---sincronizar-o-fork-e-o-repositório-local) | Sincronizar o fork e o repositório local | [1](#passo-1) · [2](#passo-2) · [3](#passo-3) · [4](#passo-4) · [5](#passo-5) | ~3 min |
| [Parte 2](#parte-2---atualizar-as-credenciais-da-aws) | Atualizar as credenciais da AWS | [6](#passo-6) · [7](#passo-7) · [8](#passo-8) · [9](#passo-9) · [10](#passo-10) · [11](#passo-11) · [12](#passo-12) · [13](#passo-13) · [14](#passo-14) | ~5 min |

> [!TIP]
> Se travou em algum passo, clique no número do passo na coluna **Passos** acima.

---

## Parte 1 - Sincronizar o fork e o repositório local

### Resultado esperado desta parte

Ao final desta etapa, seu fork e seu repositório local no Codespaces estarão atualizados com o material mais recente da disciplina.

---

<a id="passo-1"></a>

**1.** Acesse o seu GitHub no repositório que você forkou da disciplina **FIAP-Platform-Engineering**.

---

<a id="passo-2"></a>

**2.** Clique em `Sync Fork` no meio da tela para sincronizar com o repositório original. Se houver algo para sincronizar, clique em `Update branch`.

![](img/sync1.png)

![](img/sync2.png)

<details>
<summary><b>💡 Clique para entender: o que é sincronizar o fork</b></summary>
<blockquote>

O seu fork é uma fotografia do repositório original no momento em que você o criou. Conforme o professor publica correções e novos exercícios, o original (chamado de `upstream`) avança e o seu fork fica para trás.

`Sync Fork` puxa essas atualizações do `upstream` para o seu fork, sem você precisar refazer nada. É o equivalente, na interface do GitHub, a um `git fetch upstream` + `git merge`.

</blockquote>
</details>

---

<a id="passo-3"></a>

**3.** Caso não haja nada para sincronizar, a mensagem será `This branch is not behind the upstream` — nesse caso, não é preciso fazer nada nesta tela.

![](img/sync3.png)

---

<a id="passo-4"></a>

**4.** Acesse o seu Codespaces em [github.com/codespaces](https://github.com/codespaces) e clique no nome do Codespace que você criou para as aulas (derivado do repositório **FIAP-Platform-Engineering**).

![](img/codespacess11.png)

---

<a id="passo-5"></a>

**5.** No terminal do Codespaces, atualize o repositório local com as alterações que você acabou de sincronizar:

```bash
cd /workspaces/FIAP-Platform-Engineering && git pull origin master
```

<details>
<summary><b>⚠ Se der erro: <code>Your local changes would be overwritten by merge</code></b></summary>
<blockquote>

Isso acontece quando você editou arquivos do repositório dentro do Codespaces e eles conflitam com a atualização. Se essas edições forem testes que você não quer manter, descarte-as e refaça o `pull`:

```bash
cd /workspaces/FIAP-Platform-Engineering && git checkout -- . && git pull origin master
```

Se quiser preservar suas mudanças, fale com o professor antes de descartar.

</blockquote>
</details>

### Checkpoint

Se você chegou até aqui, então:

- o `Sync Fork` foi feito (ou já estava em dia)
- o `git pull` trouxe o material mais recente para o Codespaces

---

## Parte 2 - Atualizar as credenciais da AWS

### Resultado esperado desta parte

Ao final desta etapa, o Codespaces terá credenciais AWS válidas e o comando `aws s3 ls` funcionará.

---

<a id="passo-6"></a>

**6.** Ainda no terminal do Codespaces, abra o arquivo de credenciais da AWS:

```bash
code ~/.aws/credentials
```

---

<a id="passo-7"></a>

**7.** Acesse o [AWS Academy](https://www.awsacademy.com/vforcesite/LMS_Login) e clique em `AWS Academy Learner Lab` para entrar no laboratório que o professor informou.

![](img/ac1.png)

---

<a id="passo-8"></a>

**8.** Na lateral esquerda, clique em `AWS Academy Learner Lab` e depois em `Módulos`.

![](img/ac2.png)

---

<a id="passo-9"></a>

**9.** Clique em `Iniciar os laboratórios de aprendizagem da AWS Academy`.

![](img/ac3.png)

---

<a id="passo-10"></a>

**10.** Clique em `Start Lab` para iniciar a sessão. Aguarde até a bolinha ao lado de `AWS` (canto superior esquerdo) ficar **verde**. Em seguida, clique em `AWS` para abrir o console em outra aba.

![](img/ac4.png)

---

<a id="passo-11"></a>

**11.** Ainda na aba do AWS Academy, clique em `AWS Details` no canto superior direito.

![](img/ac5.png)

---

<a id="passo-12"></a>

**12.** Em `AWS CLI`, clique em `Show` para ver as credenciais de acesso.

![](img/ac6.png)

---

<a id="passo-13"></a>

**13.** Copie as credenciais e cole no arquivo `credentials` que você abriu no passo [6](#passo-6). Salve o arquivo (`Ctrl+S`) e feche.

![](img/ac7.png)

<details>
<summary><b>💡 Clique para entender: por que as credenciais mudam toda aula</b></summary>
<blockquote>

O AWS Academy Learner Lab usa credenciais **temporárias**: além do `aws_access_key_id` e `aws_secret_access_key`, há um `aws_session_token` que expira em até 4 horas. Por isso não dá para "configurar uma vez e esquecer" — a cada nova sessão (e a cada nova aula) o token muda e você precisa recopiá-lo.

É o oposto de uma credencial fixa de IAM e é proposital: reduz o risco de uma chave vazada continuar válida por muito tempo.

</blockquote>
</details>

---

<a id="passo-14"></a>

**14.** Teste no terminal do Codespaces:

```bash
aws s3 ls
```

Se tudo estiver correto, você verá a lista de buckets do S3 da sua conta, incluindo o `base-config-<SEU RM>` criado no setup.

<details>
<summary><b>⚠ Se der erro: <code>ExpiredToken</code> ou <code>Unable to locate credentials</code></b></summary>
<blockquote>

- `ExpiredToken` / `The security token included in the request is invalid`: a sessão do AWS Academy expirou ou você copiou credenciais antigas. Refaça os passos [10](#passo-10) a [13](#passo-13) com a sessão ativa (bolinha verde).
- `Unable to locate credentials`: o arquivo `~/.aws/credentials` não foi salvo. Refaça os passos [6](#passo-6) e [13](#passo-13), confirmando o `Ctrl+S`.

Para confirmar quem você é na AWS, rode também `aws sts get-caller-identity` — deve retornar seu `Account` e `Arn`.

</blockquote>
</details>

### Checkpoint

Se você chegou até aqui, então:

- a sessão do AWS Academy está ativa (bolinha verde)
- `aws s3 ls` lista seus buckets (credenciais válidas no Codespaces)

---

## Conclusão

Ritual concluído: fork sincronizado, repositório local atualizado e credenciais AWS válidas no Codespaces.

**Mensagem para o Diego:** ambiente destravado, sem token vencido. Pode começar a aula.

---

## Próximo passo

Com o ambiente pronto, abra o laboratório da aula de hoje a partir do **[README raiz do repositório](../README.md)** e siga a ordem do **Mapa de demos** (Mês 1 → Terraform, Mês 2 → Ansible, Mês 3 → CI/CD).

---

<details>
<summary><b>💡 Glossário rápido — termos que aparecem neste lab</b></summary>
<blockquote>

| Termo | O que é |
|-------|---------|
| **Fork** | Cópia do repositório na sua conta GitHub. |
| **`upstream`** | O repositório original da disciplina, do qual o seu fork foi criado. |
| **Sync Fork** | Ação do GitHub que traz as atualizações do `upstream` para o seu fork. |
| **`git pull`** | Comando que traz as atualizações do repositório remoto para o seu Codespaces local. |
| **`aws_session_token`** | Token temporário das credenciais do AWS Academy; expira em até 4 horas. |
| **`aws sts get-caller-identity`** | Comando que confirma qual identidade AWS está autenticada no momento. |

</blockquote>
</details>

<details>
<summary><b>💡 Como pedir ajuda se travou</b></summary>
<blockquote>

Antes de pedir ajuda, colete:

1. **Em que passo você está** (ex.: "passo 14, rodando `aws s3 ls`")
2. **Mensagem de erro literal** (copia-cola do terminal, não screenshot)
3. **Saída de** `aws sts get-caller-identity`
4. **O que você já tentou**

Canais (em ordem de prioridade):

- **Issues do repositório:** [github.com/vamperst/FIAP-Platform-Engineering/issues](https://github.com/vamperst/FIAP-Platform-Engineering/issues)
- **E-mail do professor:** [Rafael@rfbarbosa.com](mailto:Rafael@rfbarbosa.com)
- **Antes de tudo:** confirme que a sessão do AWS Academy está ativa (bolinha verde) — quase todo erro de credencial é sessão expirada.

</blockquote>
</details>
