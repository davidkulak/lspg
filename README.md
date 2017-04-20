# lspg
List and interact with PostgreSQL clusters


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
