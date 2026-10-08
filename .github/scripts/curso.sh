#!/usr/bin/env bash
# ==========================================================
#  Robô do curso "Trabalho em equipe"
# ==========================================================
#  Roda a cada push (em qualquer branch), a cada mudança em pull request
#  e a cada comentário na issue (ver .github/workflows/curso.yml).
#
#  Igual aos outros cursos práticos:
#    - a etiqueta da issue (passo-1 ... passo-5, concluido) guarda o passo atual;
#    - cumpriu: parabéns + próximo passo; adiantou: avança vários de uma vez;
#    - errou de um jeito que dá para explicar: comenta uma dica.
#
#  O QUE ESTE CURSO TEM DE DIFERENTE: o robô também AGE como colega de equipe
#    - passo 2 concluído -> deixa um pedido de mudança no pull request (revisão);
#    - passo 3 concluído -> faz um commit na main mexendo na mesma parte do
#      EQUIPE.md que o aluno, para criar um CONFLITO de propósito.
#
#  Os textos de cada passo ficam em .github/passos/*.md
#  Neles, {{usuario}}, {{repo}} e {{pr}} são trocados pelos dados do aluno.
# ==========================================================
set -euo pipefail

REPO="$GITHUB_REPOSITORY"
USUARIO="${REPO%%/*}"
NOME_REPO="${REPO#*/}"
PASSOS=".github/passos"
TITULO="👥 Trabalho em equipe"
ULTIMO_PASSO=5
ARQ="EQUIPE.md"
LINHA_STELA="- Stela · professora e orientadora"
LINHA_ROBO="- Robô do curso · revisor automático 🤖"   # PARA EDITAR: a linha que causa o conflito
PR=""

# PARA EDITAR: o "cabeçalho" de todo comentário do robô
CABECALHO='<img src="https://maristelaoliveira.github.io/curso-github/assets/memoji.png" width="48" align="left" alt="">

**Stela diz:**
<br clear="left">

'

# PARA EDITAR: a frase de parabéns de cada passo concluído
FEITO[1]="✅ **Passo 1 concluído!** Sua branch está criada e você entrou para a equipe (por enquanto, só na sua branch). 🌿"
FEITO[2]="✅ **Passo 2 concluído!** Pull request aberto, com descrição. Já fui lá revisar! 🔍"
FEITO[3]="✅ **Passo 3 concluído!** Revisão atendida e aprovada. 👏 Mas, enquanto isso, eu mexi na \`main\`... 😈"
FEITO[4]="✅ **Passo 4 concluído!** Conflito resolvido, com as duas linhas mantidas. Isso é trabalho em equipe! ⚔️➡️🤝"
FEITO[5]="✅ **Passo 5 concluído!** Sua parte está na \`main\`. 🎉"

# PARA EDITAR: o pedido de mudança que o robô deixa no pull request (revisão)
REVISAO="### 🔍 Revisão

Oi! Li o seu pull request e ficou bom! 👏 Só um pedido antes do merge:

