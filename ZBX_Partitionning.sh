#!/bin/bash

# Bootstrap.sql et documentation sur https://github.com/cavaliercoder/zabbix-pgsql-partitioning
#
# Christophe TRIOMPHE 2018
# Prerequis PSQL Server:
## - Procedure testee et validee pour PostgreSQL 9.6
## - Un Acces Trust pour zabbix en local
## - Le Partitionnement de base n est pas supporte par Zabbix SIA
# Crontab -e
## 0 0 * * * $HOME/.profile; /etc/zabbix/bin/ZBX_Partitionning.sh
## @reboot sleep 10; $HOME/.profile; /etc/zabbix/bin/ZBX_Partitionning.sh


# Initialisation des variables
#Historique Numerique
HISTORYDAY=90

#Historique Texte
TRENDDAY=730

#Serveur SQL
PSQLSERVER="127.0.0.1"
ZBXUSER="zabbix"
ZBXDB="zabbix"

#Command PSQL Builder
DATABASECREATE="-h $PSQLSERVER -U $ZBXUSER -d $ZBXDB"
DATABASEDROP="-h $PSQLSERVER -U $ZBXUSER -d $ZBXDB"


# Procedure de calcul des delai de purge
calc-time()
{
        # Calcul des valeurs
        DATENOW=$(date --date=$(date +%Y%m%d) +"%s")
        HISTOTIME=$(($HISTORYDAY * 86400))
        TRENDTIME=$(($TRENDDAY * 86400))
        HISTOOLD=$(($DATENOW - $HISTOTIME))
        TRENDOLD=$(($DATENOW - $TRENDTIME))
}

# Debug des Dates
show()
{
        # PrÃ©sentation des valeurs
        echo $(date +%Y-%m-%d -d @$HISTOOLD)
        echo $(date +%Y-%m-%d -d @$TRENDOLD)
}

# Procedure de creation des Tables de partionnements pour 2 jours
create-tables()
{
        # CrÃ©ation des nouvelles tables j+2
        /usr/bin/psql -qAtX $DATABASECREATE -c "SELECT zbx_provision_partitions('history', 'day', 2);"
        /usr/bin/psql -qAtX $DATABASECREATE -c "SELECT zbx_provision_partitions('history_uint', 'day', 2);"
        /usr/bin/psql -qAtX $DATABASECREATE -c "SELECT zbx_provision_partitions('history_log', 'day', 2);"
        /usr/bin/psql -qAtX $DATABASECREATE -c "SELECT zbx_provision_partitions('history_text', 'day', 2);"
        /usr/bin/psql -qAtX $DATABASECREATE -c "SELECT zbx_provision_partitions('trends', 'day', 2);"
        /usr/bin/psql -qAtX $DATABASECREATE -c "SELECT zbx_provision_partitions('trends_uint', 'day', 2);"
}

# Procedure de purges des tables Obsoletes
purge-tables()
{
        # Purge des tables obsolete
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('history', '$(date +%Y-%m-%d -d @$HISTOOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('history_uint', '$(date +%Y-%m-%d -d @$HISTOOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('history_log', '$(date +%Y-%m-%d -d @$TRENDOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('history_text', '$(date +%Y-%m-%d -d @$TRENDOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('trends', '$(date +%Y-%m-%d -d @$TRENDOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('trends_uint', '$(date +%Y-%m-%d -d @$TRENDOLD)'::TIMESTAMP);"
}

### Programme principal
calc-time
#show
create-tables
purge-tables