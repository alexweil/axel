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

# Fuente primaria de verdad: pmset (legible incluso desde sandboxes que niegan señales/ps).
# Tri-estado: 0 = viva (pmset muestra la assertion de ese pid), 1 = muerta confirmada
# (pmset accesible y sin match), 2 = indeterminado (sin pmset y señales no concluyentes).
# Con estado indeterminado JAMÁS se limpia el pidfile ni se señaliza el pid.
check() {
  [ -f "$PIDFILE" ] || return 1
  local pid asserts
  pid="$(cat "$PIDFILE")"
  asserts="$(pmset -g assertions 2>/dev/null || true)"
  if [ -n "$asserts" ]; then
    if printf '%s\n' "$asserts" | grep -q "pid ${pid}(caffeinate)"; then
      return 0
    fi
    return 1
  fi
  # Fallback sin pmset: solo afirmamos vida si ambas comprobaciones son concluyentes
  if kill -0 "$pid" 2>/dev/null; then
    case "$(ps -p "$pid" -o comm= 2>/dev/null)" in
      *caffeinate*) return 0 ;;
    esac
  fi
  return 2
}

# Señaliza el pid trackeado y CONFIRMA la muerte (vía check) antes de que el caller
# pierda el rastro. El pidfile solo se borra tras muerte confirmada.
kill_confirmed() {
  local pid="$1" rc
  kill "$pid" 2>/dev/null || true
  for _ in 1 2 3; do
    rc=0; check || rc=$?
    if [ "$rc" = 1 ]; then
      return 0
    fi
    sleep 0.2
  done
  return 1
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
    RC=0; check || RC=$?
    case "$RC" in
      0)
        if ! kill_confirmed "$(cat "$PIDFILE")"; then
          echo "error: no pude confirmar la muerte de la assertion previa (pid $(cat "$PIDFILE")); conservo el pidfile — resolvé a mano o dejá que la venza su timeout" >&2
          exit 2
        fi ;;
      1) ;;
      2)
        echo "error: estado de la assertion previa indeterminado; no arranco otra ni pierdo su rastro — reintentá desde un contexto sin sandbox o esperá su timeout" >&2
        exit 2 ;;
    esac
    rm -f "$PIDFILE"
    # -i: sin idle sleep (batería incluida) · -s: sistema despierto en corriente · -t: backstop
    nohup caffeinate -is -t "$((HORAS * 3600))" >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "máquina despierta por ${HORAS}h (pid $(cat "$PIDFILE"))"
    ;;
  stop)
    RC=0; check || RC=$?
    case "$RC" in
      0)
        if kill_confirmed "$(cat "$PIDFILE")"; then
          rm -f "$PIDFILE"
          echo "assertion liberada: la máquina puede dormir"
        else
          echo "error: la señal no surtió efecto o fue denegada (pid $(cat "$PIDFILE")); conservo el pidfile — la assertion sigue viva" >&2
          exit 2
        fi ;;
      1)
        rm -f "$PIDFILE"
        echo "no había assertion activa" ;;
      2)
        echo "estado indeterminado (sin pmset ni señales): no toco nada; si hace falta, matá el pid $(cat "$PIDFILE" 2>/dev/null || echo '?') a mano" >&2
        exit 2 ;;
    esac
    ;;
  status)
    RC=0; check || RC=$?
    case "$RC" in
      0) echo "despierta (pid $(cat "$PIDFILE"))" ;;
      1)
        # pmset confirmó que no existe: limpiar el pidfile huérfano es seguro
        rm -f "$PIDFILE"
        echo "sin assertion: la máquina puede dormir" ;;
      2) echo "indeterminado: hay pidfile ($(cat "$PIDFILE" 2>/dev/null || echo '?')) pero no puedo verificarlo desde acá; no lo toco" ;;
    esac
    ;;
  *)
    echo "uso: $0 {start [horas]|stop|status}" >&2
    exit 2
    ;;
esac
