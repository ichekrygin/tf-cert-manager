output cluster-issuer-name {
  value = data.template_file.cluster-issuer.vars.name
}

output cluster-issuer-email {
  value = data.template_file.cluster-issuer.vars.email
}