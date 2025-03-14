// Local Key-Value Store based on sync.Map and file I/O
package lkvstore

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/rs/zerolog/log"
)

var (
	lkvstore   sync.Map
	dbFilePath string
)

type Config struct {
	DbFilePath string
}

func Init(config Config) {
	if config.DbFilePath != "" {
		dbFilePath = config.DbFilePath
	} else {
		dbFilePath = ".lkvstore/lkvstore.db"
	}
}

// Save lkvstore to file
func SaveLkvStore() error {
	if dbFilePath == "" {
		return fmt.Errorf("db file path is not set")
	}

	// Ensure the DB file directory exists before creating the log file
	dir := filepath.Dir(dbFilePath)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		// Create the directory if it does not exist
		err = os.MkdirAll(dir, 0755) // Set permissions as needed
		if err != nil {
			log.Error().Msgf("Failed to Create the DB Directory: : [%v]", err)	
		}
	}
			
	file, err := os.Create(dbFilePath)
	if err != nil {
		return fmt.Errorf("failed to create db file: %w", err)
	}
	defer file.Close()

	tempMap := make(map[string]interface{})
	lkvstore.Range(func(key, value interface{}) bool {
		tempMap[key.(string)] = value
		return true
	})

	encoder := json.NewEncoder(file)
	if err := encoder.Encode(tempMap); err != nil {
		return fmt.Errorf("failed to encode map: %w", err)
	}

	return nil
}

// Load the info from file
func LoadLkvStore() error {
	if dbFilePath == "" {
		return fmt.Errorf("db file path is not set")
	}

	if _, err := os.Stat(dbFilePath); os.IsNotExist(err) {
		return fmt.Errorf("db file does not exist: %w", err)
	}

	file, err := os.Open(dbFilePath)
	if err != nil {
		return fmt.Errorf("failed to open db file: %w", err)
	}
	defer file.Close()

	var tempMap map[string]interface{}
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&tempMap); err != nil {
		return fmt.Errorf("failed to decode map: %w", err)
	}

	for key, value := range tempMap {
		lkvstore.Store(key, value)
	}

	return nil
}

// Get returns the value for a given key.
func Get(key string) (string, bool) {

	value, ok := lkvstore.Load(key)
	if !ok {
		log.Debug().Msgf("Get key: %s, value: %v", key, nil)
		return "", ok
	}

	return value.(string), ok
}

// GetWithPrefix returns the values for a given key prefix.
func GetWithPrefix(keyPrefix string) ([]string, bool) {
	var results []string
	var exists bool

	lkvstore.Range(func(key, value interface{}) bool {
		if strings.HasPrefix(key.(string), keyPrefix) {			
			results = append(results, value.(string))
			exists = true
		}
		return true
	})

	if !exists {
		return nil, false
	}

	return results, true
}

// Put the key-value pair.
func Put(key string, value interface{}) error {

	// Marshal the value to JSON
	jsonValue, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("failed to marshal value: %w", err)
	}

	// Store the JSON string
	lkvstore.Store(key, string(jsonValue))
	return nil
}

// Delete the key-value pair for a given key.
func Delete(key string) {
	lkvstore.Delete(key)
}