#!/bin/bash
##############################################################################
# lspg.sh (github.com/davidkulak/lspg)
##############################################################################
#   Liste tous les cluster et bases PostgreSQL d'une machine
##############################################################################
# Parametre(s) :
#  -l
#  -d
#  -t
#  -s
#  -c
#  -v
#  -f
#  -i
#  -r
#  -p " < entier > "
#  -h
##############################################################################
# Exemple(s) : lspg.sh -d -p 5432
##############################################################################

#Configuration

SEP="------------------------------------------------------------------------"
BINPSQL=$(which psql)
BINVACUUM=$(which vacuumdb)
BINREINDEX=$(which reindexdb)
bold=$(tput bold)
normal=$(tput sgr0)

#Requetes

DBNAME="SELECT datname FROM pg_stat_database WHERE datname != 'postgres' AND datname NOT LIKE 'template%';"
CLNAME="SHOW data_directory;"
CLVERSION="SHOW server_version;"
CLENCODING="SHOW server_encoding;"
CLCONFDIR="SHOW hba_file;"
CLMASTER="select pg_is_in_recovery();"
CLSTANDALONE="select count(1) from pg_stat_replication;"
CLSTANDBY="select client_addr,sync_state from pg_stat_replication;"
CLREPMGR="select count(*) from pg_stat_activity where datname='repmgr_db' AND query LIKE '%INSERT%' AND query NOT LIKE '%pg_stat_activity%';"
CLLASTVACUUM="select last_vacuum from pg_stat_user_tables limit 1;"
REQ="$BINPSQL -h $SOCKDIR -p $PORT -U $PGUSER -d postgres --pset tuples_only 2>/dev/null";

#Fonctions

function fHelp
{
	echo "	        USAGE: ./lspg.sh [l | d | t | s | c | v | f | i | r | p <port>]"
	echo "	                  -l        | Affiche plus d'infos sur les clusters"
	echo "	                  -d        | Affiche les bases"
	echo "	                  -t        | Affiche les tablespaces (si il y en a)"
	echo "	                  -s        | Affiche encodage et taille des bases si option -d utilisee"
	echo "	                  -c        | Permet de se connecter ensuite a  l'un des clusters proposes"
	echo "	                  -v        | Permet de faire un vaccum des clusters"
	echo "	                  -f        | Permet de faire un vaccum full des clusters si option -v est utilisee"
	echo "	                  -i        | Permet de faire un reindex des clusters"
	echo "	                  -r        | Permet de faire un reload des clusters"
	echo "	                  -p <port> | Ne montre que les bases du cluster <port> "
	exit 0;
}

function fVacuum ()
{
    SOCKDIR=$1;
    PORT=$2;
    PGUSER=$3;
    if [[ $VACUUMFULL == 1 ]]; then
        su - $PGUSER -c "$BINVACUUM -avzf -h $SOCKDIR -p $PORT";
    else
        su - $PGUSER -c "$BINVACUUM -avz -h $SOCKDIR -p $PORT";
    fi
}   

function fReindex ()
{
    SOCKDIR=$1;
    PORT=$2;
    PGUSER=$3;
    su - $PGUSER -c "$BINREINDEX -a -h $SOCKDIR -p $PORT";
}

function fReload ()
{
    SOCKDIR=$1;
    PORT=$2;
    PGUSER=$3;
    DATADIR=$4
    BINPGCTL=$(find /usr -type f -name pg_ctl | head -n 1)
    su - $PGUSER -c "$BINPGCTL -D $DATADIR reload";
}

function fListTbs ()
{
    PG_CL_NAME=$1;
    PG_TBS_LISTE=$(ls $PG_CL_NAME/pg_tblspc/);
    if [ "$PG_TBS_LISTE" != "" ]; then
        echo -e "${bold}[TABLESPACES]${normal}";
        for tbs in $PG_TBS_LISTE; do
        location=$(readlink -f $PG_CL_NAME/pg_tblspc/$tbs);
        echo "  * $location";
        done;
    fi
}

