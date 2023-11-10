resource "shoreline_notebook" "ingress_controller_route_distribution_issues" {
  name       = "ingress_controller_route_distribution_issues"
  data       = file("${path.module}/data/ingress_controller_route_distribution_issues.json")
  depends_on = [shoreline_action.invoke_scale_up_deployment,shoreline_action.invoke_ingress_checker]
}

resource "shoreline_file" "scale_up_deployment" {
  name             = "scale_up_deployment"
  input_file       = "${path.module}/data/scale_up_deployment.sh"
  md5              = filemd5("${path.module}/data/scale_up_deployment.sh")
  description      = "Consider scaling up the Ingress Controller or Traefik to handle increased traffic and load."
  destination_path = "/tmp/scale_up_deployment.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "ingress_checker" {
  name             = "ingress_checker"
  input_file       = "${path.module}/data/ingress_checker.sh"
  md5              = filemd5("${path.module}/data/ingress_checker.sh")
  description      = "Verify that the Ingress Controller is running properly and that there are no issues with connectivity or resource allocation."
  destination_path = "/tmp/ingress_checker.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_scale_up_deployment" {
  name        = "invoke_scale_up_deployment"
  description = "Consider scaling up the Ingress Controller or Traefik to handle increased traffic and load."
  command     = "`chmod +x /tmp/scale_up_deployment.sh && /tmp/scale_up_deployment.sh`"
  params      = ["NAMESPACE","DESIRED_NUMBER_OF_REPLICAS","INGRESS_CONTROLLER_OR_TRAEFIK_DEPLOYMENT"]
  file_deps   = ["scale_up_deployment"]
  enabled     = true
  depends_on  = [shoreline_file.scale_up_deployment]
}

resource "shoreline_action" "invoke_ingress_checker" {
  name        = "invoke_ingress_checker"
  description = "Verify that the Ingress Controller is running properly and that there are no issues with connectivity or resource allocation."
  command     = "`chmod +x /tmp/ingress_checker.sh && /tmp/ingress_checker.sh`"
  params      = ["NAMESPACE","INGRESS_CONTROLLER_POD","SERVICE_URL","NODE_NAME"]
  file_deps   = ["ingress_checker"]
  enabled     = true
  depends_on  = [shoreline_file.ingress_checker]
}

