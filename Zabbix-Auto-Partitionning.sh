#!/bin/bash

# Bootstrap.sql et documentation sur https://github.com/cavaliercoder/zabbix-pgsql-partitioning
#
# Christophe TRIOMPHE 2018 @ AxelIT
# Prerequis PSQL Server:
## - Procedure testée et validée pour PostgreSQL 9.6
## - Un Acces Trust pour zabbix en local
## - Le Partitionnement de base n'est pas supporté par Zabbix SIA

# Initialisation des variables
HISTORYDAY=7
TRENDDAY=365
PSQLSERVER="1.2.3.4"
DATABASECREATE="-h $PSQLSERVER -U zabbix -d zabbix"
DATABASEDROP="-h $PSQLSERVER -U zabbix -d zabbix"

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
        # Présentation des valeurs
        echo $(date +%Y-%m-%d -d @$HISTOOLD)
        echo $(date +%Y-%m-%d -d @$TRENDOLD)
}

# Procedure de creation des Tables de partionnements pour 2 jours
create-tables()
{
        # Création des nouvelles tables j+2
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
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('history_log', '$(date +%Y-%m-%d -d @$HISTOOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('history_text', '$(date +%Y-%m-%d -d @$HISTOOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('trends', '$(date +%Y-%m-%d -d @$TRENDOLD)'::TIMESTAMP);"
        /usr/bin/psql -qAtX $DATABASEDROP -c "SELECT zbx_drop_old_partitions('trends_uint', '$(date +%Y-%m-%d -d @$TRENDOLD)'::TIMESTAMP);"
}

### Programme principal
calc-time
#show
create-tables
purge-tables