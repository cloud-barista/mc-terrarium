package terrarium

import (
	"encoding/json"
	"fmt"
	"os"
	"sync"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/config"
)

const (
	terrariumDbFileName = "terrarium.db"
	terrariumDir        = ".terrarium"
)

// Manage the running status of tofu commands.
var terrariumInfoMap sync.Map

// Save the terrarium info to file
func SaveTerrariumInfoMap() error {
	projectRoot := config.Terrarium.Root
	terrariumDbFilePath := fmt.Sprintf("%s/%s/%s", projectRoot, terrariumDir, terrariumDbFileName)

	// Create the file to store the terrarium info map
	file, err := os.Create(terrariumDbFilePath)
	if err != nil {
		return fmt.Errorf("failed to create terrarium info db file: %w", err)
	}
	defer file.Close()

	// Encode sync.Map to a JSON file
	tempMap := make(map[string]model.TerrariumInfo)
	terrariumInfoMap.Range(func(key, value interface{}) bool {
		tempMap[key.(string)] = value.(model.TerrariumInfo)
		return true
	})

	encoder := json.NewEncoder(file)
	if err := encoder.Encode(tempMap); err != nil {
		return fmt.Errorf("failed to encode terrarium info map: %w", err)
	}

	return nil
}

// Load the terrarium info from file
func LoadTerrariumInfoMap() error {
	projectRoot := config.Terrarium.Root
	terrariumDbFilePath := fmt.Sprintf("%s/%s/%s", projectRoot, terrariumDir, terrariumDbFileName)

	// Check and open the status file
	if _, err := os.Stat(terrariumDbFilePath); os.IsNotExist(err) {
		return fmt.Errorf("terrarium info db file does not exist: %w", err)
	}

	file, err := os.Open(terrariumDbFilePath)
	if err != nil {
		return fmt.Errorf("failed to open terrarium info db file: %w", err)
	}
	defer file.Close()

	// Decode JSON file to sync.Map
	var tempMap map[string]model.TerrariumInfo
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&tempMap); err != nil {
		return fmt.Errorf("failed to decode terrarium info map: %w", err)
	}

	for key, value := range tempMap {
		terrariumInfoMap.Store(key, value)
	}

	return nil
}

// Set the terrarium info for a given trId.
func setTerrariumInfo(trInfo model.TerrariumInfo) {
	terrariumInfoMap.Store(trInfo.Id, trInfo)
}

// Get the terrarium info for a given trId.
func getTerrariumInfo(trId string) (model.TerrariumInfo, bool) {
	value, exists := terrariumInfoMap.Load(trId)
	if !exists {
		return model.TerrariumInfo{}, false
	}
	return value.(model.TerrariumInfo), true
}

// Get all terrarium info.
func getAllTerrariumInfo() []model.TerrariumInfo {
	var terrariumInfoList []model.TerrariumInfo
	terrariumInfoMap.Range(func(key, value interface{}) bool {
		terrariumInfoList = append(terrariumInfoList, value.(model.TerrariumInfo))
		return true
	})
	return terrariumInfoList
}

func IssueTerrarium(trInfo model.TerrariumInfo) error {

	if _, exists := getTerrariumInfo(trInfo.Id); exists {
		return fmt.Errorf("the terrarium (trId: %s) already exist", trInfo.Id)
	}
	setTerrariumInfo(trInfo)

	return nil
}

func ReadTerrariumInfo(trId string) (model.TerrariumInfo, error) {

	trInfo, exists := getTerrariumInfo(trId)
	if !exists {
		return model.TerrariumInfo{}, fmt.Errorf("not existed the terrarium (trId: %s)", trId)
	}

	return trInfo, nil
}

func ReadAllTerrariumInfo() ([]model.TerrariumInfo, error) {

	trInfoList := getAllTerrariumInfo()

	return trInfoList, nil
}

func UpdateTerrariumInfo(trInfo model.TerrariumInfo) error {

	_, exists := getTerrariumInfo(trInfo.Id)
	if !exists {
		return fmt.Errorf("not existed the terrarium (trId: %s)", trInfo.Id)
	}
	setTerrariumInfo(trInfo)

	return nil
}

func DeleteTerrariumInfo(trId string) error {

	_, exists := getTerrariumInfo(trId)
	if !exists {
		return fmt.Errorf("not existed the terrarium (trId: %s)", trId)
	}
	terrariumInfoMap.Delete(trId)

	return nil
}
