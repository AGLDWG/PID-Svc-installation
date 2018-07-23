# update machine, set time
sudo apt update
sudo apt -y upgrade
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
sudo apt install -y tomcat8
sudo apt install -y tomcat8-admin
sudo apt install -y apache2
sudo apt install -y postgresql
sudo apt install -y postgresql-contrib
sudo apt install -y unzip

# environment variables
sudo sh -c 'echo "JAVA_HOME=\"/usr/lib/jvm/default-java\"" >> /etc/environment'
sudo sh -c 'echo "TOMCAT_HOME=\"/var/lib/tomcat8/\"" >> /etc/environment'
sudo sh -c 'echo "CATALINA_HOME=\"/usr/share/tomcat8\"" >> /etc/environment'
sudo sh -c 'echo "CATALINA_BASE=\"/var/lib/tomcat8/\"" >> /etc/environment'
source /etc/environment

cd pid-svc-installation

#
#	Tomcat
#
wget https://cgsrv1.arrc.csiro.au/swrepo/PidService/jenkins/trunk/pidsvc-latest.war

# move the Tomcat site config files to its home
sudo cp install/linked.xml /etc/tomcat7/Catalina/localhost/linked.xml

# replace the password tokens in the Tomcat site files with real ones
sudo sed -i "s/LINKED_PWD/$LINKED_PWD/g" /etc/tomcat7/Catalina/localhost/linked.xml

# make dir for the Tomcat sites
sudo mkdir -p /usr/local/pidsvc/linked

$ unzip the PIDSvc file from the war into the site dir
sudo unzip pidsvc-latest.war -d /usr/local/pidsvc/linked/

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
sudo mkdir /var/log/apache2/linked.data.gov.au
sudo touch /var/log/apache2/linked.data.gov.au/access.log
sudo touch /var/log/apache2/linked.data.gov.au/error.log

# remove the unused site definition
sudo rm /etc/apache2/sites-available/default-ssl.conf

sudo cp linked.data.gov.au.conf /etc/apache2/sites-available/linked.data.gov.au.conf

sudo htpasswd -b -c /etc/.htpasswd linked $LINKED_PWD

sudo a2ensite linked.data.gov.au.conf

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
psql -c "CREATE USER linked WITH PASSWORD '$LINKED_PWD';"

# create DBs
createdb linked -O linked

# get the DB setup script
wget https://www.seegrid.csiro.au/subversion/PID/trunk/pidsvc/src/main/db/postgresql.sql

# run the DB setup script, changing the owner each time
sed -i 's/pidsvc-admin/linked/g' postgresql.sql
psql -d linked -f postgresql.sql

# become ubuntu user
exit
