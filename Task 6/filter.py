#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def _iter_containers(req: dict):
    spec = (req or {}).get('spec') or {}
    for key in ('containers', 'initContainers', 'ephemeralContainers'):
        items = spec.get(key) or []
        if isinstance(items, list):
            for c in items:
                if isinstance(c, dict):
                    yield c


def is_suspicious(event: dict) -> bool:
    verb = event.get('verb')
    obj = event.get('objectRef') or {}
    req = event.get('requestObject') or {}

    resource = obj.get('resource')
    subresource = obj.get('subresource')
    namespace = obj.get('namespace', '')
    name = obj.get('name', '')

    # 1) Доступ к secrets
    if resource == 'secrets' and verb in ('get', 'list', 'watch'):
        return True

    # 2) kubectl exec (обычно: verb=create, objectRef.resource=pods, subresource=exec)
    if verb == 'create' and subresource == 'exec':
        return True

    # 3) Привилегированные pod'ы (privileged: true)
    if resource == 'pods':
        for c in _iter_containers(req):
            sc = c.get('securityContext') or {}
            if sc.get('privileged') is True:
                return True

    # 4) RoleBinding/ClusterRoleBinding, дающий cluster-admin
    if resource in ('rolebindings', 'clusterrolebindings') and verb == 'create':
        role_ref = req.get('roleRef') or {}
        if role_ref.get('name') == 'cluster-admin':
            return True

    # 5) Удаление/изменение audit-policy (в minikube часто это не API-объект,
    # поэтому ищем "следы" в имени/URI/UA)
    if verb in ('delete', 'update', 'patch'):
        request_uri = event.get('requestURI', '') or ''
        user_agent = event.get('userAgent', '') or ''
        haystack = f'{name} {request_uri} {user_agent}'.lower()
        if 'audit-policy' in haystack:
            return True

        # Доп. триггер: правки системных configmaps (часто не ок)
        if resource == 'configmaps' and namespace == 'kube-system':
            return True

    return False


def main():
    audit_path = Path('audit.log')
    out_path = Path('audit-extract.json')

    result = []

    with audit_path.open('r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            if is_suspicious(event):
                result.append(event)

    with out_path.open('w', encoding='utf-8') as out:
        json.dump(result, out, ensure_ascii=False, indent=2)

    print(f'Подозрительные события сохранены в {out_path}')


if __name__ == '__main__':
    main()
