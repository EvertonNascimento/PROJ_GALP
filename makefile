ifndef LOCATION
$(error LOCATION is not set)
endif

.PHONY: all plan apply destroy


all: plan

plan:
	cd $(LOCATION) && terraform plan 

apply:

	cd $(LOCATION) && terraform init 
	cd $(LOCATION) && terraform plan
	cd $(LOCATION) && terraform apply -auto-approve
	
destroy:
	cd $(LOCATION) && terraform destroy -auto-approve