> Na sua linha do \`EQUIPE.md\`, acrescente o seu curso depois do nome:
> \`- Seu Nome · Seu Curso\` (ou com hífen: \`- Seu Nome - Seu Curso\`)

Faça o commit na branch do PR que ele se atualiza sozinho."

# ---------- funções auxiliares ----------
renderizar() { sed -e "s|{{usuario}}|${USUARIO}|g" -e "s|{{repo}}|${NOME_REPO}|g" -e "s|{{pr}}|${PR}|g" "$1"; }
arquivo_do_passo() { ls "$PASSOS"/"$1"-*.md | head -1; }
comentar() { gh issue comment "$ISSUE" --repo "$REPO" --body "${CABECALHO}$1" >/dev/null; }
comentar_pr() { gh pr comment "$PR" --repo "$REPO" --body "${CABECALHO}$1" >/dev/null; }
atualizar() { git fetch -q --prune origin '+refs/heads/*:refs/remotes/origin/*'; }

# linhas que o aluno ACRESCENTOU no EQUIPE.md numa branch, em relação à main
linhas_novas() { git diff "origin/main...origin/$1" -- "$ARQ" | grep '^+' | grep -v '^+++' | sed 's/^+//' || true; }

# o pull request aberto para a main (o mais recente): devolve "número branch"
pr_aberto() { gh pr list --repo "$REPO" --state open --base main --json number,headRefName --jq '.[0] | select(.) | "\(.number) \(.headRefName)"'; }

# todas as branches do GitHub, da mais recente para a mais antiga, sem o "origin/"
branches_remotas() { git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/remotes/origin | sed 's#^origin/##' | grep -vxE 'origin|HEAD'; }

# a branch de trabalho do aluno: a do PR aberto ou, se não houver, a que mexeu no EQUIPE.md
branch_do_aluno() {
  local pr; pr="$(pr_aberto)"
  if [ -n "$pr" ]; then echo "${pr#* }"; return; fi
  local b
  for b in $(branches_remotas); do
    [ "$b" = "main" ] || [ "$b" = "HEAD" ] && continue
    if [ -n "$(linhas_novas "$b")" ]; then echo "$b"; return; fi
  done
}

# uma linha com nome e curso: "- Nome · Curso" (aceita também -, |, — ou vírgula como separador)
tem_nome_e_curso() {
  grep -vxF -e "$LINHA_STELA" -e "$LINHA_ROBO" \
    | grep -qE '^-[[:space:]]+[^[:space:]].*([[:space:]]?·[[:space:]]?|[[:space:]][|—][[:space:]]|,[[:space:]]|[[:space:]]-[[:space:]])[^[:space:]]'
}

# ---------- ações do robô como "colega de equipe" ----------
postar_revisao() { comentar_pr "$REVISAO"; }

criar_conflito() {
  # coloca a LINHA_ROBO na main, logo abaixo da linha da Stela: o mesmo lugar onde o aluno escreveu
  git config user.name "Robô do curso"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git checkout -q -B main origin/main
  awk -v stela="$LINHA_STELA" -v robo="$LINHA_ROBO" '{print} $0 == stela {print robo}' "$ARQ" > "$ARQ.novo" && mv "$ARQ.novo" "$ARQ"
  git commit -q -am "Adiciona o robô do curso à equipe"
  git push -q origin main
  atualizar
  comentar_pr "✅ **Revisão aprovada!** Obrigada pela mudança. 🙌

Só que eu também mexi no \`EQUIPE.md\`, direto na \`main\`... Veja o próximo passo na issue do curso. 😈"
}

# ---------- as conferências de cada passo ----------
# Devolvem 0 (passou) ou 1 (ainda não). DICA = explicação do erro.

conferir_1() {   # uma branch (que não é a main) com o nome do aluno no EQUIPE.md
  [ -n "$(branch_do_aluno)" ] && return 0
  local inicial; inicial="$(git rev-list --max-parents=0 origin/main | tail -1)"
  if git diff "$inicial" origin/main -- "$ARQ" | grep -q '^+[^+]'; then
    DICA="Você mudou o \`EQUIPE.md\` **direto na \`main\`** 😅. Em equipe, cada pessoa trabalha na própria branch, para não atrapalhar ninguém. Crie a branch \`minha-parte\` (clique no botão **main**, digite \`minha-parte\` e **Create branch**), e acrescente o seu nome **nela**."
  elif branches_remotas | grep -qvx main; then
    DICA="A branch já existe! 🌿 Agora acrescente o seu nome no \`EQUIPE.md\` **dentro dela**: confira se o botão de branches mostra \`minha-parte\` antes de editar."
  fi
  return 1
}

conferir_2() {   # pull request aberto, com descrição
  local pr; pr="$(pr_aberto)"
  [ -z "$pr" ] && return 1
  PR="${pr%% *}"
  local corpo; corpo="$(gh pr view "$PR" --repo "$REPO" --json body --jq '.body // ""')"
  if [ "${#corpo}" -lt 15 ]; then
    DICA="O PR #$PR está aberto, mas **sem descrição**. O revisor precisa saber o que você fez! No PR, clique nos **...** do primeiro comentário → **Edit**, escreva uma ou duas frases e salve."
    return 1
  fi
}

conferir_3() {   # na branch do PR, a linha do aluno tem nome e curso
  local pr; pr="$(pr_aberto)"
  if [ -z "$pr" ]; then DICA="Não encontrei o pull request aberto. Se você fechou sem querer, abra de novo (botão **Reopen**)."; return 1; fi
  PR="${pr%% *}"
  local novas; novas="$(linhas_novas "${pr#* }")"
  if echo "$novas" | tem_nome_e_curso; then return 0; fi
  [ -n "$novas" ] && DICA="Ainda não vi o curso na sua linha. Ela deve ficar assim: \`- Seu Nome · Seu Curso\` (ou com hífen: \`- Seu Nome - Seu Curso\`). Faça o commit na branch do PR."
  return 1
}

conferir_4() {   # conflito resolvido: as duas linhas na branch, sem marcas, PR pode ser mesclado
  local pr; pr="$(pr_aberto)"
  [ -z "$pr" ] && return 1
  PR="${pr%% *}"
  local br="${pr#* }" conteudo
  conteudo="$(git show "origin/$br:$ARQ")"
  if echo "$conteudo" | grep -qE '^(<<<<<<<|=======|>>>>>>>)'; then
    DICA="Ficaram **marcas do Git** no \`EQUIPE.md\` (\`<<<<<<<\`, \`=======\` ou \`>>>>>>>\`). Apague essas três linhas, deixando só as linhas da equipe, e faça o commit na branch."
    return 1
  fi
  # a branch ainda não recebeu a main (conflito não resolvido): espera, sem dica
  git merge-base --is-ancestor origin/main "origin/$br" || return 1
  if ! echo "$conteudo" | grep -qF -- "$LINHA_ROBO"; then
    DICA="O conflito foi resolvido, mas a minha linha (\`$LINHA_ROBO\`) sumiu! 😢 Em equipe, a gente não apaga o trabalho do colega: acrescente essa linha de volta no \`EQUIPE.md\` da sua branch."
    return 1
  fi
  if ! echo "$conteudo" | tem_nome_e_curso; then DICA="A sua linha, com nome e curso, sumiu do \`EQUIPE.md\`. Acrescente de volta na sua branch."; return 1; fi
  # o GitHub confirma que dá para mesclar (às vezes leva uns segundos para calcular)
  local estado i
  for i in 1 2 3 4 5; do
    estado="$(gh pr view "$PR" --repo "$REPO" --json mergeable --jq .mergeable)"
    [ "$estado" != "UNKNOWN" ] && break
    sleep 4
  done
  [ "$estado" = "MERGEABLE" ]
}

conferir_5() {   # PR mesclado e a main com as duas linhas
  PR="$(gh pr list --repo "$REPO" --state merged --base main --json number --jq '.[0].number // empty')"
  if [ -z "$PR" ]; then
    local fechado; fechado="$(gh pr list --repo "$REPO" --state closed --base main --json number --jq '.[0].number // empty')"
    if [ -n "$fechado" ] && [ -z "$(pr_aberto)" ]; then PR="$fechado"; DICA="O PR #$fechado foi **fechado sem merge** (*Close*). Abra de novo (**Reopen pull request**) e use o botão **Merge pull request**."; fi
    return 1
  fi
  git show "origin/main:$ARQ" | grep -qF -- "$LINHA_ROBO"
}

# ---------- 1. a issue do curso existe? ----------
atualizar
ISSUE="$(gh issue list --repo "$REPO" --label curso --state all --json number --jq '.[0].number // empty')"
if [ -z "$ISSUE" ]; then
  gh label create curso     --repo "$REPO" --color 3fb950 --description "Curso prático" --force >/dev/null
  gh label create concluido --repo "$REPO" --color 7ee2b8 --force >/dev/null
  for n in $(seq 1 "$ULTIMO_PASSO"); do gh label create "passo-$n" --repo "$REPO" --color e3c26b --force >/dev/null; done
  corpo="${CABECALHO}$(renderizar "$PASSOS/0-boas-vindas.md")

---

$(renderizar "$(arquivo_do_passo 1)")"
  url="$(gh issue create --repo "$REPO" --title "$TITULO" --label curso --label passo-1 --body "$corpo")"
  echo "Issue do curso criada: $url"
  exit 0
fi

# ---------- 2. em que passo o aluno está? ----------
ETIQUETAS="$(gh issue view "$ISSUE" --repo "$REPO" --json labels --jq '[.labels[].name] | join(" ")')"
if [[ " $ETIQUETAS " == *" concluido "* ]]; then echo "Curso já concluído."; exit 0; fi
PASSO="$(echo "$ETIQUETAS" | grep -o 'passo-[0-9]*' | head -1 | cut -d- -f2)"
PASSO="${PASSO:-1}"
echo "Issue #$ISSUE · passo atual: $PASSO · evento: ${EVENTO:-?}"

# ---------- 3. confere e avança enquanto as tarefas estiverem cumpridas ----------
AVANCOU=0
while [ "$PASSO" -le "$ULTIMO_PASSO" ]; do
  DICA=""
  if "conferir_$PASSO"; then
    # o robô age como colega de equipe em alguns passos
    case "$PASSO" in
      2) postar_revisao ;;
      3) criar_conflito ;;
    esac
    if [ "$PASSO" -lt "$ULTIMO_PASSO" ]; then
      comentar "${FEITO[$PASSO]}

---

$(renderizar "$(arquivo_do_passo $((PASSO + 1)))")"
      gh issue edit "$ISSUE" --repo "$REPO" --remove-label "passo-$PASSO" --add-label "passo-$((PASSO + 1))" >/dev/null
    else
      comentar "${FEITO[$PASSO]}

---

$(renderizar "$PASSOS/6-fim.md")"
      gh issue edit "$ISSUE" --repo "$REPO" --remove-label "passo-$PASSO" --add-label concluido >/dev/null
      gh issue close "$ISSUE" --repo "$REPO" --reason completed >/dev/null
    fi
    PASSO=$((PASSO + 1))
    AVANCOU=1
  else
    if [ "$AVANCOU" = 0 ] && [ -n "$DICA" ]; then comentar "🤔 **Quase!** $DICA"; fi
    break
  fi
done
