# ubuntu-server-build
Ubuntu-based LAMP server
## Installation
Load a fresh installation of Ubuntu, and execute the following commands as root
```bash
git clone https://github.com/massyn/ubuntu-server-build
cd ubuntu-server-build
bash install.sh
```
To install a web server, execute
```bash
bash setup_web.sh
bash harden_web.sh
```
To install a database, execute
```bash
bash setup_db.sh
```
## Operations
### Web server
To create a new website, you will need to ensure that the DNS is pointing to the server.  If you'd like the site to have SSL, you can use the free Let's Encrypt certificate.  To issue a certificate, use the command :
```bash
letsencrypt.sh mywebsite.com
```
Following that, execute the command to setup the webserver
```bash
setup_web.sh mywebsite.com
```

### Database
To create a new database, execute the following command
```bash
setup_db.sh mydbname
```
