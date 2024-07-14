 /*
****************************************VPC, RDS **********************VPC, RDS *******************VPC, RDS *************** VPC, RDS 
****************************************VPC, RDS **********************VPC, RDS *******************VPC, RDS *************** VPC, RDS 
****************************************VPC, RDS **********************VPC, RDS *******************VPC, RDS *************** VPC, RDS 
*/


provider "aws" {
  region = "eu-west-2"
}

//******************************************************** vpc - main 
resource "aws_vpc" "vpc" {
    cidr_block = "192.168.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
      Name = "vpc"
    }
}
//******************************************************** public subnet
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "192.168.5.0/24"
    availability_zone = "eu-west-2a"
    map_public_ip_on_launch = true
    tags = {
      Name = "public_subnet"
    }
}
// Create Public Intenet Gateway
 /*An Internet Gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between
  instances in your VPC and the internet. It enables resources within your VPC to gain access to the internet and vice versa. */

resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "public_igw"
  }
}

// Route Table for public subnet
resource "aws_route_table" "rout_table_public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block =  "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_igw.id
  }
  tags = {
    Name = "Route_table_public"
  }
}
// Route Table Assocation (public subnet)
resource "aws_route_table_association" "name" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.rout_table_public.id  
}

 
// Security Group for public subnet 
resource "aws_security_group" "sg_for_publicsubnet" {
  name        = "wp"
  description = "Allow TLS inbound traffic-2"
  vpc_id      = aws_vpc.vpc.id


 ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "http2"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "wp-sg"
  }
}

// This Instance is on the public subnet 
/*
resource "aws_instance" "wp-os" {
  ami           = "ami-05d929ac8893c382f"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [ aws_security_group.sg_for_publicsubnet.id ]
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
      Name = "webserver"
    }
}*/


resource "aws_instance" "web_server" {
  ami                    = "ami-0fe310dde2a8fdc5c"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_for_publicsubnet.id]
  subnet_id              = aws_subnet.public_subnet.id
  key_name = "access_to_ec2"

  tags = {
    Name = "web_server"
  }
}

output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}


/*
resource "aws_key_pair" "my_key_pair" {
  key_name   = "new-eks-key-pair"
   //public_key = "AAAAB3NzaC1yc2EAAAADAQABAAABAQCZ5xTteYumpx59F4njPWkxBvrziDrP6aOHh2BKpY86HFBglMxIFGfHvm+nTMoTCK3UkNGzVKwD4Ihr8AMJ+zux/fs2+NPqh3mTRxvC25wHh2Q14N34ddtgiEq+Xb7bC63cd/GQv4PLirAr5TBjWtlwQVuLIdnA0H2n0Bx3h85rZ1dszbXjYP/IMKKBsYtdj5i7kEBdsUsT+78RZL/A7MTEZMUh+nzTrjPTAhQbGowjMQTwvWufgdK+l3f6zbK7FDwKhnzfcw3rdiP4f667r1vtA0PNfsQuViicuQebkEg98IqPT5NLIAJj529x1ppD87+z5z56W9DtS4SXIhIIzATb"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZ5xTteYumpx59F4njPWkxBvrziDrP6aOHh2BKpY86HFBglMxIFGfHvm+nTMoTCK3UkNGzVKwD4Ihr8AMJ+zux/fs2+NPqh3mTRxvC25wHh2Q14N34ddtgiEq+Xb7bC63cd/GQv4PLirAr5TBjWtlwQVuLIdnA0H2n0Bx3h85rZ1dszbXjYP/IMKKBsYtdj5i7kEBdsUsT+78RZL/A7MTEZMUh+nzTrjPTAhQbGowjMQTwvWufgdK+l3f6zbK7FDwKhnzfcw3rdiP4f667r1vtA0PNfsQuViicuQebkEg98IqPT5NLIAJj529x1ppD87+z5z56W9DtS4SXIhIIzATb imported-openssh-key"
}*/


// *********************************************Private Subnet - database etc - With internte access 


resource "aws_eip" "ip" {
  tags = {
    Name = "eip"
  }
}

resource "aws_subnet" "private_subnet_02" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "192.168.7.0/24"
  availability_zone = "eu-west-2b"
  tags = {
    Name = "private_subnet_02"
  }
}
resource "aws_subnet" "private_subnet_01" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "192.168.6.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "private_subnet_01"
  }
}

 

resource "aws_instance" "jump_server" {
  ami           = "ami-0fe310dde2a8fdc5c"
  instance_type = "t2.micro"
 // key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_for_jumpserver.id]
  subnet_id     = aws_subnet.private_subnet_01.id

  tags = {
    Name = "jump_server"
  }
}


 


resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.ip.id
  subnet_id     = aws_subnet.public_subnet.id // point to public subnet allways 
  tags = {
    Name = "nat_gateway"
  }
}

resource "aws_route_table" "route_table_jump_server" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "route_table_jump_server"
  }
}

 resource "aws_route_table_association" "associate2" {
  subnet_id      = aws_subnet.private_subnet_01.id
  route_table_id = aws_route_table.route_table_jump_server.id
}


resource "aws_security_group" "sg_for_jumpserver" {
  name        = "basic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id
 
 ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 tags = {
    Name = "jumpserver_sg"
  }
}




# Create Security Group for RDS
resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Adjust this to be more specific if needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}


# Create DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_01.id, aws_subnet.private_subnet_02.id]

  tags = {
    Name = "main-subnet-groupp"
  }
}

# Create RDS Instance
resource "aws_db_instance" "default" {
  identifier           = "myapp-dev"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t3.micro"
  db_name              = "mydatabase"
  username             = "dbadmin"  # Choose a valid username here
  password             = "mypassword123"
  availability_zone    = "eu-west-2a"  # Ensure this is the correct AZ
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot  = true
  publicly_accessible  = true
  deletion_protection  = false

  tags = {
    Name = "mydatabase"
  }
}




/* 
1. webserver - apachi 
2. DB - mariadb 
3. Route 53 
3.1 Using domain name name - www.ryanisha.co.uk
3.1 create hosted zone 
3.2 Setup A record - helps to point to EC2 or Fargate, EKS, api gatewasy etc
3.3 Setup Name server record

//Reference for route53
https://www.youtube.com/watch?v=5EJwxQ41RbY

sudo su - 
cat /etc/os-release
sudo dnf install -y httpd php php-mysqli mariadb105
// to connect to mariadb using the endpoint
mysql -h mariadb-instance.cv0ykmwaiopx.us-west-2.rds.amazonaws.com -P 3306 -u admin -p
SHOW DATABASES;


Reference
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Tutorials.WebServerDB.CreateWebServer.html
 
//tgik record details 
ns-1287.awsdns-32.org.
ns-391.awsdns-48.com.
ns-912.awsdns-50.net.
ns-2037.awsdns-62.co.uk.
 */
/*


***************************
***************************
*/
// Works  443 
// ***********************************************  Host Zone Allready created in AWS Console called tgik.uk
// Note : I have Already create host zone for tgik.uk and the NS details are entered in godaddy.com
// Fetching Name Server list, this host entry was already made  this server 

/*
data "aws_route53_zone" "tgik_uk" {
  name = "tgik.uk" 
}
//retrive the zone id
output "tgik_name_hosted_zone_id" {
  value = data.aws_route53_zone.tgik_uk.zone_id
}


// Creating A record in route 53 
resource "aws_route53_record" "Enter_A_rec_in_r53" {
  zone_id = data.aws_route53_zone.tgik_uk.zone_id
  name    = "tgik.uk"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.web_server.public_ip]
}
*/

