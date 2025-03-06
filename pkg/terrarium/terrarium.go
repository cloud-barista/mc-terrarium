package terrarium

import (
	"encoding/json"
	"fmt"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/lkvstore"
	"github.com/rs/zerolog/log"
)

// const (
// 	terrariumDbFileName = "terrarium.db"
// 	terrariumDir        = ".terrarium"
// )

// // Manage the running status of tofu commands.
// var terrariumInfoMap sync.Map

// // Save the terrarium info to file
// func SaveTerrariumInfoMap() error {
// 	projectRoot := config.Terrarium.Root
// 	terrariumDbFilePath := fmt.Sprintf("%s/%s/%s", projectRoot, terrariumDir, terrariumDbFileName)

// 	// Create the file to store the terrarium info map
// 	file, err := os.Create(terrariumDbFilePath)
// 	if err != nil {
// 		return fmt.Errorf("failed to create terrarium info db file: %w", err)
// 	}
// 	defer file.Close()

// 	// Encode sync.Map to a JSON file
// 	tempMap := make(map[string]model.TerrariumInfo)
// 	terrariumInfoMap.Range(func(key, value interface{}) bool {
// 		tempMap[key.(string)] = value.(model.TerrariumInfo)
// 		return true
// 	})

// 	encoder := json.NewEncoder(file)
// 	if err := encoder.Encode(tempMap); err != nil {
// 		return fmt.Errorf("failed to encode terrarium info map: %w", err)
// 	}

// 	return nil
// }

// // Load the terrarium info from file
// func LoadTerrariumInfoMap() error {
// 	projectRoot := config.Terrarium.Root
// 	terrariumDbFilePath := fmt.Sprintf("%s/%s/%s", projectRoot, terrariumDir, terrariumDbFileName)

// 	// Check and open the status file
// 	if _, err := os.Stat(terrariumDbFilePath); os.IsNotExist(err) {
// 		return fmt.Errorf("terrarium info db file does not exist: %w", err)
// 	}

// 	file, err := os.Open(terrariumDbFilePath)
// 	if err != nil {
// 		return fmt.Errorf("failed to open terrarium info db file: %w", err)
// 	}
// 	defer file.Close()

// 	// Decode JSON file to sync.Map
// 	var tempMap map[string]model.TerrariumInfo
// 	decoder := json.NewDecoder(file)
// 	if err := decoder.Decode(&tempMap); err != nil {
// 		return fmt.Errorf("failed to decode terrarium info map: %w", err)
// 	}

// 	for key, value := range tempMap {
// 		terrariumInfoMap.Store(key, value)
// 	}

// 	return nil
// }

// // Set the terrarium info for a given trId.
// func setTerrariumInfo(trInfo model.TerrariumInfo) {
// 	lkvstore.Put(trInfo.Id, trInfo)
// }

// // Get the terrarium info for a given trId.
// func getTerrariumInfo(trId string) (model.TerrariumInfo, bool) {
// 	value, exists := lkvstore.Get(trId)
// 	if !exists {
// 		return model.TerrariumInfo{}, false
// 	}
// 	return value.(model.TerrariumInfo), true
// }

// // Get all terrarium info.
// func getAllTerrariumInfo() []model.TerrariumInfo {
// 	var terrariumInfoList []model.TerrariumInfo
// 	values, exists := lkvstore.GetWithPrefix("")

// 	if exists {
// 		for _, value := range values {
// 			terrariumInfoList = append(terrariumInfoList, value.(model.TerrariumInfo))
// 		}
// 	}

// 	return terrariumInfoList
// }

func IssueTerrarium(trInfo model.TerrariumInfo) error {

	log.Debug().Msgf("trInfo: %v", trInfo)
	// Check if the terrarium already exists
	if value, exists := lkvstore.Get("/tr/" + trInfo.Id); exists {
		log.Debug().Msgf("value: %v", value)
		return fmt.Errorf("the terrarium (trId: %s) already exist", trInfo.Id)
	}
	
	// Save the terrarium info
	lkvstore.Put("/tr/" + trInfo.Id, trInfo)

	return nil
}

func ReadTerrariumInfo(trId string) (model.TerrariumInfo, error) {
	log.Debug().Msgf("trId: %s", trId)

	ret := model.TerrariumInfo{}
	value, exists := lkvstore.Get("/tr/" + trId)
	if !exists {
		return ret, fmt.Errorf("no terrarium (trId: %s)", trId)
	}

	err := json.Unmarshal([]byte(value), &ret)
	if err != nil {
		return ret, fmt.Errorf("failed to unmarshal terrarium info: %w", err)
	}

	return ret, nil
}

func ReadAllTerrariumInfo() ([]model.TerrariumInfo, error) {

	terrariumInfoList := []model.TerrariumInfo{}
	values, exists := lkvstore.GetWithPrefix("/tr/")


	if exists {
		for _, value := range values {
			
			trInfo := model.TerrariumInfo{}
			err := json.Unmarshal([]byte(value), &trInfo)
			if err != nil {
				log.Debug().Msgf("failed to unmarshal terrarium info: %v", err)
				continue
			}
			terrariumInfoList = append(terrariumInfoList, trInfo)
		}
	}
	
	return terrariumInfoList, nil
}

func UpdateTerrariumInfo(trInfo model.TerrariumInfo) error {

	_, exists := lkvstore.Get("/tr/" + trInfo.Id)
	if !exists {
		return fmt.Errorf("no terrarium (trId: %s)", trInfo.Id)
	}
	lkvstore.Put("/tr/" + trInfo.Id, trInfo)

	return nil
}

func DeleteTerrariumInfo(trId string) error {

	lkvstore.Delete("/tr/" + trId)

	return nil
}
