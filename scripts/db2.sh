#!/bin/bash

# Variables
PGDATA="/var/lib/postgresql/16/main"  # Chemin vers le répertoire des données PostgreSQL
PGCONF="/etc/postgresql/16/main/postgresql.conf"  # Chemin vers postgresql.conf
PGHBA="/etc/postgresql/16/main/pg_hba.conf"
REPL_USER="replicator"  # Nom de l'utilisateur de réplication
REPL_PASSWORD="votre_mot_de_passe"  # Mot de passe de l'utilisateur de réplication
MASTER_HOST="10.0.3.10"  # Adresse IP du serveur principal
LOGFILE="/tmp/db2.log"

# sudo -u postgres psql -c "SHOW transaction_read_only;"

{

  echo "Waiting for internet connection..."
  while ! ping -c 1 -W 1 google.com; do
    sleep 1
  done
  echo "Internet connection established."

echo "Installing PostgreSQL..."
apt-get update
apt-get install -y postgresql postgresql-contrib

#install cron 
apt-get install cron -y

echo "Waiting for the master host to listen on port 5432..."
while ! pg_isready -h $MASTER_HOST -p 5432; do   
  sleep 1
done
echo "Master host is now listening on port 5432."

systemctl start postgresql

# Supprimer les données existantes
rm -rf $PGDATA/*

echo "Effectuer une sauvegarde de base depuis le serveur principal..."

attempt=0
max_attempts=5
success=false

while [ $attempt -lt $max_attempts ]; do
  PGPASSWORD=$REPL_PASSWORD pg_basebackup -h $MASTER_HOST -D $PGDATA -U $REPL_USER -v -P --wal-method=stream
  if [ $? -eq 0 ]; then
    success=true
    echo "Sauvegarde de base réussie. Tentative $(($attempt + 1))/$max_attempts."
    break
  else
    echo "Erreur : la sauvegarde de base a échoué. Tentative $(($attempt + 1))/$max_attempts."
    attempt=$(($attempt + 1))
    sleep 5
  fi
done

if [ "$success" = false ]; then
  echo "Erreur : la sauvegarde de base a échoué après $max_attempts tentatives."
fi

chown -R postgres:postgres /var/lib/postgresql
chmod -R 700 /var/lib/postgresql

# Créer le fichier standby.signal pour indiquer le mode standby
echo "Création du fichier standby.signal..."
touch $PGDATA/standby.signal

echo "Activation de hot_standby dans postgresql.conf..."
echo "hot_standby = on" >> $PGCONF
echo "listen_addresses = '*'" >> $PGCONF


# Configurer la connexion au serveur principal dans postgresql.conf
echo "primary_conninfo = 'host=$MASTER_HOST port=5432 user=$REPL_USER password=$REPL_PASSWORD'" >> $PGCONF

echo "Configuration de pg_hba.conf pour les connexions locales et en lecture seule..."
echo "local   all             postgres                                peer" >> $PGHBA
echo "host    all             all             127.0.0.1/32            md5" >> $PGHBA
echo "host    all             all             ::1/128                 md5" >> $PGHBA



# Démarrer PostgreSQL sur le serveur secondaire
systemctl restart postgresql

echo "Configuration du serveur secondaire terminée."

echo "setting up cron job for failover"

crontab -l > failover
echo "* * * * * pg_isready -h 10.0.3.10 -p 5432 || sudo -u postgres pg_ctlcluster 16 main promote" >> failover
echo "* * * * * sleep 10; pg_isready -h 10.0.3.10 -p 5432 || sudo -u postgres pg_ctlcluster 16 main promote" >> failover
echo "* * * * * sleep 20; pg_isready -h 10.0.3.10 -p 5432 || sudo -u postgres pg_ctlcluster 16 main promote" >> failover
echo "* * * * * sleep 30; pg_isready -h 10.0.3.10 -p 5432 || sudo -u postgres pg_ctlcluster 16 main promote" >> failover
echo "* * * * * sleep 40; pg_isready -h 10.0.3.10 -p 5432 || sudo -u postgres pg_ctlcluster 16 main promote" >> failover
echo "* * * * * sleep 50; pg_isready -h 10.0.3.10 -p 5432 || sudo -u postgres pg_ctlcluster 16 main promote" >> failover
crontab failover

# Clean up
rm failover

# Check if crontab is empty and restore if necessary
if [ -z "$(crontab -l)" ]; then
  echo "Crontab is empty, restoring failover jobs..."
  crontab failover
else
  echo "Crontab is not empty, failover jobs already set."
fi

} >> $LOGFILE 2>&1
