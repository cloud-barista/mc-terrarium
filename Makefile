default:
	cd cmd/mc-terrarium && $(MAKE)

cc:
	cd cmd/mc-terrarium && $(MAKE)

run:
	cd cmd/mc-terrarium && $(MAKE) run

runwithport:
	cd cmd/mc-terrarium && $(MAKE) runwithport --port=$(PORT)

clean:
	cd cmd/mc-terrarium && $(MAKE) clean

prod:
	cd cmd/mc-terrarium && $(MAKE) prod

source-model:
	cd pkg/api/rest/model && $(MAKE) source-model

swag swagger:
	cd pkg/ && $(MAKE) swag
