### Introduction
The TitanX servers uses Ubuntu 16.04 OS. The docker image lives in `/var/lib/docker`, but the `/var` partition is too small to fit in our docker images. The `/usr` is relatively large. So we need to change the image storage to `/usr`. 

### Plan
- stop docker service
- copy docker directory to /usr/local/docker
- create symbolic link from `/var/lib/docker` to `/usr/local/docker`
- restart docker service

### Operations

    sudo hostname Seung-titan03
    sudo systemctl restart docker nvidia-docker
    sudo systemctl stop docker
    sudo mv /var/lib/docker /usr/local/
    sudo ln -s /usr/local/docker /var/lib/docker
    sudo systemctl edit nvidia-docker

add following:
```
[Service]
ExecStart=
ExecStart=/usr/bin/nvidia-docker-plugin -s $SOCK_DIR -d /usr/local/nvidia-docker-test
```

continue commands:

    sudo mkdir /usr/local/nvidia-docker-test
    sudo chown nvidia-docker /usr/local/nvidia-docker-test

restart and check:

    sudo systemctl restart docker nvidia-docker
    systemctl status docker

### References

- [the special treatment for Ubuntu 16.04](https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169/17)
- [nvidia docker issue](https://github.com/NVIDIA/nvidia-docker/issues/133)
- [create volume permission error](https://github.com/NVIDIA/nvidia-docker/issues/148)

## NIS service

### Titan01 as NIS server 

[manual for ubuntu16.04](https://www.server-world.info/en/note?os=Ubuntu_16.04&p=nis)


#### Fix an issue
this will run with some error:
```
Running /var/yp/Makefile...
make[1]: Entering directory '/var/yp/seunglab'
Updating passwd.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating passwd.byuid...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating group.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating group.bygid...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating hosts.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating hosts.byaddr...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating rpc.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating rpc.bynumber...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating services.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating services.byservicename...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating netid.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating protocols.bynumber...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating protocols.byname...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating netgroup...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating netgroup.byhost...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating netgroup.byuser...
failed to send 'clear' to local ypserv: RPC: Port mapper failureUpdating shadow.byname... Ignored -> merged with passwd
make[1]: Leaving directory '/var/yp/seunglab'
```

restart some service fixed this:

    systemctl restart portmap ypserv

### Configure in slaves

[slave configuration](https://www.server-world.info/en/note?os=Ubuntu_16.04&p=nis&f=2)

seems that we still need old setting, not sure which one take effect.

[some useful other steps](https://help.ubuntu.com/community/SettingUpNISHowTo)


Edit /etc/yp.conf and add the line:

```
ypserver 123.45.67.89
ypserver 987.65.43.21
```

Where 123.45.67.89 and 987.65.43.21 are the NIS servers.


It is probably a good idea to then add a portmap line to /etc/hosts.allow for security reasons:

    portmap : <NIS server IP address>


restart both portmap and NIS

    sudo systemctl restart portmap nis

## NFS mount

I first modified  master  /ect/exports with:

     /mnt/data01/ seung-titan*.pni.princeton.edu(rw,sync,no_root_squash)
     /mnt/data02/ seung-titan*.pni.princeton.edu(rw,sync,no_root_squash)

I've modified  /etc/fstab in all nodes adding, which should mount when the system is rebooted: (haven't tested because I shouldn't reboot now)

    seung-titan01.pni.princeton.edu:/mnt/data01 /mnt/data01 nfs default 0 0
    seung-titan01.pni.princeton.edu:/mnt/data02 /mnt/data02 nfs default 0 0

In the meantime I called (files are accessible from nodes)

    sudo mount seung-titan01.pni.princeton.edu:/mnt/data01 /mnt/data01
    sudo mount seung-titan01.pni.princeton.edu:/mnt/data02 /mnt/data02

## Fix the DHCP constant request

in BIOS/PIMT/network

- set configure as `yes` to open setting
- change `DHCP` to `static`
- set configure back as `no` to avoid future change.
