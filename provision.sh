#!/bin/sh

# This is the main script for provisioning.  Out of this
# file, everything that builds the box is executed.

### Software ###
# NodeJS 0.10.25
# Ruby 2.1.1
# Apache
# MongoDB 2.4.9
# MySQL 5.6.16
# Ant

### NodeJS Global Modules ###
# Cucumber
# N
# Supervisor


### Build the box


# Make /opt directory owned by vagrant user
sudo chown vagrant:vagrant /opt/

### Update the system
sudo apt-get update


### Install system dependencies
sudo apt-get install -y ant apache2 build-essential curl g++ git libaio1 libaio-dev nfs-common openssl subversion


### NodeJS ###


### Node 0.10
# Download the binary
wget http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz -O /tmp/node-v0.10.26-linux-x64.tar.gz

# Unpack it
cd /tmp
tar -zxvf /tmp/node-v0.10.26-linux-x64.tar.gz
mv /tmp/node-v0.10.26-linux-x64 /opt/node-v0.10.26-linux-x64
ln -s /opt/node-v0.10.26-linux-x64 /opt/nodejs-0.10
sudo ln -s /opt/nodejs-0.10/bin/node /usr/bin/nodejs0.10


### Node 0.8
wget http://nodejs.org/dist/v0.8.26/node-v0.8.26-linux-x64.tar.gz -O /tmp/node-v0.8.26-linux-x64.tar.gz

# Unpack it
cd /tmp
tar -zxvf /tmp/node-v0.8.26-linux-x64.tar.gz
mv /tmp/node-v0.8.26-linux-x64 /opt/node-v0.8.26-linux-x64
ln -s /opt/node-v0.8.26-linux-x64 /opt/nodejs-0.8
sudo ln -s /opt/nodejs-0.8/bin/node /usr/bin/nodejs0.8


### Node 0.6
wget http://nodejs.org/dist/v0.6.12/node-v0.6.12.tar.gz -O /tmp/node-v0.6.12.tar.gz

# Unpack it
cd /tmp
tar -zxvf /tmp/node-v0.6.12.tar.gz
cd /tmp/node-v0.6.12
./configure --prefix=/opt/nodejs-v0.6.12-linux-x64
make
make install
ln -s /opt/nodejs-v0.6.12-linux-x64 /opt/nodejs-0.6
sudo ln -s /opt/nodejs-0.6/bin/node /usr/bin/nodejs0.6

# Set the path to v0.10
ln -s /opt/nodejs-0.10 /opt/nodejs

# Set the node_path
export NODE_PATH=/opt/nodejs/lib/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules
export NODE_PATH=$NODE_PATH:/usr/local/lib/node_modules

# Update NPM to the latest version
npm update npm -g

# Install global Node dependencies
/opt/nodejs/bin/npm install -g cucumber
/opt/nodejs/bin/npm install -g n
/opt/nodejs/bin/npm install -g supervisor
/opt/nodejs/bin/npm install -g commander
/opt/nodejs/bin/npm install -g fs-extra

/opt/nodejs/bin/npm config set loglevel http


# Install the latest version of Node 10
sudo n stable


### MongoDB ###


# Download it
wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.9.tgz -O /tmp/mongodb-linux-x86_64-2.4.9.tgz

# Create mongo user and group
sudo groupadd -g 550 mongodb
sudo useradd -g mongodb -u 550 -c "MongoDB Database Server" -M -s /sbin/nologin mongodb

# Unpack it and move to /opt directory
cd /tmp
tar -zxvf mongodb-linux-x86_64-2.4.9.tgz
mv /tmp/mongodb-linux-x86_64-2.4.9 /opt
ln -s /opt/mongodb-linux-x86_64-2.4.9 /opt/mongodb

# Create the directories
mkdir -p /opt/mongodb/data
mkdir -p /opt/mongodb/etc
mkdir -p /opt/mongodb/log
mkdir -p /opt/mongodb/run