function fListDbs ()
{
  SOCKDIR=$1;
  PORT=$2;
  PGUSER=$3;
  echo -e "${bold}[BASES]${normal}";
  PG_DB_LISTE=$(su - $PGUSER -c "echo \"$DBNAME\" | $REQ ");
  for base in $PG_DB_LISTE; do
  if [[ $SHOWDBSIZE == 1 ]]; then
      BASEENCODING="SELECT pg_encoding_to_char(encoding) FROM pg_database WHERE datname = '$base';";
      BASESIZE="SELECT pg_size_pretty(pg_database_size('$base'));";
      encodage=$(su - $PGUSER -c "echo \"$BASEENCODING\" | $REQ ");
      size=$(su - $PGUSER -c "echo \"$BASESIZE\" | $REQ ");
      lastvacuum=$(su - $PGUSER -c "echo \"$CLLASTVACUUM\" | $BINPSQL -h $SOCKDIR -p $PORT -U $PGUSER -d $base --pset tuples_only 2>/dev/null ");
      lastvacuumpretty=$(echo $lastvacuum | cut -d ' ' -f 1);
      printf "  * \e[1;32m%-30s \e[0m%-10s %-10s %-30s \n" $base $encodage ${size//[[:blank:]]/} LastVacuum:$lastvacuumpretty;
  else
      echo -e "  * \e[1;32m$base\e[0m";
  fi
  done;
}

function fCluster ()
{
        PORT=$1;
	COUNT=$2;
        PID=$(echo $i |awk -F '/' '{print $1}' |awk -F '_' '{print $2}');
        SOCKDIR=$(lsof -U -a -Fn +p $PID | grep PGSQL | cut -c2- |awk -F '.' '{print $1}' |head -n 1)
        PGUSER=$(ps aux |grep $PID |grep postgres | awk '{print $1}' | uniq);
        [[ $PGUSER =~ ^-?[0-9]+$ ]] && PGUSER=$(cat /etc/passwd | grep $PGUSER | awk -F ':' '{print $1}');
        REQ="$BINPSQL -h $SOCKDIR -p $PORT -U $PGUSER -d postgres --pset tuples_only 2>/dev/null";
        PG_CL_VERSION=$(su - $PGUSER -c "echo \"$CLVERSION\" | $REQ " | sed 's/ //g');
        PG_CL_ENCODING=$(su - $PGUSER -c "echo \"$CLENCODING\" | $REQ " | sed 's/ //g');
        PG_CL_NAME=$(su - $PGUSER -c "echo \"$CLNAME\" | $REQ " | sed 's/ //g');
	PG_CL_MASTER=$(su - $PGUSER -c "echo \"$CLMASTER\" | $REQ " | sed 's/ //g');

	eval USER_$COUNT=${PGUSER};
	eval SOCK_$COUNT=${SOCKDIR};
	eval PORT_$COUNT=${PORT};

	# Si Postgresql superieur a 9.0 alors replication possible sinon forcement en standalone
	if [[ $PG_CL_VERSION =~ 9.* ]]; then
	    # Si pg_is_in_recovery() est false on est sur le master ou sur un standalone, si true on est sur le standby
	    if [ $PG_CL_MASTER == "f" ]; then
	        # Si la vue pg_stat_replication ne renvoie rien on est sur un santalone, sinon sur un master
		PG_CL_STANDALONE=$(su - $PGUSER -c "echo \"$CLSTANDALONE\" | $REQ " | sed 's/ //g');
		if [ $PG_CL_STANDALONE == 0 ]; then
		    PGTYPE="\033[34mStandalone\033[0m";
		    MASTER=0;
		else
		   MASTER=1;
		   PG_CL_STANDBY=$(su - $PGUSER -c "echo \"$CLSTANDBY\" | $REQ " | sed 's/ //g' | sed 's/|/:/g' | sed ':a;N;$!ba;s/\n/ /g');
		   PG_CL_REPMGR=$(su - $PGUSER -c "echo \"$CLREPMGR\" | $REQ " | sed 's/ //g');
		   if [ $PG_CL_REPMGR == 0 ]; then
		     REPMGR="\033[31m(REPMGR=KO)\033[0m"
		   else
		     REPMGR="\033[32m(REPMGR=OK)\033[0m"
		   fi	
		   PGTYPE="\033[32mMaster ( $PG_CL_STANDBY) $REPMGR\033[0m";
		fi
	    else
                PGTYPE="\033[33mStandby\033[0m";
            fi
	else
	        PGTYPE="\033[34mStandalone\033[0m";
	fi

	echo $SEP;
	if [[ $CONNECT == 1 ]]; then
	    echo -e "${bold}[\033[35m$COUNT\033[0m]${bold}[CLUSTER]${normal} (${PG_CL_NAME##*/}) $PGTYPE";
	else
	    echo -e "${bold}[CLUSTER]${normal} (${PG_CL_NAME##*/}) $PGTYPE";
	fi
        echo -e "  * Port     : \e[90m$PORT\e[0m";
	echo -e "  * Version  : \e[90m$PG_CL_VERSION\e[0m";
	if [[ $DETAIL == 1 ]]; then
            echo -e "  * Encodage : \e[90m$PG_CL_ENCODING\e[0m";
	    echo -e "  * SockDir  : \e[90m$SOCKDIR\e[0m";
	fi
        echo -e "  * DataDir  : \e[90m$PG_CL_NAME\e[0m";
	# On liste les Tablespaces existants (si on en trouve)
	if [[ $SHOWTBS ]]; then
	    fListTbs $PG_CL_NAME
	fi

	# On liste les Bases existantes
	if [[ $SHOWDB ]]; then
            fListDbs $SOCKDIR $PORT $PGUSER
	fi
        
	# On Vacuum
        if [[ $VACUUM ]]; then
            fVacuum $SOCKDIR $PORT $PGUSER
        fi

        # On Reindex
        if [[ $REINDEX ]]; then
            fReindex $SOCKDIR $PORT $PGUSER
        fi

        # On recharge la configuration
        if [[ $RELOAD ]]; then
            fReload $SOCKDIR $PORT $PGUSER $PG_CL_NAME
        fi

}

#Init

COUNTER=1

#Parametres

while getopts dtlcsvfirp:h option
do
 case $option in
  l) DETAIL=1 ;;
  d) SHOWDB=1 ;;
  s) SHOWDBSIZE=1 ;;
  t) SHOWTBS=1 ;;
  c) CONNECT=1 ;;
  v) VACUUM=1 ;;
  f) VACUUMFULL=1 ;;
  i) REINDEX=1 ;;
  r) RELOAD=1 ;;
  p) PORTOPTS=${OPTARG} ;;
  h) fHelp ;;
  *) fHelp ;;
 esac
