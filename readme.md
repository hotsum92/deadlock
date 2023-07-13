# deadlock

## 単一テーブルでのデッドロック

### 環境作成

```
$ docker run --rm -d -e MYSQL_ALLOW_EMPTY_PASSWORD=true -p 3306:3306 mysql
$ mysql -h $(hostname -i) -u root -p < ./deadlock_1.sql
```

```
mysql> select * from a_bank;
+----+------+--------+----------------+---------------------+---------------------+
| id | name | amount | account_number | updated_at          | created_at          |
+----+------+--------+----------------+---------------------+---------------------+
|  1 | sato |     12 |              1 | 2023-07-13 17:56:07 | 2023-07-13 17:56:07 |
|  2 | kato |    120 |              2 | 2023-07-13 17:56:07 | 2023-07-13 17:56:07 |
|  3 | goto |     13 |              3 | 2023-07-13 17:56:07 | 2023-07-13 17:56:07 |
+----+------+--------+----------------+---------------------+---------------------+
```

### transaction A - step 1

a_bank使用者でid=1のsatoさんがid=2のkatoさんに3万円を振り込みました。預金から3万円を引く変更を行います。
このUPDATEにより、 id=1のcolumnにロックがかかりました。

```
mysql> BEGIN;
Query OK, 0 rows affected (0.00 sec)

mysql> UPDATE a_bank SET amount = amount - 3 WHERE id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

### transaction B - step 2

satoさんが振り込むと同時に、a_bank利用者でid=2のkatoさんがid=1のsatoさんに1万円を振り込みました。預金から1万円を引く変更を行います。
このUPDATEにより、 id=2のcolumnにロックがかかりました。

```
mysql> BEGIN;
Query OK, 0 rows affected (0.00 sec)

mysql> UPDATE a_bank SET amount = amount - 1 WHERE id = 2;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```

### transaction A - step 3

satoさんが振り込んだお金がkatoさんの口座に振り込まれます。トランザクションAで振り込まれた分の3万円がid=2のkatoさんの預金に合算されます。
ロック獲得待ちになりました。

```
mysql> UPDATE a_bank SET amount = amount + 3 WHERE id = 2;

```

### transaction B - step 4

katoさんが振り込んだお金がsatoさんの口座に振り込まれます。トランザクションBで振り込まれた分の1万円がid=1のsatoさんの預金に合算されます。

このUPDATEの実行により、

* トランザクションA : satoさんの口座から3万円が引かれる処理でロックがかかり、katoさんの口座に合算する処理でロック獲得待ちが発生
* トランザクションB : katoさんの口座から1万円が引かれる処理でロックがかかり、satoさんの口座に合算する処理でロック獲得待ちが発生

これがデッドロックです。

デッドロックが起きトランザクションBは自動でROLLBACKされました。

```
mysql> UPDATE a_bank SET amount = amount + 10000 WHERE id = 1;
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```

### transaction A - step 5

トランザクションBがROLLBACKされたことで、ロック獲得待ちが解除されUPDATE,COMMITが通りました。

```
mysql> UPDATE a_bank SET amount = amount + 3 WHERE id = 2;
Query OK, 1 row affected (1.99 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> COMMIT;
Query OK, 0 rows affected (0.04 sec)
```

### 結果

```
mysql> select * from a_bank;
+----+------+--------+----------------+---------------------+---------------------+
| id | name | amount | account_number | updated_at          | created_at          |
+----+------+--------+----------------+---------------------+---------------------+
|  1 | sato |      9 |              1 | 2023-07-13 17:56:07 | 2023-07-13 17:56:07 |
|  2 | kato |    123 |              2 | 2023-07-13 17:56:07 | 2023-07-13 17:56:07 |
|  3 | goto |     13 |              3 | 2023-07-13 17:56:07 | 2023-07-13 17:56:07 |
+----+------+--------+----------------+---------------------+---------------------+
```

## ref

[元の記事](https://note.com/shift_tech/n/nb23b9f44bd34)
