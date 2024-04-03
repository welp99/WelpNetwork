# Gitlab install

## Pre-requis

- Ubuntu server CPU: 2 // RAM 4Go // Disk : 16Go

**Install and configure the necessary dependencies**

```bash

sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
```

**Add the GitLab package repository and install the package**

```bash
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
```

```bash
sudo EXTERNAL_URL="https://gitlab.your-domain.com" apt-get install gitlab-ce
```

### Create user

- Acces the GiLab Rails Console:

```bash
sudo gitlab-rails console
```

- Create User

```bash
user = User.new(username: 'username',name: 'name', email: 'example@mail.com', password: 'password', password_confirmation: 'password')
```

```bash
user.skip_confirmation!
user.save!
exit!
```
