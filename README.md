# lspg
List PostgreSQL clusters and interact with them : 
* show PostgreSQL clusters, standby, master or standalone mode
* show databases, encoding and size
* simply connect to PostgreSQL clusters
* vaccum, reindex, reload you cluster

# Usage
```
root@serveur:~# lspg -h
	        USAGE: ./lspg.sh [l | d | t | s | c | v | f | i | r | p <port>]
	                  -l        | Affiche plus d'infos sur les clusters
	                  -d        | Affiche les bases
	                  -t        | Affiche les tablespaces (si il y en a)
	                  -s        | Affiche encodage et taille des bases si option -d utilisee
	                  -c        | Permet de se connecter ensuite a  l'un des clusters proposes
	                  -v        | Permet de faire un vaccum des clusters
	                  -f        | Permet de faire un vaccum full des clusters si option -v est utilisee
	                  -i        | Permet de faire un reindex des clusters
	                  -r        | Permet de faire un reload des clusters
	                  -p <port> | Ne montre que les bases du cluster <port> 
```
# Examples

Simple mode :


```
------------------------------------------------------------------------
[CLUSTER] (re7_1) Standby
  * Port      : 15404
  * Version   : 9.4.4
  * DataDir   : /app/postgresql/9.4/re7_1
                              
------------------------------------------------------------------------
[CLUSTER] (re7_2) Master ( 10.0.0.1:sync 10.0.0.2:potential ) (REPMGR=OK)
  * Port      : 15405
  * Version   : 9.4.4
  * DataDir   : /app/postgresql/9.4/re7_2

  ```

Extended mode with databases view :

```
------------------------------------------------------------------------
[CLUSTER] (re7_1) Standby
  * Port      : 15404
  * Version   : 9.4.4
  * Encodage  : UTF8
  * SockDir   : /var/run/postgresql/re7_1/
  * DataDir   : /app/postgresql/9.4/re7_1
  * StartTime : 2017-04-14 09:09:38
[BASES]
  * base1                      UTF8       5723kB     LastVacuum:2016-10-04                 
  * base2                      UTF8       5723kB     LastVacuum:2016-10-04                 
  * base3                      UTF8       5723kB     LastVacuum:2016-10-04                 
  * base4                      UTF8       5723kB     LastVacuum:2016-10-04                 
                   
------------------------------------------------------------------------
[CLUSTER] (re7_2) Master ( 10.0.0.1:sync 10.0.0.2:potential ) (REPMGR=OK)
  * Port      : 15405
  * Version   : 9.4.4
  * Encodage  : UTF8
  * SockDir   : /var/run/postgresql/re7_2/
  * DataDir   : /app/postgresql/9.4/re7_2
  * StartTime : 2017-02-21 14:56:40
[BASES]
  * base1                      UTF8       5723kB     LastVacuum:2016-10-04                 
  * base1                      UTF8       5723kB     LastVacuum:2016-10-04
  ```
