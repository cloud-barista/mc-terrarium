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

	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/models"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

// Manage the running status of tofu commands.
var requestStatusMap = make(map[string]string)
var mapMutex = &sync.Mutex{}

// Set the running status for a given rgId.
func setRunningStatus(rgId, status string) {
	mapMutex.Lock()
	defer mapMutex.Unlock()
	requestStatusMap[rgId] = status
}

// Get the running status for a given rgId.
func getRunningStatus(rgId string) (status string, exists bool) {
	mapMutex.Lock()
	defer mapMutex.Unlock()
	status, exists = requestStatusMap[rgId]
	return
}

// ExecuteTofuCommand executes a given tofu CLI command with arguments and returns the result.
// It also logs the full command being executed.
// Example usage:
// - ExecuteTofuCommand("version")
// - ExecuteTofuCommand("apply", "-var=\"image_id=ami-abc123\"")
// - ExecuteTofuCommand("import", "aws_vpc.my-imported-vpc", "vpc-a01106c2")
// ExecuteTofuCommand executes a given tofu CLI command with arguments asynchronously.
func ExecuteTofuCommand(rgId string, args ...string) (string, error) {
	currentStatus, exists := getRunningStatus(rgId)
	if exists && currentStatus == "Running" {
		return "", errors.New("A previous request is still in progress")
	}
	setRunningStatus(rgId, "Running")

	go func() {
		defer func() {
			if r := recover(); r != nil {
				setRunningStatus(rgId, "Failed")
			}
		}()

		// Execute the command and setup
		if err := executeCommand(args); err != nil {
			log.Error().Msgf("Command execution failed: %v", err)
			setRunningStatus(rgId, "Failed")
			return
		}
		setRunningStatus(rgId, "Success")
	}()

	return "Request in progress. Please use the status check API.", nil
}

// executeCommand executes the tofu command with given arguments.
func executeCommand(args []string) error {
	var logFile *os.File
	var outputBuffer bytes.Buffer
	var err error

	tf := "tofu"
	fullCommand := fmt.Sprintf("%s %s", tf, strings.Join(args, " "))
	log.Debug().Msgf("Executing command: %s", fullCommand)

	arg := args[0]
	if strings.HasPrefix(arg, "-chdir=") {
		path := strings.SplitN(arg, "=", 2)[1]
		runningLogFile := path + "/running.log"
		logFile, err = os.OpenFile(runningLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return fmt.Errorf("Failed to open log file: %v", err)
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
		return fmt.Errorf("Failed to execute command: %s. Error: %v", fullCommand, err)
	}

	if logFile == nil {
		log.Debug().Msgf("Command output: %s", outputBuffer.String())
	}
	return nil
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

	projectRoot := viper.GetString("pocmcnettf.root")
	cred := projectRoot + "/.tofu/secrets/credential-gcp.json"

	return CopyFile(cred, des)
}

func CopyAzureCredentials(des string) error {

	projectRoot := viper.GetString("pocmcnettf.root")
	cred := projectRoot + "/.tofu/secrets/credential-azure.env"

	return CopyFile(cred, des)
}

func CopyFiles(sourceDir, destDir string) error {
	err := filepath.Walk(sourceDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(sourceDir, path)
		if err != nil {
			return err
		}

		destPath := filepath.Join(destDir, relPath)

		if info.IsDir() {
			err := os.MkdirAll(destPath, info.Mode())
			if err != nil {
				return err
			}
		} else {
			sourceFile, err := os.Open(path)
			if err != nil {
				return err
			}
			defer sourceFile.Close()

			destFile, err := os.Create(destPath)
			if err != nil {
				return err
			}
			defer destFile.Close()

			_, err = io.Copy(destFile, sourceFile)
			if err != nil {
				return err
			}
		}

		return nil
	})

	if err != nil {
		log.Error().Err(err).Msg("Failed to copy template files to working directory")
		return err
	}

	return nil
}

func SaveGcpAwsTfVarsToFile(tfVars models.TfVarsGcpAwsVpnTunnel, filePath string) error {
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

func SaveGcpAzureTfVarsToFile(tfVars models.TfVarsGcpAzureVpnTunnel, filePath string) error {
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

func SaveTestEnvTfVarsToFile(tfVars models.TfVarsTestEnv, filePath string) error {
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
