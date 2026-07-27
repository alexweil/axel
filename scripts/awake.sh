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

alive() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

case "${1:-status}" in
  start)
    if ! command -v caffeinate >/dev/null 2>&1; then
      echo "caffeinate no disponible (no es macOS): nada que hacer"
      exit 0
    fi
    HORAS="${2:-12}"
    if alive; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
    fi
    # -i: sin idle sleep (batería incluida) · -s: sistema despierto en corriente · -t: backstop
    nohup caffeinate -is -t "$((HORAS * 3600))" >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "máquina despierta por ${HORAS}h (pid $(cat "$PIDFILE"))"
    ;;
  stop)
    if alive; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
      rm -f "$PIDFILE"
      echo "assertion liberada: la máquina puede dormir"
    else
      rm -f "$PIDFILE"
      echo "no había assertion activa"
    fi
    ;;
  status)
    if alive; then
      echo "despierta (pid $(cat "$PIDFILE"))"
    else
      echo "sin assertion: la máquina puede dormir"
    fi
    ;;
  *)
    echo "uso: $0 {start [horas]|stop|status}" >&2
    exit 2
    ;;
esac
