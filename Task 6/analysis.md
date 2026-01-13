# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам:
   - Кто: minikube-user
   - Где: namespace kube-system
   - Почему подозрительно: kube-system — системный namespace; перечисление secrets часто означает попытку получить токены/учётные данные (bootstrap-token потенциально может быть использован для компрометации/подключения компонентов в кластере).

2. Привилегированные поды:
   - Кто: minikube-user
   - Комментарий: был выполнен get pod privileged-pod в namespace secure-ops (код 200). В спецификации этого pod’а контейнер pwn имеет securityContext: { privileged: true }.

3. Использование kubectl exec в чужом поде:
   - Кто: minikube-user
   - Что делал: выполнен exec в pod attacker-pod (namespace secure-ops) — запрос к subresource pods/exec, ответ 101 Switching Protocols (типично для exec). В URI видно запуск sh и команду с echo exec-test.

4. Создание RoleBinding с правами cluster-admin:
   - Кто: не зафиксировано в предоставленном audit.log
   - К чему привело: в этом фрагменте нет ни одного запроса к ресурсам RBAC (roles/rolebindings/clusterrolebindings), поэтому подтвердить создание RoleBinding/ClusterRoleBinding с cluster-admin невозможно.

5. Удаление audit-policy.yaml:
   - Кто: не зафиксировано в предоставленном audit.log
   - Возможные последствия: прямых событий про audit-policy.yaml в логе нет.

## Вывод

В логе прослеживается цепочка действий minikube-user (группа system:masters): разведка и доступ к чувствительным объектам (перечисление secrets в kube-system), интерес к привилегированному pod’у (privileged-pod с privileged: true), удалённое выполнение команд через kubectl exec в существующем pod’е, а также попытка удалить системный ConfigMap (заблокирована RBAC).
При этом события про создание RoleBinding с cluster-admin и удаление audit-policy.yaml в данном фрагменте отсутствуют, поэтому их нельзя подтвердить по предоставленному файлу.
