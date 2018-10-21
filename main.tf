// We need four separate entities to create the s3 bucket backed site
// 1. The s3 bucket. This should be private
// 2. A TLS cert created by ACM
// 3. The Cloudfront distribution that fronts the bucket
// 4. IAM permissions allowing cloudfront to talk to the s3 bucket

resource "aws_s3_bucket" "main" {
  bucket = "${var.domain}"
  acl    = "private"

  tags {
    "Name" = "${var.domain}"
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "aws_route53_zone" "main" {
  domain = "${var.domain}"
}

resource "aws_acm_certificate" "main" {
  domain      = "${var.domain}"
  subject_alternative_names = "${var.domain_sans}"

  // This module is only DNS validation for now as we can do it all in on apply
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "main" {
  name    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.main.id}"
  records = ["${aws_acm_certificate.main.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acn_certificate_validation" "main" {
  certificate_arn = "${aws_acm_certificate.main.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.main.fqdn}"
  ]
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = "${aws_s3_bucket.main.bucket_domain_name}"
    origin_id = "S3-${aws_s3_bucket.main.bucket}"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = [
        "TLSv1.2",
      ]
    }
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id     = "S3-${aws_s3_bucket.main.id}"
    view_protocol_policy = "redirect-to-https"

    // These are the TTL defaults as specified at
    // https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  // See price class information here:
  // https://aws.amazon.com/cloudfront/pricing/
  price_class = "${var.price_class}"
  enabled = true

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.main.arn}"
    minimum_protocol_version = "${var.minimum_tls_protocol}"
  }
}
