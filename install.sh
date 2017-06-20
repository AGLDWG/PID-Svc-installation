# update machine, set time
sudo apt update
sudo timedatectl set-timezone Australia/Brisbane

# install the PID Svc repos
sudo apt install -y git
git clone https://github.com/AGLDWG/PID-Svc-installation.git pid-svc-installation
git clone https://github.com/AGLDWG/PID-Svc-backup.git pid-svc-backup

# make the repo required for backup staging
mkdir backup
cd backup
git init
cd ..

# install things
sudo apt install -y tomcat7
sudo apt install -y tomcat7-admin
sudo apt install -y apache2
sudo apt install -y postgresql
sudo apt install -y postgresql-contrib
sudo apt install -y unzip

# environment variables
sudo sh -c 'echo "JAVA_HOME=\"/usr/lib/jvm/default-java\"" >> /etc/environment'
sudo sh -c 'echo "TOMCAT_HOME=\"/var/lib/tomcat7/\"" >> /etc/environment'
sudo sh -c 'echo "CATALINA_HOME=\"/usr/share/tomcat7\"" >> /etc/environment'
sudo sh -c 'echo "CATALINA_BASE=\"/var/lib/tomcat7/\"" >> /etc/environment'
source /etc/environment

cd pid-svc-installation

# 
#	Tomcat
#
wget https://cgsrv1.arrc.csiro.au/swrepo/PidService/jenkins/trunk/pidsvc-latest.war

# move the Tomcat site config files to their homes
sudo cp install/environment.xml /etc/tomcat7/Catalina/localhost/environment.xml
sudo cp install/governance.xml /etc/tomcat7/Catalina/localhost/governance.xml
sudo cp install/infrastructure.xml /etc/tomcat7/Catalina/localhost/infrastructure.xml
sudo cp install/infrastructure.xml /etc/tomcat7/Catalina/localhost/maritime.xml
sudo cp install/reference.xml /etc/tomcat7/Catalina/localhost/reference.xml
sudo cp install/transport.xml /etc/tomcat7/Catalina/localhost/transport.xml

# replace the password tokens in the Tomcat site files with real ones
sudo sed -i "s/ENVIRONMENT_PWD/$ENVIRONMENT_PWD/g" /etc/tomcat7/Catalina/localhost/environment.xml
sudo sed -i "s/GOVERNANCE_PWD/$GOVERNANCE_PWD/g" /etc/tomcat7/Catalina/localhost/governance.xml
sudo sed -i "s/INFRASTRUCTURE_PWD/$INFRASTRUCTURE_PWD/g" /etc/tomcat7/Catalina/localhost/infrastructure.xml
sudo sed -i "s/MARITIME_PWD/$MARITIME_PWD/g" /etc/tomcat7/Catalina/localhost/maritime.xml
sudo sed -i "s/REFERENCE_PWD/$REFERENCE_PWD/g" /etc/tomcat7/Catalina/localhost/reference.xml
sudo sed -i "s/TRANSPORT_PWD/$TRANSPORT_PWD/g" /etc/tomcat7/Catalina/localhost/transport.xml

# make dirs for all the Tomcat sites
sudo mkdir -p /usr/local/pidsvc/environment
sudo mkdir /usr/local/pidsvc/governance
sudo mkdir /usr/local/pidsvc/infrastructure
sudo mkdir /usr/local/pidsvc/maritime
sudo mkdir /usr/local/pidsvc/reference
sudo mkdir /usr/local/pidsvc/transport

$ unzip the PIDSvc file from the war into each site
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/environment/
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/governance/
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/infrastructure/
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/maritime/
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/reference/
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/transport/

# postgres Java driver
wget https://jdbc.postgresql.org/download/postgresql-42.1.1.jar
sudo cp postgresql-42.1.1.jar $CATALINA_HOME/lib/

# Tomcat admin
sudo nano /var/lib/tomcat7/conf/tomcat-users.xml
''' Add:
<role rolename="manager-gui"/>
<user username="pidsvcadmin" password="xxx" roles="manager-gui"/>
'''

sudo service tomcat7 restart

#
#	Apache
#
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_html
sudo a2enmod xml2enc
sudo a2enmod proxy_ajp
sudo a2enmod filter
sudo a2enmod headers
sudo a2enmod rewrite

