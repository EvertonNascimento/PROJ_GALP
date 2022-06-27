/*variables to be set 


The developed code will require the following input variables (It is assumed that the reviewer will
already get and terraform.tfvars file with the input variables set):
Note: Required means a mandatory variable to be set, but Optional means the variable must exist
but it is not required to be set
a. Network_CIDR (string, required) to set the network IP address configuration on CIDR format
b. N_Subnets (integer, required) to set the number of subnets to be used
c. Name (string, required) to set a name to the deployed infrastructure by tag name or another
field if required by the created resource.
d. Tags (key/value dictionary or map, optional). A bundle of key/values records (a.k.a tags) to
be set on resources that support it.


*/
#logica das cidr range pras subnets vai ter que ser pensada
network_cidr = "172.168.0.0/16"


n_subnets = "4"
infra_name = "test_sre"
tags = { infra = "test"}