// The tofu package provides utility functions to execute tofu CLI commands.
package tofu

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/rs/zerolog/log"
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