done

#Main

if [ "$(id -u)" != "0" ]; then
   echo "Script must be run as root" 1>&2
   exit 1
fi

if [[ $PORTOPTS ]]; then
    SERVER=$(netstat -laputen | grep -i -e postgres -e postmaster | grep LISTEN | grep 0.0.0.0 | grep $PORTOPTS | awk '{print $4"_"$9}')
else
    SERVER=$(netstat -laputen | grep -i -e postgres -e postmaster | grep LISTEN | grep 0.0.0.0 | awk '{print $4"_"$9}')
fi

if [[ $SERVER != "" ]]; then
    for i in $SERVER; do
        PORT=$(echo $i |awk -F ':' '{print $2}' |awk -F '_' '{print $1}');
        fCluster $PORT $COUNTER
        COUNTER=$[$COUNTER +1]
    done
else
    echo -e "${bold}\033[31mNo running PostgreSQL cluster detected !\033[0m${normal}"
fi

if [[ $CONNECT == 1 ]]; then
    echo " "
    read -p "A quel numero de cluster voulez vous vous connecter ? : " num
    CONNECT_USER=$(eval 'echo ${'USER_${num}'}')
    CONNECT_SOCK=$(eval 'echo ${'SOCK_${num}'}')
    CONNECT_PORT=$(eval 'echo ${'PORT_${num}'}')
    su - $CONNECT_USER -c "$BINPSQL -h $CONNECT_SOCK -p $CONNECT_PORT -U $CONNECT_USER -d postgres"
fi
