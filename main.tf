locals {
  index_doc = "index.html"
  error_doc = "error.html"
}

resource "random_id" "suffix" {
  byte_length = 3
}

locals {
  bucket_name = "static-site-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true   
  tags          = var.project_tags
}


resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = local.index_doc
  }

  error_document {
    key = local.error_doc
  }

  depends_on = [
    aws_s3_bucket_public_access_block.this,
    aws_s3_bucket_ownership_controls.this
  ]
}


data "aws_iam_policy_document" "public_read" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json
  depends_on = [aws_s3_bucket_public_access_block.this]
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.this.website_endpoint
}



resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = local.index_doc
  source       = "${path.module}/files/${local.index_doc}"
  content_type = "text/html"
  etag         = filemd5("${path.module}/files/${local.index_doc}")

  tags = merge(var.project_tags, {
    Role = "WebsiteIndex"
  })

  depends_on = [
    aws_s3_bucket_website_configuration.this
  ]
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = local.error_doc
  source       = "${path.module}/files/${local.error_doc}"
  content_type = "text/html"
  etag         = filemd5("${path.module}/files/${local.error_doc}")

  tags = merge(var.project_tags, {
    Role = "WebsiteError"
  })

  depends_on = [
    aws_s3_bucket_website_configuration.this
  ]
}
