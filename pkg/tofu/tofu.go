// The tofu package provides utility functions to execute tofu CLI commands.
package tofu

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/rs/zerolog/log"
)

const (
	statusFileName = "runningStatusMap.db"
	terrariumDir   = ".terrarium"
)

// Manage the running status of tofu commands.
var requestStatusMap sync.Map

// Save the running status map to file
func SaveRunningStatusMap() error {
	projectRoot := config.Terrarium.Root
	statusFilePath := fmt.Sprintf("%s/%s/%s", projectRoot, terrariumDir, statusFileName)

	// Create the file to store the running status map
	file, err := os.Create(statusFilePath)
	if err != nil {
		return fmt.Errorf("failed to create status file: %w", err)
	}
	defer file.Close()

	// Encode sync.Map to a JSON file
	tempMap := make(map[string]string)
	requestStatusMap.Range(func(key, value interface{}) bool {
		tempMap[key.(string)] = value.(string)
		return true
	})

	encoder := json.NewEncoder(file)
	if err := encoder.Encode(tempMap); err != nil {
		return fmt.Errorf("failed to encode status map: %w", err)
	}

	return nil
}

// Load the running status map from file
func LoadRunningStatusMap() error {
	projectRoot := config.Terrarium.Root
	statusFilePath := fmt.Sprintf("%s/%s/%s", projectRoot, terrariumDir, statusFileName)

	// Check and open the status file
	if _, err := os.Stat(statusFilePath); os.IsNotExist(err) {
		return fmt.Errorf("status file does not exist: %w", err)
	}

	file, err := os.Open(statusFilePath)
	if err != nil {
		return fmt.Errorf("failed to open status file: %w", err)
	}
	defer file.Close()

	// Decode JSON file to sync.Map
	var tempMap map[string]string
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&tempMap); err != nil {
		return fmt.Errorf("failed to decode status map: %w", err)
	}

	for key, value := range tempMap {
		requestStatusMap.Store(key, value)
	}

	return nil
}

// Set the running status for a given trId.
func setRunningStatus(trId, status string) {
	requestStatusMap.Store(trId, status)
}

// Get the running status for a given trId.
func getRunningStatus(trId string) (string, bool) {
	value, exists := requestStatusMap.Load(trId)
	if !exists {
		return "", false
	}
	return value.(string), true
}

func GetTofuVersion() (string, error) {

	var outputBuffer bytes.Buffer

	tf := "tofu"
	args := []string{"version"}
	fullCommand := fmt.Sprintf("%s %s", tf, args)
	log.Debug().Msgf("Executing command: %s", fullCommand)

	cmd := exec.Command(tf, args...)
	cmd.Stdout = io.MultiWriter(os.Stdout, &outputBuffer)
	cmd.Stderr = io.MultiWriter(os.Stderr, &outputBuffer)

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to execute command: %s. Error: %v", fullCommand, err)
	}

	return outputBuffer.String(), nil
}

// ExecuteTofuCommand executes a given tofu CLI command with arguments and returns the result.
// It also logs the full command being executed.
// Example usage:
// - ExecuteTofuCommand("version")
// - ExecuteTofuCommand("apply", "-var=\"image_id=ami-abc123\"")
// - ExecuteTofuCommand("import", "aws_vpc.my-imported-vpc", "vpc-a01106c2")
func ExecuteTofuCommand(trId, reqId string, args ...string) (string, error) {

	currentStatus, exists := getRunningStatus(trId)
	if exists && currentStatus == "Running" {
		return "", errors.New("a previous request is still in progress")
	}
	setRunningStatus(trId, "Running")

	defer func() {
		if r := recover(); r != nil {
			setRunningStatus(trId, "Failed")
		}
	}()

	// Execute the command and setup
	output, err := executeCommand(reqId, args)
	if err != nil {
		log.Error().Msgf("Command execution failed: %v", err)
		setRunningStatus(trId, "Failed")
		return output, err
	}
	// log.Debug().Msgf("Command output: %s", output)
	setRunningStatus(trId, "Success")

	// log.Debug().Msgf("Command output: %s", output)

	// Return the result
	return output, nil
}

// ExecuteTofuCommandAsync executes a given tofu CLI command with arguments and returns the result.
// It also logs the full command being executed.
// Example usage:
// - ExecuteTofuCommandAsync("version")
// - ExecuteTofuCommandAsync("apply", "-var=\"image_id=ami-abc123\"")
// - ExecuteTofuCommandAsync("import", "aws_vpc.my-imported-vpc", "vpc-a01106c2")
// ExecuteTofuCommandAsync executes a given tofu CLI command with arguments asynchronously.
func ExecuteTofuCommandAsync(trId string, reqId string, args ...string) (string, error) {
	currentStatus, exists := getRunningStatus(trId)
	if exists && currentStatus == "Running" {
		return "", errors.New("a previous request is still in progress")
	}
	setRunningStatus(trId, "Running")

	go func() {
		defer func() {
			if r := recover(); r != nil {
				setRunningStatus(trId, "Failed")
			}
		}()

		// Execute the command and setup
		_, err := executeCommand(reqId, args)
		if err != nil {
			log.Error().Msgf("Command execution failed: %v", err)
			setRunningStatus(trId, "Failed")
			return
		}
		// log.Debug().Msgf("Command output: %s", output)
		setRunningStatus(trId, "Success")
	}()

	res := fmt.Sprintf("Request (reqId: %s) in progress. Please use the status check API with the request ID.", reqId)
	return res, nil
}

