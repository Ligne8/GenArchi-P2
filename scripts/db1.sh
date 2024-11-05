# Variables
PGDATA="/var/lib/postgresql/16/main"  # Chemin vers le répertoire des données PostgreSQL
PGCONF="/etc/postgresql/16/main/postgresql.conf"
PGHBA="/etc/postgresql/16/main/pg_hba.conf"
REPL_USER="replicator"  # Nom de l'utilisateur de réplication
REPL_PASSWORD="votre_mot_de_passe"  # Mot de passe de l'utilisateur de réplication
REPL_NET="10.0.4.10/32"  # Réseau autorisé pour la réplication
LOGFILE="/tmp/db1.log"


# Installation de PostgreSQL
echo "Installing PostgreSQL..."
apt-get update
apt-get install -y postgresql postgresql-contrib


{
# Initialisation du serveur PostgreSQL
systemctl start postgresql

echo "wal_level = replica" >> $PGCONF
echo "max_wal_senders = 3" >> $PGCONF
echo "wal_keep_size = 64" >> $PGCONF
echo "listen_addresses = '*'" >> $PGCONF

# Ajouter une entrée dans pg_hba.conf pour l'utilisateur de réplication
echo "host    replication     replicator      10.0.4.10/32    md5" >> $PGHBA

# Redémarrer PostgreSQL pour appliquer les modifications
systemctl restart postgresql

# Créer l'utilisateur de réplication
sudo -u postgres psql -c "CREATE USER $REPL_USER REPLICATION LOGIN ENCRYPTED PASSWORD '$REPL_PASSWORD';"

echo "Configuration du serveur principal terminée."
} >> $LOGFILE 2>&1