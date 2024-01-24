resource "aws_db_instance" "mydb" {
  identifier           = "dev.db_instance_identifier"
  allocated_storage    = 200
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"  # You can replace this with the desired version
  instance_class       = "db.t3.micro"
  username             = "test.db_instance"
  password             = "testinstance123"
  db_name              = "aplication.db"
  publicly_accessible = true
  multi_az             = false
  availability_zone    = data.aws_availability_zones.available.names[0]  # Adjust the index as needed

  vpc_security_group_ids = ["aws_security_group.rds_sg.id"]

  tags = {
    Name = "my-rds-instance"
  }
}

# configured aws provider with proper credentials


# create default vpc if one does not exit
resource "aws_vpc" "test_vpc1" {

  tags = {
    Name = "default vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create a default subnet in the first az if one does not exit
resource "aws_subnet" "test_instance6" {
  vpc_id  = aws_vpc.test_vpc1.id 
  availability_zone = data.aws_availability_zones.available.names[0]
}

# create a default subnet in the second az if one does not exit
resource "aws_subnet" "test_instance5" {
 vpc_id  = aws_vpc.test_vpc1.id
  availability_zone = data.aws_availability_zones.available.names[1]
}

# create security group for the web server
resource "aws_security_group" "webserver_security_group" {
  name        = "webserver security group"
  description = "enable http access on port 80"
  vpc_id      = aws_vpc.test_vpc1.id

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =["0.0.0.0/0"] 
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"] 
  }

  tags   = {
    Name = "webserver_security_group"
  }
}

# create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "database security group"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = aws_vpc.test_vpc1.id

  ingress {
    description      = "mysql/aurora access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.webserver_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "database security group"
  }
}


# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "database_subnet"
  subnet_ids   = [aws_subnet.test_instance6.id, aws_subnet.test_instance5.id]
  description  = "subnet for database"

  tags   = {
    Name = "database_subnet"
  }
}


