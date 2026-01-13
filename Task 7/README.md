# Task 7 — Аудит и соответствие политике безопасности контейнеров (PSA / OPA Gatekeeper)

### Установка Gatekeeper
```bash
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm repo update
helm install gatekeeper gatekeeper/gatekeeper --namespace gatekeeper-system --create-namespace
```
---

```bash
./verify/verify-admission.sh
```

### Реальный запуск secure-подов + проверка securityContext

```bash
./verify/validate-security.sh
```
