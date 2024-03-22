// The tofu package provides utility functions to execute tofu CLI commands.
package tofu

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/models"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

// ExecuteTofuCommand executes a given tofu CLI command with arguments and returns the result.
// It also logs the full command being executed.
// Example usage:
// - ExecuteTofuCommand("version")
// - ExecuteTofuCommand("apply", "-var=\"image_id=ami-abc123\"")
// - ExecuteTofuCommand("import", "aws_vpc.my-imported-vpc", "vpc-a01106c2")
func ExecuteTofuCommand(command string, args ...string) (string, error) {

	tf := "tofu"
	// Combine the command and arguments
	cmdArgs := append([]string{command}, args...)
	fullCommand := fmt.Sprintf("%s %s", tf, strings.Join(cmdArgs, " "))
	log.Debug().Msgf("Executing command: %s", fullCommand)

	// Prepare buffer to capture output
	var outputBuffer bytes.Buffer

	var logFile *os.File
	var err error
	runningLogFile := ""

	// Setup logging to a file if -chdir was specified
	arg := cmdArgs[0]
	if strings.HasPrefix(arg, "-chdir=") {
		path := strings.SplitN(arg, "=", 2)[1]
		runningLogFile = path + "/running.log" // Specify the log file name
	}

	if runningLogFile != "" {
		logFile, err = os.OpenFile(runningLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			log.Error().Msgf("Failed to open log file: %v", err)
			return "", err
		}
		defer logFile.Close()
	}

	// Execute the command
	cmd := exec.Command(tf, cmdArgs...)

	if logFile != nil {
		// Redirect command output to both log file, os.Stdout, and outputBuffer
		cmd.Stdout = io.MultiWriter(os.Stdout, logFile, &outputBuffer)
		cmd.Stderr = io.MultiWriter(os.Stderr, logFile, &outputBuffer)
	} else {
		// If no log file, capture output directly to outputBuffer
		cmd.Stdout = &outputBuffer
		cmd.Stderr = &outputBuffer
	}

	err = cmd.Run()
	output := outputBuffer.String()
	if err != nil {
		log.Error().Msgf("Failed to execute command: %s", fullCommand)
		return output, err
	}

	log.Debug().Msgf("Command output: %s", output)

	// output, err := cmd.CombinedOutput()
	// if err != nil {
	// 	log.Error().Msgf("Failed to execute command: %s", fullCommand)
	// 	return "", err
	// }

	// log.Debug().Msgf("Command output: %s", output)

	// Return the result
	return strings.TrimSpace(output), nil
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
