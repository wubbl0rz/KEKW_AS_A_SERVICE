#cloud-config
users:
  - name: devops
    groups: users, admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${public_key}
package_update: true
package_upgrade: true
packages:
  - nginx
  - fail2ban
  - ufw
runcmd:
  - systemctl enable nginx
  - ufw allow 'Nginx HTTP'
  # - printf "[sshd]\nenabled = true\nbanaction = iptables-multiport" > /etc/fail2ban/jail.local
  # - systemctl enable fail2ban
  # - systemctl start fail2ban
  - ufw allow 'OpenSSH'
  - ufw enable
  - sed -ie '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  - sed -ie '/^PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
  - sed -ie '/^X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
  - sed -ie '/^#MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
  - sed -ie '/^#AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' /etc/ssh/sshd_config
  - sed -ie '/^#AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config
  - sed -ie '/^#AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh/authorized_keys/' /etc/ssh/sshd_config
  - sed -i '$a AllowUsers devops' /etc/ssh/sshd_config
  - systemctl restart ssh
  - rm /var/www/html/*
  - echo "Hello! I am Nginx @ $(curl -s ipinfo.io/ip)! This record added at $(date -u)." >>/var/www/html/index.html
