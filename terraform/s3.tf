resource "aws_s3_bucket" "tf_s3_bucket" {
  bucket = "nodejs-bucket98654789"

  tags = {
    Name        = "Node js s3 bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "tf_s3_object" {
  bucket = aws_s3_bucket.tf_s3_bucket.bucket
  for_each = fileset("../public/images", "**") // ** will return all the files in the directory and subdirectories
  key    = "images/${each.key}"
  source = "../public/images/${each.key}"

  
}