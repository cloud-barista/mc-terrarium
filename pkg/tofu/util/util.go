package tfutil

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/cloud-barista/mc-terrarium/pkg/config"
)

// Version returns the version of the Tofu installation
func Version() (string, error) {
	cmd := exec.Command("tofu", "version")
	output, err := cmd.Output()
	if err != nil {
			return "", err
	}
	return strings.TrimSpace(string(output)), nil
}


// SaveTfVarsToFile saves any tfVars structure to a JSON file
func SaveTfVarsToFile(tfVars interface{}, file string) error {
	// Convert tfVars to json
	jsonData, err := json.MarshalIndent(tfVars, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal tfVars: %w", err)
	}
	
	// Write jsonData to file
	err = os.WriteFile(file, jsonData, 0644)
	if err != nil {
		return fmt.Errorf("failed to write tfVars file: %w", err)
	}
	
	return nil
}


// CopyFile copies a file from one location to another.
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

// CopyGCPCredentials copies the GCP credentials file.
func CopyGCPCredentials(des string) error {
	projectRoot := config.Terrarium.Root
	if projectRoot == "" {
		return errors.New("TERRARIUM_ROOT environment variable is not set")
	}
	
	cred := projectRoot + "/secrets/credential-gcp.json"

	return CopyFile(cred, des)
}

// CopyAzureCredentials copies the Azure credentials file.
func CopyAzureCredentials(des string) error {
	projectRoot := config.Terrarium.Root
	if projectRoot == "" {
		return errors.New("TERRARIUM_ROOT environment variable is not set")
	}
	
	cred := projectRoot + "/secrets/credential-azure.env"

	return CopyFile(cred, des)
}

// CopyFiles copies files from the source directory to the destination directory.
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

// Internal file copy helper function
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

// TruncateFile truncates the contents of a file.
func TruncateFile(filename string) error {
	file, err := os.OpenFile(filename, os.O_TRUNC, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	return nil
}