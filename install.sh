#!/usr/bin/env bash
# Instalador de skills para agentes de Claude Code.
#
#   sudo ./install.sh [--dest RUTA] [--agents-dir RUTA] [--user USUARIO]
#                     [--rtk RUTA_AL_BINARIO] [--python RUTA]
#
# Las skills se instalan UNA vez en --dest y cada workspace de agente recibe
# un enlace a esa carpeta. Asi una correccion se propaga a todos a la vez;
# con copias acabarias con versiones distintas sin enterarte.
set -euo pipefail

DEST="/opt/codex-web-v4/skills"
AGENTS_DIR="/var/lib/codex-web-v4/agents"
USER_NAME="codex-web"
RTK_SRC=""
PYTHON_BIN=""
ORIGEN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    --agents-dir) AGENTS_DIR="$2"; shift 2 ;;
    --user) USER_NAME="$2"; shift 2 ;;
    --rtk) RTK_SRC="$2"; shift 2 ;;
    --python) PYTHON_BIN="$2"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Opcion desconocida: $1" >&2; exit 1 ;;
  esac
done

[[ $EUID -ne 0 ]] && { echo "Ejecutalo con sudo." >&2; exit 1; }
id "$USER_NAME" >/dev/null 2>&1 || { echo "No existe el usuario $USER_NAME. Usa --user." >&2; exit 1; }

# ---------------------------------------------------------------- python
if [[ -z "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python3 || true)"
fi
[[ -x "$PYTHON_BIN" ]] || { echo "No se encontro python3. Pasa --python RUTA." >&2; exit 1; }
echo "==> Python: $PYTHON_BIN"

# ------------------------------------------------------------------- rtk
# RTK es un binario independiente, no un paquete de pip. Optimus lo usa para
# filtrar salidas antes de que lleguen al modelo; sin el, la skill funciona
# pero sin su razon de ser.
if [[ -n "$RTK_SRC" ]]; then
  [[ -f "$RTK_SRC" ]] || { echo "No existe $RTK_SRC" >&2; exit 1; }
  install -m 755 "$RTK_SRC" /usr/local/bin/rtk
  echo "==> RTK instalado en /usr/local/bin/rtk"
fi

if command -v rtk >/dev/null 2>&1; then
  echo "    rtk $(rtk --version 2>&1 | head -1)"
else
  echo "    AVISO: rtk no esta en el PATH."
  echo "    Optimus se instalara igual, pero sin RTK no filtra nada."
  echo "    Copia el binario y vuelve a ejecutar con --rtk /ruta/al/rtk"
fi

# --------------------------------------------------------------- skills
echo "==> Skills en $DEST"
mkdir -p "$DEST"
for s in optimus ultracave ponytail; do
  [[ -d "$ORIGEN/$s" ]] || { echo "Falta $ORIGEN/$s" >&2; exit 1; }
  rm -rf "${DEST:?}/$s"
  cp -r "$ORIGEN/$s" "$DEST/$s"
  echo "    $s"
done

# Optimus lleva escritas las rutas del servidor donde nacio. Se reescriben
# a las de este, o el helper no se encontraria a si mismo.
SKILL="$DEST/optimus/SKILL.md"
sed -i "s#/opt/codex-web/.venv-zynertools/bin/python#${PYTHON_BIN}#g" "$SKILL"
sed -i "s#/opt/codex-web/skills/optimus/scripts/optimus.py#${DEST}/optimus/scripts/optimus.py#g" "$SKILL"
echo "    rutas de optimus ajustadas a este servidor"

chown -R "$USER_NAME:$(id -gn "$USER_NAME")" "$DEST"
chmod -R g+rX "$DEST"

# ------------------------------------------- enlaces en cada especialista
echo "==> Enlazando en los workspaces de $AGENTS_DIR"
N=0
if [[ -d "$AGENTS_DIR" ]]; then
  for ws in "$AGENTS_DIR"/*/workspace; do
    [[ -d "$ws" ]] || continue
    mkdir -p "$ws/.claude"
    ln -sfn "$DEST" "$ws/.claude/skills"
    chown -h "$USER_NAME:$(id -gn "$USER_NAME")" "$ws/.claude/skills"
    chown "$USER_NAME:$(id -gn "$USER_NAME")" "$ws/.claude"
    N=$((N + 1))
  done
fi
echo "    $N workspaces enlazados"
[[ $N -eq 0 ]] && echo "    (ninguno: comprueba --agents-dir)"

# ------------------------------------------------------------ verificacion
echo "==> Comprobacion"
if sudo -u "$USER_NAME" "$PYTHON_BIN" "$DEST/optimus/scripts/optimus.py" status --project /tmp >/dev/null 2>&1; then
  echo "    el helper de optimus responde"
else
  echo "    AVISO: el helper de optimus no respondio. Revisa $PYTHON_BIN"
fi

echo
echo "Listo. Las skills viven en $DEST y los $N workspaces apuntan ahi."
echo "Los especialistas que crees DESPUES naceran sin el enlace: vuelve a"
echo "ejecutar este instalador, o enlazalos a mano."
