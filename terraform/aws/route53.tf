# -- Route 53 --

# - Hosted Zone for mwalika.com -

resource "aws_route53_zone" "mwalika" {
  name = "mwalika.com"
  comment = "Hosted zone for mwalika.com managed by Terraform"
}

# - Certificate validation record for ACM certificate -

data "aws_acm_certificate" "cloudfront" {
  provider    = aws.us_east_1
  domain      = "mwalika.com"
  statuses    = ["ISSUED"]
  most_recent = true
}


resource "aws_route53_record" "www" {
	zone_id = aws_route53_zone.mwalika.zone_id
	name    = "www.mwalika.com"
	type    = "CNAME"
	ttl     = 300
	records = ["mwalika.com"]
}

# - Alias record for CloudFront distributions -

resource "aws_route53_record" "cloudfront_alias" {
  for_each = var.cloudfront_distributions

  zone_id = aws_route53_zone.mwalika.zone_id
  name    = each.value.alias
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distributions[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.distributions[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}