# logging
sudo mkdir /var/log/apache2/environment.data.gov.au
sudo touch /var/log/apache2/environment.data.gov.au/access.log
sudo touch /var/log/apache2/environment.data.gov.au/error.log
sudo mkdir /var/log/apache2/governance.data.gov.au
sudo touch /var/log/apache2/governance.data.gov.au/access.log
sudo touch /var/log/apache2/governance.data.gov.au/error.log
sudo mkdir /var/log/apache2/infrastructure.data.gov.au
sudo touch /var/log/apache2/infrastructure.data.gov.au/access.log
sudo touch /var/log/apache2/infrastructure.data.gov.au/error.log
sudo mkdir /var/log/apache2/maritime.data.gov.au
sudo touch /var/log/apache2/maritime.data.gov.au/access.log
sudo touch /var/log/apache2/maritime.data.gov.au/error.log
sudo mkdir /var/log/apache2/reference.data.gov.au
sudo touch /var/log/apache2/reference.data.gov.au/access.log
sudo touch /var/log/apache2/reference.data.gov.au/error.log
sudo mkdir /var/log/apache2/transport.data.gov.au
sudo touch /var/log/apache2/transport.data.gov.au/access.log
sudo touch /var/log/apache2/transport.data.gov.au/error.log

# remove the unused site definition
sudo rm /etc/apache2/sites-available/default-ssl.conf

sudo cp install/environment.data.gov.au.conf /etc/apache2/sites-available/environment.data.gov.au.conf
sudo cp install/governance.data.gov.au.conf /etc/apache2/sites-available/governance.data.gov.au.conf
sudo cp install/infrastructure.data.gov.au.conf /etc/apache2/sites-available/infrastructure.data.gov.au.conf
sudo cp install/maritime.data.gov.au.conf /etc/apache2/sites-available/maritime.data.gov.au.conf
sudo cp install/reference.data.gov.au.conf /etc/apache2/sites-available/reference.data.gov.au.conf
sudo cp install/transport.data.gov.au.conf /etc/apache2/sites-available/transport.data.gov.au.conf

sudo htpasswd -b -c /etc/.htpasswd environment $ENVIRONMENT_PWD
sudo htpasswd -b /etc/.htpasswd governance $GOVERNANCE_PWD
sudo htpasswd -b /etc/.htpasswd infrastructure $MARITIME_PWD
sudo htpasswd -b /etc/.htpasswd maritime $INFRASTRUCTURE_PWD
sudo htpasswd -b /etc/.htpasswd reference $REFERENCE_PWD
sudo htpasswd -b /etc/.htpasswd transport $TRANSPORT_PWD

sudo a2ensite environment.data.gov.au.conf
sudo a2ensite governance.data.gov.au.conf
sudo a2ensite infrastructure.data.gov.au.conf
sudo a2ensite maritime.data.gov.au.conf
sudo a2ensite reference.data.gov.au.conf
sudo a2ensite transport.data.gov.au.conf

sudo service apache2 restart

#
#	Postgres
#
# set postgres auth type
sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/9.5/main/pg_hba.conf
sudo service postgresql restart

# prepare the change ownership script
sudo mkdir /home/postgres
sudo cp passwords.txt /home/postgres
sudo chown -R postgres /home/postgres

# become postgres user
sudo su - postgres
source /home/postgres/passwords.txt

#
#	create DBs
#
# create DB users
#psql -c "CREATE USER \"pidsvc-admin\" WITH PASSWORD 'nothing';"
psql -c "CREATE USER environment WITH PASSWORD '$ENVIRONMENT_PWD';"
psql -c "CREATE USER governance WITH PASSWORD '$GOVERNANCE_PWD';"
psql -c "CREATE USER infrastructure WITH PASSWORD '$INFRASTRUCTURE_PWD';"
psql -c "CREATE USER maritime WITH PASSWORD '$MARITIME_PWD';"
psql -c "CREATE USER reference WITH PASSWORD '$REFERENCE_PWD';"
psql -c "CREATE USER transport WITH PASSWORD '$TRANSPORT_PWD';"

# create DBs
createdb environment -O environment
createdb governance -O governance
createdb infrastructure -O infrastructure
createdb maritime -O maritime
createdb reference -O reference
createdb transport -O transport

# get the DB setup script
wget https://www.seegrid.csiro.au/subversion/PID/trunk/pidsvc/src/main/db/postgresql.sql

# run the DB setup script, changing the owner each time
sed -i 's/pidsvc-admin/environment/g' postgresql.sql
psql -d environment -f postgresql.sql
sed -i 's/environment/governance/g' postgresql.sql
psql -d governance -f postgresql.sql
sed -i 's/governance/infrastructure/g' postgresql.sql
psql -d infrastructure -f postgresql.sql
sed -i 's/infrastructure/maritime/g' postgresql.sql
psql -d maritime -f postgresql.sql
sed -i 's/maritime/reference/g' postgresql.sql
psql -d reference -f postgresql.sql
sed -i 's/reference/transport/g' postgresql.sql
psql -d transport -f postgresql.sql

# become ubuntu user
exit

#
#	PID Svc home page
#
sudo cp index.html /var/www/html/

