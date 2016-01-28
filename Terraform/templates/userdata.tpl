#cloud-config
hostname: ${hostname}
disable_root: false
fqdn: ${hostname}
packages:
  - redhat-lsb-core
resolv_conf:
  domain: demo.maxserv.com
bootcmd:
  - echo ${master_ip} puppet >> /etc/hosts
  - rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
  - yum clean all
  - yum install puppet -y
  - mkdir -p /etc/facter/facts.d
  - echo "is_type=demo" > /etc/facter/facts.d/demo.txt
puppet:
  conf:
    agent:
      server: "puppet"
      certname: "${hostname}"