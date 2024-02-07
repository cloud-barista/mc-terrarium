default:
	cd cmd/poc-mc-net-tf && $(MAKE)

cc:
	cd cmd/poc-mc-net-tf && $(MAKE)

run:
	cd cmd/poc-mc-net-tf && $(MAKE) run

runwithport:
	cd cmd/poc-mc-net-tf && $(MAKE) runwithport --port=$(PORT)

clean:
	cd cmd/poc-mc-net-tf && $(MAKE) clean

prod:
	cd cmd/poc-mc-net-tf && $(MAKE) prod

source-model:
	cd pkg/api/rest/model && $(MAKE) source-model

swag swagger:
	cd pkg/ && $(MAKE) swag
