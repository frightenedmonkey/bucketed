variable "domain" { }
variable "domain_sans" {
  type = "list"
  default = []
}

// PriceClass_100 is the lowest tier & only covers North America & Europe
variable "price_class" {
  default = "PriceClass_100"
}

// There's no reason to support TLSv1.0 & 1.1 in 2018:
// https://caniuse.com/#feat=tls1-2
// See also the various announcements removing TLSv1.0 & 1.1:
// https://webkit.org/blog/8462/deprecation-of-legacy-tls-1-0-and-1-1-versions/
// https://blogs.windows.com/msedgedev/2018/10/15/modernizing-tls-edge-ie11/
// And the IETF deprecating them:
// https://tools.ietf.org/html/draft-ietf-tls-oldversions-deprecate-00
variable "minimum_tls_protocol" {
  default = "TLSv1.2_2018"
}
