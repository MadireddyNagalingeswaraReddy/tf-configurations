sudo yum remove java*
sudo yum install java-1.8.0-openjdk* -y
java -version
sudo mkdir /app && cd /app
sudo rm -rf /opt/nexus*
sudo rm -rf /etc/init.d/nexus
sudo wget -O nexus.tar.gz https://download.sonaty
sudo tar -xvf nexus.tar.gz
sudo mv nexus-3* nexus
sudo adduser nexus
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work
sudo vi  /app/nexus/bin/nexus.rc
sudo vi /etc/systemd/system/nexus.service
sudo chkconfig nexus on
sudo systemctl start nexus
sudo systemctl status nexus