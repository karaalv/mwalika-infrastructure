# -- CloudFront --

# - Policies -

# Cache policy
resource "aws_cloudfront_cache_policy" "cache_policy" {
  name        = "cache-policy"
  default_ttl = 0
  min_ttl     = 0
  max_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# Origin request policy
resource "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  name    = "origin-request-policy"
  comment = "Forward all cookies to origin"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# Response headers policy
resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name    = "cors-policy"
  comment = "CORS policy for Mwalika CloudFront distribution"

  cors_config {
    access_control_allow_credentials = true
    access_control_allow_headers {
      items = [
        "Content-Type",
        "Authorization",
        "X-Requested-With",
        "X-Mwalika",
        "x-amz-server-side-encryption",
        "x-amz-security-token",
        "x-amz-acl",
        "Connection",
        "Upgrade",
        "Sec-WebSocket-Key",
        "Sec-WebSocket-Version",
        "Sec-WebSocket-Accept",
        "Sec-WebSocket-Protocol"
      ]
    }
    access_control_allow_methods {
      items = ["ALL"]
    }
    access_control_allow_origins {
      items = ["https://mwalika.com", "https://agent.mwalika.com"]
    }
    origin_override            = false
    access_control_max_age_sec = 86400
  }
}

# - Distributions -

variable "cloudfront_distributions" {
  type = map(object({
    alias     = string
    origin_id = string
    port      = number
  }))

  default = {
    frontend = {
      alias     = "mwalika.com"
      origin_id = "mwalika-frontend-origin"
      port      = 30000
    },
    agent = {
      alias     = "agent.mwalika.com"
      origin_id = "mwalika-agent-origin"
      port      = 30001
    }
  }
}

resource "aws_cloudfront_distribution" "distributions" {
  for_each = var.cloudfront_distributions

  enabled     = true
  aliases     = [each.value.alias]
  price_class = "PriceClass_200"
  web_acl_id  = aws_wafv2_web_acl.cloudfront.arn

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  origin {
    origin_id   = each.value.origin_id
    domain_name = aws_instance.ec2_instance.public_dns

    custom_origin_config {
      http_port              = each.value.port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = each.value.origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.origin_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
    Project     = "mwalika"
    ManagedBy   = "terraform"
  }
}