# Set permissions:
sudo chown mongodb /opt/mongodb/data
sudo chown mongodb /opt/mongodb/log
sudo chown mongodb /opt/mongodb/run

# Create the config file
printf "port = 27017\nlogpath=/opt/mongodb/log/mongodb.log\nfork = true\ndbpath=/opt/mongodb/data\npidfilepath=/opt/mongodb/run/mongodb.pid\nnojournal=true" > /opt/mongodb/etc/mongodb.conf

# Create the init.d file
printf '#!/bin/bash\n\nControls the main MongoDB server daemon "mongod"\n### END INIT INFO\n\n\npid_file="/opt/mongodb/run/mongodb.pid"\n\n\n# abort if not being ran as root\nif [ "${UID}" != "0" ] ; then\n        echo "you must be root"\n        exit 20\nfi\n\n\nstatus() {\n        # read pid file, return if file does not exist or is empty\n        if [ -f "$pid_file" ] ; then\n                read pid < "$pid_file"\n                if [ -z "${pid}" ] ; then\n                        # not running (empty pid file)\n                        return 1\n                fi\n        else\n                # not running (no pid file)\n                return 2\n        fi\n\n        # pid file exists, check if it is stale\n        if [ -d "/proc/${pid}" ]; then\n                # it is running (pid file is valid)\n                return 0\n        else\n                # not running (stale pid file)\n                return 3\n        fi\n}\n\nshow_status() {\n       # get the status\n        status\n\n        case "$?" in\n      0)\n            echo "running (pid ${pid})"\n           return 0\n          ;;\n        1)\n            echo "not running (empty pid file)"\n           return 1\n          ;;\n        2)\n            echo "not running (no pid file)"\n          return 2\n          ;;\n        3)\n            echo "not running (stale pid file)"\n           return 3\n          ;;\n        *)\n            # should never get here\n           echo "could not get status"\n           exit 10\n   esac\n}\n\nstart() {\n  # return if it is already running\n if ( status ) ; then\n      echo "already running"\n        return 1\n  fi\n\n  # start it\n    echo "Starting MongoDB"\n   sudo /bin/bash -c "/opt/mongodb/bin/mongod --quiet -f /opt/mongodb/etc/mongodb.conf run"\n}\n\nstop() {\n   # return if it is not running\n if ( ! status ) ; then\n        echo "already stopped"\n        return 1\n  fi\n\n  # stop it\n # call status again to get the pid\n    status\n    echo "Stopping MongoDB (killing ${pid})"\n  kill "${pid}"\n}\n\n\ncase "$1" in\n    status)\n       show_status\n       ;;\n    start)\n        start\n     ;;\n    stop)\n     stop\n      ;;\n    *)\n        echo $"Usage: $0 {start|stop|status}"\n     exit 100\nesac\n\nexit $?\n\n' > /opt/mongodb/etc/init-script
chmod 755 /opt/mongodb/etc/init-script
sudo ln -s /opt/mongodb/etc/init-script /etc/init.d/mongodb

# Register the init.d file
sudo update-rc.d mongodb defaults

# Start MongoDB
sudo service mongodb start


### MySQL ###


# Download
wget http://downloads.sourceforge.net/project/mysql.mirror/MySQL%205.6.16/mysql-5.6.16-debian6.0-x86_64.deb -O /tmp/mysql-5.6.16-debian6.0-x86_64.deb

# Install
sudo dpkg -i /tmp/mysql-5.6.16-debian6.0-x86_64.deb

# Finish mysql installation
sudo groupadd mysql
sudo useradd -r -g mysql mysql
sudo chown -R mysql /opt/mysql/server-5.6/
sudo chgrp -R mysql /opt/mysql/server-5.6/
sudo /opt/mysql/server-5.6/scripts/mysql_install_db --user=mysql
sudo chown -R root /opt/mysql/server-5.6/
sudo chown -R mysql /opt/mysql/server-5.6/data
sudo mkdir -p /opt/mysql/server-5.6/log
sudo chown mysql /opt/mysql/server-5.6/log
sudo chmod 755 /opt/mysql/server-5.6/log

