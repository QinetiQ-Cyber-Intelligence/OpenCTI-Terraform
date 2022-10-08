
#####################################
# -- Public Subnet Configuration -- #
#####################################
resource "aws_subnet" "public" {
  vpc_id            = var.vpc_id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.resource_prefix}-public-${var.availability_zone}"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = var.public_route_table_id
}

resource "aws_eip" "this" {
  vpc              = true
  public_ipv4_pool = "amazon"
}
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public.id
}


######################################
# -- Private Subnet Configuration -- #
######################################
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_subnet" "private" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.resource_prefix}-private-${var.availability_zone}"
  }
}

resource "aws_vpc_endpoint_route_table_association" "private" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = var.vpc_s3_endpoint_id
}