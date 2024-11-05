# Variables
# Variables
PGDATA="/var/lib/postgresql/16/main"  # Chemin vers le répertoire des données PostgreSQL
PGCONF="/etc/postgresql/16/main/postgresql.conf"  # Chemin vers postgresql.conf
PGHBA="/etc/postgresql/16/main/pg_hba.conf"
REPL_USER="replicator"  # Nom de l'utilisateur de réplication
REPL_PASSWORD="votre_mot_de_passe"  # Mot de passe de l'utilisateur de réplication
MASTER_HOST="10.0.3.10"  # Adresse IP du serveur principal
LOGFILE="/tmp/db2.log"



  echo "Waiting for 2 minutes..."
  sleep 240

  echo "Installing PostgreSQL..."
  apt-get update
  apt-get install -y postgresql postgresql-contrib

{
systemctl stop postgresql

# Supprimer les données existantes
rm -rf $PGDATA/*

echo "Effectuer une sauvegarde de base depuis le serveur principal..."
PGPASSWORD=$REPL_PASSWORD pg_basebackup -h $MASTER_HOST -D $PGDATA -U $REPL_USER -v -P --wal-method=stream
if [ $? -ne 0 ]; then
    echo "Erreur : la sauvegarde de base a échoué."
    exit 1
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
systemctl start postgresql

echo "Configuration du serveur secondaire terminée."
} >> $LOGFILE 2>&1