sudo cp /opt/mysql/server-5.6/support-files/mysql.server /etc/init.d/mysql.server
sudo update-rc.d mysql.server defaults

# Create /etc/my.cnf with the following content
printf '[mysqld]\n\n## General\ndatadir                         = /opt/mysql/server-5.6/data\nskip-name-resolve\nsql-mode                        = NO_ENGINE_SUBSTITUTION\n\n## Cache\nthread-cache-size               = 16\ntable-open-cache                = 4096\ntable-definition-cache          = 2048\nquery-cache-size                = 32M \nquery-cache-limit               = 1M\n\n## Per-thread Buffers\nsort-buffer-size                = 1M\nread-buffer-size                = 1M\nread-rnd-buffer-size            = 1M\njoin-buffer-size                = 1M\n\n## Temp Tables\ntmp-table-size                  = 32M \nmax-heap-table-size             = 64M \n\n## Networking\nback-log                        = 100\nmax-connect-errors              = 10000\nmax-allowed-packet              = 16M\ninteractive-timeout             = 3600\nwait-timeout                    = 600\n\n## MyISAM\nkey-buffer-size                 = 64M \nmyisam-sort-buffer-size         = 128M\n\n## InnoDB\ninnodb-buffer-pool-size        = 128M\ninnodb-log-file-size           = 100M\ninnodb-log-buffer-size         = 8M\ninnodb-file-per-table          = 1\ninnodb-open-files              = 300\n\n## Replication\nserver-id                       = 1\nrelay-log-space-limit           = 16G\nexpire-logs-days                = 7\n\n\n[mysqld_safe]\nlog-error                       = /opt/mysql/server-5.6/log/mysqld.log\nopen-files-limit                = 65535\n\n\n[mysql]\nno-auto-rehash' > /tmp/my.cnf
sudo mv /tmp/my.cnf /etc
sudo chown root:root /etc/my.cnf

# Start the service
sudo service mysql.server start

# Set the password/permissions
/opt/mysql/server-5.6/bin/mysqladmin -u root password 'password'

/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO root@'localhost' IDENTIFIED BY 'password';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO root@'127.0.0.1' IDENTIFIED BY 'password';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY 'password';"

/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "CREATE USER 'esgsys'@'localhost' IDENTIFIED BY 'esgsys';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "CREATE USER 'esgsys'@'127.0.0.1' IDENTIFIED BY 'esgsys';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "CREATE USER 'esgsys'@'%' IDENTIFIED BY 'esgsys';"

/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON esg.* TO 'esgsys'@'localhost';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT FILE ON *.* TO 'esgsys'@'localhost';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON esg.* TO 'esgsys'@'127.0.0.1';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT FILE ON *.* TO 'esgsys'@'127.0.0.1';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON esg.* TO 'esgsys'@'%';"
/opt/mysql/server-5.6/bin/mysql -u root -ppassword -e "GRANT FILE ON *.* TO 'esgsys'@'%';"


### Apache ###


# Create the home directory
sudo mkdir -p /var/www/html
sudo chmod 755 /var/www/html
sudo chown -R vagrant:vagrant /var/www
mv /var/www/index.html /var/www/html

# Already installed, just needs configuring
echo "ServerName localhost" > /tmp/servername
sudo mv /tmp/servername /etc/apache2/conf.d/servername

