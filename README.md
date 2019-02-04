# Jenkins Ansible Test Image

Jenkins docker image for Ansible playbook and role testing.

## How to Develop

Running this image on my Mac causes docker to crash ramdonly, sometimes it
crashs a couple of minutes after starting, sometimes hours after.
So, I use a vagrant machine to develop on.

To do the same, you'll need:

 - Ansible
 - Vagrant
 - VirtualBox / VMware

Once that software is installed, start the dev box

 1. `cd` into this directory.
 2. `cd` into `dev/`
 3. Install ansible-role dependencies -- `ansible-galaxy install -r requirements.yml`
 4. Start the vagrant box --`vagrant up`
 5. SSH into the vagrant box -- `vagrant ssh`
 6. `cd` into `/docker-jenkins-ansible`, the mounted project directory
 7. Hack away :-)


## How to Build

This image is built on a personal Jenkins server automatically and push to
Docker Hub. But should you wish to build the image locally, do the following:

  1. [Install Docker](https://docs.docker.com/engine/installation/).
  2. `cd` into this directory.
  3. Run `docker build -t jenkins-ansible .`

> Note: Switch between `master` and `testing` depending on whether you want the extra testing tools present in the resulting image.


## How to Use

  1. [Install Docker](https://docs.docker.com/engine/installation/).
  2. Pull this image from Docker Hub: `docker pull dankempster/jenkins-ansible:latest` (or use the image you built earlier, e.g. `jenkins-ansible`).
  3. Run a container from the image: `docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro dankempster/jenkins-ansible:latest` (to test my Ansible roles, I add in a volume mounted from the current working directory with ``--volume=`pwd`:/etc/ansible/roles/role_under_test:ro``).
  4. Use Ansible inside the container:
    a. `docker exec --tty [container_id] env TERM=xterm ansible --version`
    b. `docker exec --tty [container_id] env TERM=xterm ansible-playbook /path/to/ansible/playbook.yml --syntax-check`


## Notes

I use Docker to test my Ansible roles and playbooks on multiple OSes using CI tools like Jenkins and Travis. This container allows me to test roles and playbooks using Ansible running locally inside the container.

> **Important Note**: I use this image for testing in an isolated environment—not for production—and the settings and configuration used may not be suitable for a secure and performant production environment. Use on production servers/in the wild at your own risk!

## Author

Inspired by [work](https://github.com/geerlingguy/docker-debian9-ansible) from [Jeff Geerling](https://www.jeffgeerling.com/), author of [Ansible for DevOps](https://www.ansiblefordevops.com/). Modified by Dan Kempster.
