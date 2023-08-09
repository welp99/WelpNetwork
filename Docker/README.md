# Install Docker

First, update your existing list of packages:
```bash
sudo apt update
```
Next, install a few prerequisite packages which let apt use packages over HTTPS:
```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```
Then add the GPG key for the official Docker repository to your system:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```
Add the Docker repository to APT sources:
```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```
Finally, install Docker:
```bash
sudo apt install docker-ce -y && sudo apt install docker -y && sudo apt install docker-compose -y
```

# Docker command without sudo

If you want to avoid typing sudo whenever you run the docker command, add your username to the docker group:
```bash
sudo usermod -aG docker ${USER}
```
To apply the new group membership, log out of the server and back in, or type the following:
```bash
su - ${USER}
```

For more detail information go to :
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
