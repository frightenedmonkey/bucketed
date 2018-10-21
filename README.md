# Introduction

A basic terraform module that allows you to create a static website on s3, fronted
by cloudfront. This module won't actually deploy things for you; you'll need to
manage your code deploys elsewhere.

## Important Varibles/Parameters

domain: set this to the default domain you want to create a bucket for. The module
assumes that route53 manages this particular zone. The module will create a new
ACM based certificate for the domain you provide.

domain_sans: A list of subject alternative names for the ACM cert that will be
generated.

price_class: the Cloudfront price class to use, defaults to PriceClass_100 (the lowest
tier)

minimum_tls_protocol: the Cloudfront TLS policy to use
