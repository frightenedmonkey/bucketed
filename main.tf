// We need four separate entities to create the s3 bucket backed site
// 1. The s3 bucket. This should be private
// 2. A TLS cert created by ACM
// 3. The Cloudfront distribution that fronts the bucket
// 4. IAM permissions allowing cloudfront to talk to the s3 bucket

resource "aws_s3_bucket" "main" {
  bucket = "${var.domain}"
  acl    = "public-read"
  policy = "${data.aws_iam_policy_document.main.json}"

  tags {
    "Name" = "${var.domain}"
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

data "aws_iam_policy_document" "main" {
  statement {
    sid = "publicWebsiteBucket"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.domain}/*",
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}

data "aws_route53_zone" "main" {
  name = "${var.domain}"
}

resource "aws_acm_certificate" "main" {
  domain_name = "${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.main.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.main.domain_validation_options.0.resource_record_value}"]

  zone_id = "${data.aws_route53_zone.main.zone_id}"
  ttl     = 60
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = "${aws_acm_certificate.main.arn}"

  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}"
  ]
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = "${aws_s3_bucket.main.website_endpoint}"
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

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    target_origin_id       = "S3-${aws_s3_bucket.main.id}"
    viewer_protocol_policy = "redirect-to-https"

    // These are the TTL defaults as specified at
    // https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // See price class information here:
  // https://aws.amazon.com/cloudfront/pricing/
  price_class = "${var.price_class}"
  enabled = true

  viewer_certificate {
    acm_certificate_arn      = "${aws_acm_certificate.main.arn}"
    minimum_protocol_version = "${var.minimum_tls_protocol}"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_route53_record" "main" {
  name    = "${var.domain}"
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  type    = "A"

  alias {
    evaluate_target_health = false
    name    = "${aws_cloudfront_distribution.main.domain_name}"
    zone_id = "${aws_cloudfront_distribution.main.hosted_zone_id}"
  }
}
