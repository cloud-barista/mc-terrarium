// The tofu package provides utility functions to execute tofu CLI commands.
package tofu

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

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

func CopyTemplates(src string, des string) error {
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

	return CopyTemplates(cred, des)
}
