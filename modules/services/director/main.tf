resource aws_instance director {
  ami = var.image_id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }

  vpc_security_group_ids = [aws_security_group.director.id]

  key_name = var.director_key_pair_name

  tags = {
    Name = "director"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = file("director.pem")
  }

  provisioner "remote-exec" {
    inline = ["echo \"Hello, World from $(uname -smp)\""]
  }
}

resource aws_security_group director {
  name = "director"
}

resource aws_security_group_rule director-outbound {
  type = "egress"
  security_group_id = aws_security_group.director.id

  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource aws_security_group_rule director-ssh-rule {
  type = "ingress"
  security_group_id = aws_security_group.director.id
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