printf '# gzip compression as recommended by Rackspace\n\n############################################\n## enable apache served files compression\n## http://developer.yahoo.com/performance/rules.html#gzip\n<IfModule mod_deflate.c>\n\n    # Insert filter on all content\n    SetOutputFilter DEFLATE\n    # Insert filter on selected content types only\n    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript\n\n    # Netscape 4.x has some problems...\n    BrowserMatch ^Mozilla/4 gzip-only-text/html\n\n    # Netscape 4.06-4.08 have some more problems\n    BrowserMatch ^Mozilla/4\.0[678] no-gzip\n\n    # MSIE masquerades as Netscape, but it is fine\n    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html\n\n    # Dont compress images\n    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary\n\n    # Make sure proxies dont deliver the wrong content\n     Header append Vary Accept-Encoding env=!dont-vary\n\n</IfModule>\n\n############################################\n# Expires\n############################################\n<IfModule mod_expires.c>\n\n  ExpiresActive on\n  \n  ExpiresDefault                          "access plus 1 month"\n\n# cache.appcache needs re-requests in FF 3.6 (thanks Remy ~Introducing HTML5)\n  ExpiresByType text/cache-manifest       "access plus 0 seconds"\n\n# Your document html\n  ExpiresByType text/html                 "access plus 0 seconds"\n\n# Data\n  ExpiresByType text/xml                  "access plus 0 seconds"\n  ExpiresByType application/xml           "access plus 0 seconds"\n  ExpiresByType application/json          "access plus 0 seconds"\n\n# Feed\n  ExpiresByType application/rss+xml       "access plus 1 hour"\n  ExpiresByType application/atom+xml      "access plus 1 hour"\n\n# Favicon (cannot be renamed)\n  ExpiresByType image/x-icon              "access plus 1 week"\n\n# Media: images, video, audio\n  ExpiresByType image/gif                 "access plus 1 week"\n  ExpiresByType image/png                 "access plus 1 week"\n  ExpiresByType image/jpg                 "access plus 1 week"\n  ExpiresByType image/jpeg                "access plus 1 week"\n  ExpiresByType video/ogg                 "access plus 1 week"\n  ExpiresByType audio/ogg                 "access plus 1 week"\n  ExpiresByType video/mp4                 "access plus 1 week"\n  ExpiresByType video/webm                "access plus 1 week"\n\n# HTC files  (css3pie)\n  ExpiresByType text/x-component          "access plus 1 month"\n\n# Webfonts\n  ExpiresByType application/x-font-ttf    "access plus 1 month"\n  ExpiresByType font/opentype             "access plus 1 month"\n  ExpiresByType application/x-font-woff   "access plus 1 month"\n  ExpiresByType image/svg+xml             "access plus 1 month"\n  ExpiresByType application/vnd.ms-fontobject "access plus 1 month"\n\n# CSS and JavaScript\n  ExpiresByType text/css                  "access plus 1 year"\n  ExpiresByType application/javascript    "access plus 1 year"\n  ExpiresByType application/x-javascript  "access plus 1 year" \n\n</IfModule>' > /tmp/mod_gzip_mod_expires.conf
sudo mv /tmp/mod_gzip_mod_expires.conf /etc/apache2/mods-enabled

printf '# Originally from  https://github.com/h5bp/html5-boilerplate/blob/master/.htaccess\n\n# ----------------------------------------------------------------------\n# Proper MIME type for all files\n# ----------------------------------------------------------------------\n\n# JavaScript\n#   Normalize to standard type (its sniffed in IE anyways)\n\n#   tools.ietf.org/html/rfc4329#section-7.2\n\nAddType application/javascript         js jsonp\nAddType application/json               json\n\n\n# Audio\nAddType audio/ogg                      oga ogg\n\nAddType audio/mp4                      m4a f4a f4b\n\n\n# Video\nAddType video/ogg                      ogv\n\nAddType video/mp4                      mp4 m4v f4v f4p \n\nAddType video/webm                     webm\nAddType video/x-flv                    flv\n\n\n# SVG\n#   Required for svg webfonts on iPad\n\n#   twitter.com/FontSquirrel/status/14855840545\n\nAddType     image/svg+xml              svg svgz\nAddEncoding gzip                       svgz\n\n\n# Webfonts\nAddType application/vnd.ms-fontobject  eot\n\nAddType application/x-font-ttf         ttf ttc\nAddType font/opentype                  otf\n\nAddType application/x-font-woff        woff\n\n\n# Assorted types\nAddType image/x-icon                        ico\n\nAddType image/webp                          webp\nAddType text/cache-manifest                 appcache manifest\n\nAddType text/x-component                    htc\nAddType application/xml                     rss atom xml rdf\n\nAddType application/x-chrome-extension      crx\nAddType application/x-opera-extension       oex\n\nAddType application/x-xpinstall             xpi\nAddType application/octet-stream            safariextz\n\nAddType application/x-web-app-manifest+json webapp\n\nAddType text/x-vcard                        vcf\nAddType application/x-shockwave-flash       swf' > /tmp/more_mime_types.conf
sudo mv /tmp/more_mime_types.conf /etc/apache2/mods-enabled

