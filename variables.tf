variable "cidr_block" {
    type = list(string)
    default = ["172.20.0.0/16","172.20.10.0/24"]
}

variable "ports" {
    type = list(number)
    default = [22,80,443,8080,8081,9000]
}

variable "ami" {
    type = string
    default = "ami-0d80c4e4338722fc6"
}

variable "key_name" {
    type = string
    default = "nagapair"
}

variable "security" {
    type = string
    default = "MyLab Security Group"
}

variable "subnet" {
    type = string
    default = "subnet-0ca4000a485ddfabc"
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}

variable "instance_type_for_nexus" {
    type = string
    default = "t2.medium"
}
