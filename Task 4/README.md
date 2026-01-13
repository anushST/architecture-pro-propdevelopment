| Роль          | Права роли                                                | Группы пользователей           |
| ------------- | --------------------------------------------------------- | ------------------------------ |
| viewer        | GET, LIST, WATCH - Pods, Deployments, Services, Ingresses | devs, qa, support              |
| secret-reader | GET, LIST, WATCH - Secrets                                | devops, sre, security          |
| admin         | All actions on all resources                              | platform-admins, devops-admins |


Init config:
```
./init.sh
```
