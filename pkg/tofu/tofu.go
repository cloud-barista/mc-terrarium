// The tofu package provides utility functions to execute tofu CLI commands.
package tofu

import (
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

// ExecuteCommand executes a given tofu CLI command with arguments and returns the result.
// It also logs the full command being executed.
// Example usage:
// - ExecuteCommand("version")
// - ExecuteCommand("apply", "-var=\"image_id=ami-abc123\"")
// - ExecuteCommand("import", "aws_vpc.my-imported-vpc", "vpc-a01106c2")
func ExecuteCommand(command string, args ...string) (string, error) {

	tf := "tofu"
	// Combine the command and arguments
	cmdArgs := append([]string{command}, args...)
	fullCommand := fmt.Sprintf("%s %s", tf, strings.Join(cmdArgs, " "))
	log.Debug().Msgf("Executing command: %s", fullCommand)

	// Execute the command
	cmd := exec.Command(tf, cmdArgs...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Error().Msgf("Failed to execute command: %s", fullCommand)
		return "", err
	}

	log.Debug().Msgf("Command output: %s", output)

	// Return the result
	return strings.TrimSpace(string(output)), nil
}

func CopyTemplateFile(src string, des string) error {
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

	return CopyTemplateFile(cred, des)
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

func SaveTfVarsToFile(tfVars models.TfVarsVPNTunnels, filePath string) error {
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
