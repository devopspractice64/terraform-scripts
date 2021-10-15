resource aws_ses_domain_identity "primary" {
  domain = var.customer_domain
}

resource aws_ses_domain_dkim "primary" {
  domain = aws_ses_domain_identity.primary.domain
}

resource aws_route53_record "primary_ses_verification" {
  zone_id = var.route53_id
  name = "_amazonses.${aws_ses_domain_identity.primary.domain}"
  type = "TXT"
  ttl = "600"
  records = [
    aws_ses_domain_identity.primary.verification_token,
  ]
}

resource aws_route53_record "primary_dkim_record" {
  count = 3
  zone_id = var.route53_id
  name = "${element(aws_ses_domain_dkim.primary.dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.primary.domain}"
  type = "CNAME"
  ttl = "600"
  records = ["${element(aws_ses_domain_dkim.primary.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

data "aws_region" "current" {}

resource aws_route53_record "primary_email_receiving_record" {
  name = var.customer_domain
  type = "MX"
  zone_id = var.route53_id
  ttl = 1800
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}

resource aws_ses_domain_identity_verification "ses_verification" {
  domain = aws_ses_domain_identity.primary.domain

  depends_on = [
    aws_route53_record.primary_ses_verification,
    aws_route53_record.primary_dkim_record,
  ]
}

resource aws_ses_email_identity "internal_emails" {
  count = length(var.internal_emails)

  email = "${var.internal_emails[count.index]}@${var.customer_domain}"
}

resource aws_ses_email_identity "verifiable_emails" {
  count = length(var.custom_emails_to_verify)

  email = var.custom_emails_to_verify[count.index]
}
