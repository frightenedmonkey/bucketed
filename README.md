# Introduction

A basic terraform module that allows you to create a static website on s3, fronted
by cloudfront. This module won't actually deploy things for you; you'll need to
manage your code deploys elsewhere.

## Variables

__domain__: set this to the domain you want to create a bucket for. The module
assumes that route53 manages this particular zone. The module will create a new
ACM based certificate for the domain you provide.

__price_class__: the Cloudfront price class to use, defaults to PriceClass_100 (the lowest
tier)

__minimum_tls_protocol__: the Cloudfront TLS policy to use; defaults to TLSv1.2_2018
because there's no reason not to start there.

## Caveats
You *must* use an aws us-east-1 provider for this module. AWS explicitly requires
that you create a cert with ACM from us-east-1 if you want to attach it to Cloudfront.
While this isn't great, it's not the end of the world.

This module manages both the s3 bucket & the cloudfront/acm stuff. That's probably
a bit more than is ideal. Really, the bucket should be a separate module that you
can then inject into the cloudfront/acm stuff. With that said, it's a simple cookie
cutter type thing, so it's probably not that big of a deal.
