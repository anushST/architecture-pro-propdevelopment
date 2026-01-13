#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${ROOT_DIR}/01-create-namespace.yaml" >/dev/null
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraint-templates/" >/dev/null
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraints/" >/dev/null

echo "==> Создаём secure-поды (реально, не dry-run)"
kubectl apply -f "${ROOT_DIR}/secure-manifests/" >/dev/null

echo "==> Показываем securityContext"
kubectl -n audit-zone get pods -o custom-columns=NAME:.metadata.name,RUN_AS_NON_ROOT:.spec.securityContext.runAsNonRoot,SECCOMP:.spec.securityContext.seccompProfile.type

echo
echo "==> Детальная проверка контейнеров: runAsUser/runAsNonRoot/readOnlyRootFilesystem"
for pod in $(kubectl -n audit-zone get pods -o jsonpath='{.items[*].metadata.name}'); do
  echo "--- $pod"
  kubectl -n audit-zone get pod "$pod" -o jsonpath='{range .spec.containers[*]}container={.name} runAsUser={.securityContext.runAsUser} runAsNonRoot={.securityContext.runAsNonRoot} readOnlyRootFilesystem={.securityContext.readOnlyRootFilesystem}{"\n"}{end}'
done

echo
echo "==> Очистка (удаляем secure-поды)"
kubectl -n audit-zone delete -f "${ROOT_DIR}/secure-manifests/" --ignore-not-found=true >/dev/null

echo "✅ Проверка завершена."
