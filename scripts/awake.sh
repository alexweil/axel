#!/usr/bin/env bash
# axel · mantiene la máquina despierta mientras el loop trabaja (generación + review)
#
# Uso:
#   scripts/awake.sh start [horas]   # assertion de no-dormir con ventana renovable (default 12h)
#   scripts/awake.sh stop            # libera: la máquina puede dormir
#   scripts/awake.sh status
#
# start es idempotente: si ya hay assertion, la reinicia y renueva la ventana.
# El timeout es el backstop para no dejar la máquina despierta por días si algo queda colgado.
# Límite físico: con la tapa cerrada una laptop duerme igual, salvo enchufada y con display externo.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PIDFILE="$REPO_ROOT/.claude/state/caffeinate-pid"
mkdir -p "$(dirname "$PIDFILE")"

# Vivo = el pid del pidfile existe Y es realmente un caffeinate (un pid reciclado
# por otro proceso no cuenta, y jamás hay que señalizarlo).
alive() {
  [ -f "$PIDFILE" ] || return 1
  local pid
  pid="$(cat "$PIDFILE")"
  kill -0 "$pid" 2>/dev/null || return 1
  case "$(ps -p "$pid" -o comm= 2>/dev/null)" in
    *caffeinate*) return 0 ;;
    *) return 1 ;;
  esac
}

case "${1:-status}" in
  start)
    if ! command -v caffeinate >/dev/null 2>&1; then
      echo "caffeinate no disponible (no es macOS): nada que hacer"
      exit 0
    fi
    # Validar el argumento ANTES de tocar la assertion vigente
    HORAS="${2:-12}"
    case "$HORAS" in
      ''|*[!0-9]*) echo "error: horas debe ser un entero positivo (recibí: '$HORAS')" >&2; exit 2 ;;
    esac
    if [ "$HORAS" -lt 1 ]; then
      echo "error: horas debe ser >= 1" >&2
      exit 2
    fi
    if alive; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
    # -i: sin idle sleep (batería incluida) · -s: sistema despierto en corriente · -t: backstop
    nohup caffeinate -is -t "$((HORAS * 3600))" >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "máquina despierta por ${HORAS}h (pid $(cat "$PIDFILE"))"
    ;;
  stop)
    if alive; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
      echo "assertion liberada: la máquina puede dormir"
    else
      echo "no había assertion activa"
    fi
    rm -f "$PIDFILE"
    ;;
  status)
    if alive; then
      echo "despierta (pid $(cat "$PIDFILE"))"
    else
      # Limpia un pidfile viejo (timeout vencido o pid reciclado) para no confundir
      rm -f "$PIDFILE"
      echo "sin assertion: la máquina puede dormir"
    fi
    ;;
  *)
    echo "uso: $0 {start [horas]|stop|status}" >&2
    exit 2
    ;;
esac
