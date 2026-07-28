#!/usr/bin/env bash
# axel · puerta de lint: shellcheck sobre los scripts de la maquinaria y sus suites.
# Fail-closed: sin shellcheck instalado la puerta FALLA (una puerta que se salta en
# silencio no es puerta) — instalar con: brew install shellcheck
# Gate en --severity=warning (error+warning bloquean). Los hallazgos info/style se
# triagean en docs/implementation/03-loop-hardening.md: los que son señal real se
# corrigen; los idiomáticos (p. ej. SC2015 en el patrón `cond && ok || ko` de las
# suites, SC2329 en funciones invocadas vía trap) quedan inventariados ahí.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && git rev-parse --show-toplevel)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "lint: shellcheck no está instalado — la puerta falla cerrada. Instalar: brew install shellcheck" >&2
  exit 2
fi

echo "── lint: shellcheck $(shellcheck --version | awk '/^version:/ {print $2}') · severidad warning ──"
RC=0
shellcheck --severity=warning "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/tests/*.sh || RC=$?
if [ "$RC" -eq 0 ]; then
  echo "── lint: limpio (scripts/*.sh y tests/*.sh) ──"
else
  echo "── lint: hallazgos arriba — corregir o silenciar con directiva justificada ──" >&2
fi
exit "$RC"
