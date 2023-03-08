terraform { 
  backend "s3" { 
    bucket         = "terraform-state-file-backend-bucket" 
    region         = "us-east-1" 
    key            = "webapp/terraform.tfstate"  
  }
}