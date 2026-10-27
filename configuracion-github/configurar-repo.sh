#!/usr/bin/env bash
# Configura en GitHub los permisos de un repo PERSONAL (sin organización ni equipos).
# Se corre con `gh` logueado (o GH_TOKEN) como dueño del repo; es idempotente:
#
#   bash configuracion-github/configurar-repo.sh <dueño>/<repo> [usuario-marketing]
#
# Hace:
#   1. Crea/actualiza (por nombre) los rulesets:
#      - ruleset-ramas.json: main y testing solo por PR, 1 aprobación de un Code Owner
#        y los checks control-estilos y build en verde (el admin los saltea).
#      - ruleset-push-marketing.json: push ruleset que rechaza, en cualquier rama,
#        commits que toquen .razor, .cs, workflows, scripts, etc. (el admin los saltea).
#        Si el plan no lo incluye, avisa y sigue.
#   2. Crea el environment "testing", que solo acepta deploys desde la rama testing.
#   3. Carga en ese environment el secret de mentira SECRETO_PRUEBA (valor al azar,
#      no se imprime), para que el red team pruebe si una rama de Marketing lo puede leer.
#   4. Activa delete_branch_on_merge y deja los workflow permissions en read-only.
#   5. Si se pasa un usuario, lo invita como colaborador con permiso "push" (Write).
#      En un repo personal los colaboradores siempre tienen rol write: no saltean nada.
set -euo pipefail

repo="${1:?uso: configurar-repo.sh <dueño>/<repo> [usuario-marketing]}"
marketing="${2:-}"
dir="$(cd "$(dirname "$0")" && pwd)"
[[ "$repo" == */* ]] || { echo "El repo va como <dueño>/<repo>" >&2; exit 2; }

echo "→ Acceso"
if [[ "$(gh api "repos/$repo" --jq .permissions.admin)" != "true" ]]; then
    echo "El token no es admin de $repo." >&2
    exit 1
fi
echo "  admin de $repo ($(gh api "repos/$repo" --jq .visibility))"

echo "→ Rulesets"
ruleset() {
    local archivo="$dir/$1" nombre id
    nombre=$(jq -r .name "$archivo")
    id=$(gh api "repos/$repo/rulesets?includes_parents=false" \
        --jq ".[] | select(.name == \"$nombre\") | .id")
    if [[ -n "$id" ]]; then
        gh api -X PUT "repos/$repo/rulesets/$id" --input "$archivo" >/dev/null || return 1
        echo "  actualizado: $nombre (id $id)"
    else
        gh api -X POST "repos/$repo/rulesets" --input "$archivo" >/dev/null || return 1
        echo "  creado: $nombre"
    fi
}
ruleset ruleset-ramas.json || echo "  ⚠ ruleset de ramas no creado (ver el error de arriba)"
ruleset ruleset-push-marketing.json || echo "  ⚠ push ruleset no creado (¿el plan no lo incluye?)"

echo "→ Environment testing (solo rama testing)"
gh api -X PUT "repos/$repo/environments/testing" --input - >/dev/null <<'JSON'
{"deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
JSON
politicas=$(gh api "repos/$repo/environments/testing/deployment-branch-policies" \
    --jq '[.branch_policies[] | select(.type == "branch") | .name] | join(" ")')
if [[ " $politicas " != *" testing "* ]]; then
    gh api -X POST "repos/$repo/environments/testing/deployment-branch-policies" \
        -f name=testing -f type=branch >/dev/null
fi
echo "  ramas permitidas: $(gh api "repos/$repo/environments/testing/deployment-branch-policies" \
    --jq '[.branch_policies[].name] | join(", ")')"

echo "→ Secret de prueba SECRETO_PRUEBA (environment testing)"
# Valor al azar: nadie lo conoce, así que si aparece en un log o en un artifact, se filtró.
openssl rand -hex 24 | gh secret set SECRETO_PRUEBA --env testing --repo "$repo"

echo "→ Opciones del repo"
gh api -X PATCH "repos/$repo" -F delete_branch_on_merge=true >/dev/null
echo "  delete_branch_on_merge: $(gh api "repos/$repo" --jq .delete_branch_on_merge)"
gh api -X PUT "repos/$repo/actions/permissions/workflow" \
    -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
echo "  workflow permissions: $(gh api "repos/$repo/actions/permissions/workflow" \
    --jq .default_workflow_permissions)"

if [[ -n "$marketing" ]]; then
    echo "→ Colaborador $marketing (push)"
    gh api -X PUT "repos/$repo/collaborators/$marketing" -f permission=push >/dev/null
    echo "  invitado (tiene que aceptar la invitación desde su cuenta)"
fi

cat <<TXT
Listo. Falta, a mano:
  - crear la rama testing si no existe (git push origin main:testing);
  - si se invitó a Marketing, agregar su usuario en .github/CODEOWNERS (líneas de estilos);
  - en Settings → Rules → Rulesets, confirmar que el bypass diga solo "Repository admin".
TXT
