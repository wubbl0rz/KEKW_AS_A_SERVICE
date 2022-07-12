# Terraform 

Terraform startet die definierte Anzahl von Servern auf der Hetzner Cloud.
Zusätzlich wird ein LB gestartet der die Anfragen weiterleitet.

Nach dem Ausführen von Terraform generiert es eine _hosts_ Datei.
Diese kann verwendet werden um mit Ansible den krassen _kekw_ service zu deployn

## Config
Die Anzahl der Server kann in der Variables Datei angepasst werden.
Beim deployen der Resourcen frägt tf dich nach dem hetzner key und dem public key für ssh
Den kannst du in die console angeben oder in einer _terraform.tfvars_ Datei hinterlegen.

> siehe terraform.tfvars.example


## Usage
Download dependencies
```
terraform init
```
Deploy resources
```
terraform apply
```
Destroy resources
```
terraform destroy
```
