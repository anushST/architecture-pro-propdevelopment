#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Namespace audit-zone (PSA restricted)"
kubectl apply -f "${ROOT_DIR}/01-create-namespace.yaml"

echo "==> Gatekeeper ConstraintTemplates + Constraints"
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraint-templates/"
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraints/"

echo
echo "==> Проверка insecure-manifests (должны быть ОТКЛОНЕНЫ)"
for f in "${ROOT_DIR}"/insecure-manifests/*.yaml; do
  echo "--- $(basename "$f")"
  if kubectl apply -f "$f" --dry-run=server >/dev/null; then
    echo "❌ ОШИБКА: манифест прошёл валидацию, но должен быть отклонён: $f"
    exit 1
  else
    echo "✅ Отклонён (как и ожидалось)"
  fi
done

echo
echo "==> Проверка secure-manifests (должны ПРОЙТИ валидацию)"
for f in "${ROOT_DIR}"/secure-manifests/*.yaml; do
  echo "--- $(basename "$f")"
  kubectl apply -f "$f" --dry-run=server >/dev/null
  echo "✅ Принят"
done

echo
echo "🎉 Готово: политики работают (PSA/Gatekeeper), insecure отклоняются, secure проходят."