sudo chown root:root /etc/apache2/mods-enabled/mod_gzip_mod_expires.conf
sudo chown root:root /etc/apache2/mods-enabled/more_mime_types.conf

printf '' > /tmp/default
sudo mv /tmp/default /etc/apache2/sites-available/default

sudo a2ensite default

sudo a2enmod deflate expires headers proxy proxy_http rewrite

sudo service apache2 restart



### Change hostname ###
echo "nodebox" > /tmp/hostname
sudo mv /tmp/hostname /etc/hostname


### Install Ruby ###

# Remove installed version
sudo apt-get purge ruby ruby-dev ruby1.8*

# Download the source code
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.1.tar.gz -O /tmp/ruby-2.1.1.tar.gz

# Unpack it
cd /tmp
tar -zxvf /tmp/ruby-2.1.1.tar.gz
cd  /tmp/ruby-2.1.1
./configure


### Install Ruby gems ###
sudo gem install git-up
sudo gem install travis
make
sudo make install



### Add binaries to path ###


# First run the command
export PATH=$PATH:/opt/mongodb/bin:/opt/mysql/server-5.6/bin:/opt/nodejs/bin
export NODE_PATH=/opt/nodejs/lib/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules
export NODE_PATH=$NODE_PATH:/usr/local/lib/node_modules/lib/node_modules:/usr/local/lib/node_modules

# Now save to the /etc/bash.bashrc file so it works on reboot
cp /etc/bash.bashrc /tmp/bash.bashrc
printf "\n#Add binaries to path\n\nexport PATH=$PATH:/opt/mongodb/bin:/opt/mysql/server-5.6/bin:/opt/nodejs/bin\nexport NODE_PATH=/opt/nodejs/lib/node_modules\nexport NODE_PATH=$NODE_PATH:/opt/dev/node_modules\nexport NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules" > /tmp/path
cat /tmp/path >> /tmp/bash.bashrc
sudo chown root:root /tmp/bash.bashrc
sudo mv /tmp/bash.bashrc /etc/bash.bashrc

# Add ifconfig to the path
sudo ln -s /sbin/ifconfig /usr/bin/ifconfig


### Update the /etc/hosts file ###
printf '127.0.0.1       localhost\n127.0.1.1       debian-squeeze.caris.de debian-squeeze nodebox\n\n# The following lines are desirable for IPv6 capable hosts\n::1     ip6-localhost ip6-loopback\nfe00::0 ip6-localnet\nff00::0 ip6-mcastprefix\nff02::1 ip6-allnodes\nff02::2 ip6-allrouters' > /tmp/hosts
sudo mv /tmp/hosts /etc/hosts


### Set a message of the day ###
sudo rm /etc/motd
sudo cp /vagrant/files/motd.txt /etc/motd


### Test that everything is installed ok ###
printf "\n\n--- Running post-install checks ---\n\n"
node /vagrant/files/postInstall.js


### Finished ###
printf "\n\n--- NodeBox is now built ---\n\n"
