curl -fsSL get.docker.com -o get-docker.sh;
sudo sh get-docker.sh;
git clone https://github.com/slogr/slogr-twamp.git;
cd slogr-twamp/agent/;
sudo docker compose up -d