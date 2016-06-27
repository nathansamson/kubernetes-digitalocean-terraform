variable "size_lb" {
        default = "512mb"
}

resource "template_file" "haproxy" {
    count    = "1"
    
    template = "${file("04-haproxy.conf")}"
    vars {
        LB_BACKENDS80 = "${join("\n", formatlist("server %s %s:80 check", digitalocean_droplet.k8s_worker.*.name, digitalocean_droplet.k8s_worker.*.ipv4_address_private))}"
        LB_BACKENDS443 = "${join("\n", formatlist("server %s %s:443 check", digitalocean_droplet.k8s_worker.*.name, digitalocean_droplet.k8s_worker.*.ipv4_address_private))}"
        LB_BACKENDS2222 = "${join("\n", formatlist("server %s %s:2222 check", digitalocean_droplet.k8s_worker.*.name, digitalocean_droplet.k8s_worker.*.ipv4_address_private))}"
    }
}

resource "digitalocean_droplet" "haproxy" {
    count = "1"

    image = "coreos-stable"
    name = "${format("lb-%02d", count.index + 1)}"
    region = "${var.region}"
    size = "${var.size_lb}"
    user_data = "${template_file.worker_yaml.rendered}"
    private_networking = "true"
    ssh_keys = [
        "${var.ssh_fingerprint}"
    ]
    
    provisioner "local-exec" {
        command = "echo ${element(template_file.haproxy.*.rendered, count.index)} > haproxy-${count.index}"
    }
    
    provisioner "file" {
        source = "haproxy-${count.index}"
        destination = "/opt/haproxy.cfg"
        connection {
            user = "core"
        }
    }
}
