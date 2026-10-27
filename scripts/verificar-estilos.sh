#!/usr/bin/env bash
# Control de permisos de Marketing y de estilos en .razor. Lo corre el workflow
# control-estilos en cada PR; también se puede correr a mano:
#   bash scripts/verificar-estilos.sh origin/testing testing write
#
#   $1 base   commit o rama contra la que se compara el PR
#   $2 destino rama destino del PR (testing / main)
#   $3 rol    role_name del autor en GitHub (admin, maintain, write, triage, read)
#
# 1. Rol distinto de admin/maintain (Marketing; en un repo personal, cualquier
#    colaborador): todos los archivos cambiados tienen que estar en
#    .github/rutas-marketing.txt y el PR tiene que ir a testing.
# 2. Para todos: estilos NUEVOS dentro de .razor (solo las líneas que agrega el PR,
#    los que ya existen no cuentan). Aviso, o error si ESTRICTO=1.
#    Se permite style="--variable: valor" para pasar valores dinámicos al CSS.
set -euo pipefail

base="${1:?uso: verificar-estilos.sh <base> <destino> <rol>}"
destino="${2:?uso: verificar-estilos.sh <base> <destino> <rol>}"
rol="${3:?uso: verificar-estilos.sh <base> <destino> <rol>}"
cd "$(git rev-parse --show-toplevel)"
errores=0

# --- 1. Marketing: solo rutas permitidas y solo hacia testing ---------------
case "$rol" in
    admin | maintain) ;;
    *)
        if [[ "$destino" != "testing" ]]; then
            echo "::error::Los PR de Marketing van a testing (este va a $destino). El pase a main lo hace Desarrollo."
            errores=1
        fi
        patrones=$(grep -vE '^[[:space:]]*(#|$)' .github/rutas-marketing.txt)
        fuera=$(git diff --name-only --no-renames "$base"...HEAD | grep -vE -e "$patrones" || true)
        if [[ -n "$fuera" ]]; then
            echo "::error::El PR modifica archivos fuera de las rutas de Marketing (.github/rutas-marketing.txt)."
            echo "Esos cambios los tiene que hacer Desarrollo:"
            echo "$fuera"
            errores=1
        fi
        ;;
esac

# --- 2. Estilos nuevos dentro de .razor -------------------------------------
regex_estilo='<style\b|(?<![\w-])style="(?!(?:\s*--[\w-]+\s*:[^;"]*;?)*\s*")'
nuevos=$(git diff -U0 "$base"...HEAD -- '*.razor' |
    awk '/^\+\+\+ /{archivo=substr($0, 7); next} /^\+/{print archivo ": " substr($0, 2)}' |
    grep -P "$regex_estilo" || true)
if [[ -n "$nuevos" ]]; then
    nivel=warning
    [[ "${ESTRICTO:-}" == "1" ]] && nivel=error && errores=1
    echo "::$nivel::El PR agrega estilos dentro de .razor. Para que Marketing los pueda cambiar,"
    echo "usá una clase y poné el estilo en el .razor.css del componente o en wwwroot/css/"
    echo "(para valores dinámicos: style=\"--variable: valor\")."
    echo "$nuevos"
fi

if ((errores == 0)); then
    echo "OK (rol: $rol, destino: $destino)."
fi
exit "$errores"
