variable "size_lb" {
  default = "512mb"
}

variable "keepalivedstates" {
	default = "MASTER, BACKUP"
}

variable "keepalivedprios" {
	default = "200, 100"
}

resource "digitalocean_droplet" "haproxy" {
  count = "2"

  image = "fedora-24-x64"
  name = "${format("%slb-%02d", var.prefix, count.index + 1)}"
  region = "${var.region}"
  size = "${var.size_lb}"
  private_networking = "true"
  ssh_keys = ["${split(",", var.ssh_fingerprint)}"]

  provisioner "file" {
    source = "setup-ip.py"
    destination = "/usr/local/bin/assign-ip"
  }

  provisioner "remote-exec" {
    inline = [
      "dnf install haproxy keepalived python python-requests -y",
      "systemctl enable haproxy.service",
      "systemctl enable keepalived.service",
      "setsebool -P haproxy_connect_any 1",
      "setsebool -P deny_ptrace 0",
      "chmod +x /usr/local/bin/assign-ip",
      "curl -L -o droplan.tar.gz https://github.com/tam7t/droplan/releases/download/v1.0.1/droplan_1.0.1_linux_amd64.tar.gz",
      "tar xvzf droplan.tar.gz",
      "sudo mv droplan /usr/local/bin/",
      "(crontab -l; echo '*/10 * * * * DO_KEY=${var.do_read_token} PATH=/sbin /usr/local/bin/droplan >> /var/log/droplan 2>&1') | crontab - "
    ]
  }
}

resource "template_file" "haproxy-config" {
  count = "2"

  template = "${file("04-haproxy.conf")}"

  vars {
    SELF_IP = "${element(digitalocean_droplet.haproxy.*.ipv4_address, count.index)}"
    LB_BACKENDS80 = "${join("\n  ", formatlist("server %s %s:80 check port 9090", digitalocean_droplet.k8s_worker.*.name, digitalocean_droplet.k8s_worker.*.ipv4_address_private))}"
    LB_BACKENDS443 = "${join("\n  ", formatlist("server %s %s:443 check port 9090", digitalocean_droplet.k8s_worker.*.name, digitalocean_droplet.k8s_worker.*.ipv4_address_private))}"
    LB_BACKENDS2222 = "${join("\n  ", formatlist("server %s %s:2222 check port 9090", digitalocean_droplet.k8s_worker.*.name, digitalocean_droplet.k8s_worker.*.ipv4_address_private))}"
  }
}

resource "null_resource" "haproxy-config" {
  count = 2

  triggers {
    templates = "${element(template_file.haproxy-config.*.rendered, count.index)}"
  }

  connection {
    host = "${element(digitalocean_droplet.haproxy.*.ipv4_address, count.index)}"
  }

  provisioner "local-exec" {
    command = "echo '${element(template_file.haproxy-config.*.rendered, count.index)}' > $PWD/secrets/haproxy-${count.index}.cfg.rendered"
  }

  provisioner "file" {
    source = "./secrets/haproxy-${count.index}.cfg.rendered"
    destination = "/etc/haproxy/haproxy.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl restart haproxy.service"
    ]
  }
}

resource "template_file" "haproxy-keepalived" {
  count = 2

  template = "${file("04-haproxy-keepalived.conf")}"

  vars {
    SELF_IP = "${element(digitalocean_droplet.haproxy.*.ipv4_address_private, count.index)}"
    OTHER_IP = "${element(digitalocean_droplet.haproxy.*.ipv4_address_private, count.index + 1)}"
    STATE = "${element(split(",", var.keepalivedstates), signum(count.index))}"
    PRIORITY = "${element(split(",", var.keepalivedprios), signum(count.index))}"
    KEEPALIVED_PASSWORD = "${file("secrets/KEEPALIVED_TOKEN")}"
  }
}

resource "digitalocean_floating_ip" "haproxy-master" {
  region = "${var.region}"
}

resource "template_file" "master" {
  template = "${file("keepalived-master.sh")}"

  vars {
    FLOATING_IP = "${digitalocean_floating_ip.haproxy-master.ip_address}"
    DO_TOKEN = "${var.do_token}"
  }
}

resource "null_resource" "keepalived-config" {
  count = 2

  triggers {
    templates = "${element(template_file.haproxy-keepalived.*.rendered, count.index)}"
    floating = "${template_file.master.rendered}"
  }

  connection {
    host = "${element(digitalocean_droplet.haproxy.*.ipv4_address, count.index)}"
  }

  provisioner "local-exec" {
    command = "echo '${element(template_file.haproxy-keepalived.*.rendered, count.index)}' > $PWD/secrets/keepalived-${count.index}.cfg.rendered"
  }

  provisioner "local-exec" {
    command = "echo '${template_file.master.rendered}' > $PWD/secrets/master.sh.rendered"
  }

  provisioner "file" {
    source = "./secrets/keepalived-${count.index}.cfg.rendered"
    destination = "/etc/keepalived/keepalived.conf"
  }

  provisioner "file" {
    source = "./secrets/master.sh.rendered"
    destination = "/etc/keepalived/master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /etc/keepalived/master.sh",
      "systemctl restart keepalived.service"
    ]
  }
}
