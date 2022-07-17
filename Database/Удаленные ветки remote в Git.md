202207150603
Tags: #git

---

# Удаленные ветки remote в Git

Ветки слежения - сслыки на определенное состояние удаленных веток. Локальные ветки, которые нельзя перемещать. Гит их сам перемещает при каждом соединении с сервером. 

*remote*/*branch*

origin - не спец. название, а просто название по умолчанию для удаленого сервера

```bash
# синхронизация изменений с сервером
git fetch origin

# Чтобы создать локальную версию ветки serverfix
git checkout -b serverfix origin/serverfix
# короткая альтернативная команда
git checkout --track origin/serverfix
# and even much shorter
git checkout serverfix

# настройка локальной ветки на слежение за удаленной веткой
git branch -u origin/iss61
git branch --set-upstream-to origin/iss61
# спецификация ссылок
git branch --u featureB:featureBee

# настройки веток слежения
git branch -vv
# но перед этим необходимо актуализировать данные
git fetch --all

# delete remote branch
git push origin --delete branchname
```

Ветка, за которой следит локальная, наз-ся upstream branch


---
## Links
- [[Ветка в git]]