// executeCommand executes the tofu command with given arguments.
func executeCommand(reqId string, args []string) (string, error) {
	var logFile *os.File
	var outputBuffer bytes.Buffer
	var err error

	tf := "tofu"
	fullCommand := fmt.Sprintf("%s %s", tf, strings.Join(args, " "))
	log.Debug().Msgf("Executing command: %s", fullCommand)

	arg := args[0]
	if strings.HasPrefix(arg, "-chdir=") {
		path := strings.SplitN(arg, "=", 2)[1]
		// Create the runningLogs directory path
		logDir := fmt.Sprintf("%s/runningLogs", path)
		// Create the directory if it does not exist
		if err := os.MkdirAll(logDir, 0755); err != nil {
			return "", fmt.Errorf("failed to create log directory: %v", err)
		}
		// Set the log file path
		runningLogFile := fmt.Sprintf("%s/%s.log", logDir, reqId)
		logFile, err = os.OpenFile(runningLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return "", fmt.Errorf("failed to open log file: %v", err)
		}
		defer logFile.Close()
	}

	cmd := exec.Command(tf, args...)
	if logFile != nil {
		cmd.Stdout = io.MultiWriter(os.Stdout, logFile, &outputBuffer)
		cmd.Stderr = io.MultiWriter(os.Stderr, logFile, &outputBuffer)
	} else {
		cmd.Stdout = &outputBuffer
		cmd.Stderr = &outputBuffer
	}

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to execute command: %s. Error: %v", fullCommand, err)
	}

	// if logFile != nil {
	// 	log.Debug().Msgf("Command output is also logged to: %s", logFile.Name())
	// }

	return outputBuffer.String(), nil
}

func GetRunningStatus(trId, statusLogFile string) (string, error) {

	status, exists := getRunningStatus(trId)
	if !exists {
		return "", errors.New("no request found")
	}
	log.Debug().Msgf("Request status: %s", status)

	_, err := os.Stat(statusLogFile)
	if err != nil {
		if os.IsNotExist(err) {
			return "", errors.New("status log file does not exist")
		}
		return "", fmt.Errorf("failed to check status log file: %v", err)
	}

	// Read the status from the log file
	statusBytes, err := os.ReadFile(statusLogFile)
	if err != nil {
		return "", fmt.Errorf("failed to read status log file: %v", err)
	}

	statusReport := fmt.Sprintf("[Request status: %s]\n%s", status, string(statusBytes))

	return statusReport, nil
}

func CopyFile(src string, des string) error {
	srcFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	dstFile, err := os.Create(des)
	if err != nil {
		return err
	}
	defer dstFile.Close()

	_, err = io.Copy(dstFile, srcFile)
	if err != nil {
		return err
	}

	return nil
}

func CopyGCPCredentials(des string) error {

	projectRoot := config.Terrarium.Root
	cred := projectRoot + "/secrets/credential-gcp.json"

	return CopyFile(cred, des)
}

func CopyAzureCredentials(des string) error {

	projectRoot := config.Terrarium.Root
	cred := projectRoot + "/secrets/credential-azure.env"

	return CopyFile(cred, des)
}

func CopyFiles(sourceDir, destDir string) error {
		// Create destination directory if it does not exist
		if err := os.MkdirAll(destDir, 0755); err != nil {
			return fmt.Errorf("failed to create destination directory: %w", err)
		}
	
		// Read file list from source directory
		entries, err := os.ReadDir(sourceDir)
		if err != nil {
			return fmt.Errorf("failed to read source directory: %w", err)
		}
	
		for _, entry := range entries {
			// Skip directories
			if entry.IsDir() {
				continue
			}
	
			srcFilePath := filepath.Join(sourceDir, entry.Name())
			destFilePath := filepath.Join(destDir, entry.Name())
	
			// Copy the file
			if err := copyFile(srcFilePath, destFilePath); err != nil {
				return fmt.Errorf("failed to copy file %s: %w", entry.Name(), err)
			}
		}
	
		return nil
}

func SaveTfVarsToFile(tfVars interface{}, filePath string) error {
	tfVarsBytes, err := json.MarshalIndent(tfVars, "", "  ")
	if err != nil {
		return err
	}

	err = os.WriteFile(filePath, tfVarsBytes, 0644)
	if err != nil {
		return err
	}

	return nil
}

func copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	return err
}

func SaveGcpAwsTfVarsToFile(tfVars model.TfVarsGcpAwsVpnTunnel, filePath string) error {
	tfVarsBytes, err := json.MarshalIndent(tfVars, "", "  ")
	if err != nil {
		return err
	}

	err = os.WriteFile(filePath, tfVarsBytes, 0644)
	if err != nil {
		return err
	}

	return nil
}

func SaveGcpAzureTfVarsToFile(tfVars model.TfVarsGcpAzureVpnTunnel, filePath string) error {
	tfVarsBytes, err := json.MarshalIndent(tfVars, "", "  ")
	if err != nil {
		return err
	}

	err = os.WriteFile(filePath, tfVarsBytes, 0644)
	if err != nil {
		return err
	}

	return nil
}

func SaveTestEnvTfVarsToFile(tfVars model.TfVarsTestEnv, filePath string) error {
	tfVarsBytes, err := json.MarshalIndent(tfVars, "", "  ")
	if err != nil {
		return err
	}

	err = os.WriteFile(filePath, tfVarsBytes, 0644)
	if err != nil {
		return err
	}

	return nil
}

func TruncateFile(filename string) error {
	file, err := os.OpenFile(filename, os.O_TRUNC, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	return nil
}
