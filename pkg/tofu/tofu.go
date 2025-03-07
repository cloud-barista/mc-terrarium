package tofu

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/cloud-barista/mc-terrarium/pkg/lkvstore"
	"github.com/rs/zerolog/log"
)

// cliName is the name of the OpenTofu CLI binary.
// It can be modified if the binary name is different in the system.
var cliName = "tofu"

// SetRunningStatus sets the running status for a given trId.
func SetRunningStatus(trId, status string) {
	lkvstore.Put("/tr/" + trId + "/status", status)
}

// GetExecutionStatus gets the running status for a given trId.
func GetExecutionStatus(trId string) (string, bool) {
	value, exists := lkvstore.Get("/tr/" + trId + "/status")
	if !exists {
		return "", false
	}
	return value, true
}

// ExecuteCommand executes a given tofu CLI command with arguments and returns the result.
// It also logs the full command being executed.
// Example usage:
// - ExecuteCommand("version")
// - ExecuteCommand("apply", "-var=\"image_id=ami-abc123\"")
// - ExecuteCommand("import", "aws_vpc.my-imported-vpc", "vpc-a01106c2")
func ExecuteCommand(trId, reqId string, args ...string) (string, error) {
	currentStatus, exists := GetExecutionStatus(trId)
	if exists && currentStatus == "Running" {
		return "", errors.New("a previous request is still in progress")
	}
	SetRunningStatus(trId, "Running")

	defer func() {
		if r := recover(); r != nil {
			SetRunningStatus(trId, "Failed")
		}
	}()

	// Execute the command and setup
	output, err := executeCommand(reqId, args)
	if err != nil {
		log.Error().Msgf("Command execution failed: %v", err)
		SetRunningStatus(trId, "Failed")
		return output, err
	}
	SetRunningStatus(trId, "Success")

	// Return the result
	return output, nil
}

// ExecuteCommandAsync executes a given tofu CLI command with arguments asynchronously.
func ExecuteCommandAsync(trId string, reqId string, args ...string) (string, error) {
	currentStatus, exists := GetExecutionStatus(trId)
	if exists && currentStatus == "Running" {
		return "", errors.New("a previous request is still in progress")
	}
	SetRunningStatus(trId, "Running")

	go func() {
		defer func() {
			if r := recover(); r != nil {
				SetRunningStatus(trId, "Failed")
			}
		}()

		// Execute the command and setup
		_, err := executeCommand(reqId, args)
		if err != nil {
			log.Error().Msgf("Command execution failed: %v", err)
			SetRunningStatus(trId, "Failed")
			return
		}
		SetRunningStatus(trId, "Success")
	}()

	res := fmt.Sprintf("Request (reqId: %s) in progress. Please use the status check API with the request ID.", reqId)
	return res, nil
}

// executeCommand executes the tofu command with the given arguments.
func executeCommand(reqId string, args []string) (string, error) {
	var logFile *os.File
	var outputBuffer bytes.Buffer
	var err error

	fullCommand := fmt.Sprintf("%s %s", cliName, strings.Join(args, " "))
	log.Debug().Msgf("Executing command: %s", fullCommand)

	if len(args) > 0 {
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
	}

	cmd := exec.Command(cliName, args...)
	if logFile != nil {
		cmd.Stdout = io.MultiWriter(os.Stdout, logFile, &outputBuffer)
		cmd.Stderr = io.MultiWriter(os.Stderr, logFile, &outputBuffer)
	} else {
		cmd.Stdout = &outputBuffer
		cmd.Stderr = &outputBuffer
	}

	if err := cmd.Run(); err != nil {
		return outputBuffer.String(), fmt.Errorf("failed to execute command: %s. Error: %v", fullCommand, err)
	}

	return outputBuffer.String(), nil
}

// GetExcutionHistory gets the running status for a given trId.
func GetExcutionHistory(trId, statusLogFile string) (string, error) {
	status, exists := GetExecutionStatus(trId)
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
