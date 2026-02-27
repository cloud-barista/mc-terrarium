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

// SaveTfVars saves any tfVars structure to a JSON file
func SaveTfVars(tfVars interface{}, file string) error {
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

// CopyGCPCredentials copies the GCP credentials file.
// Deprecated: Templates now use OpenBao vault provider for credential management.
func CopyGCPCredentials(des string) error {
	projectRoot := config.Terrarium.Root
	if projectRoot == "" {
		return errors.New("TERRARIUM_ROOT environment variable is not set")
	}

	cred := projectRoot + "/secrets/credential-gcp.json"

	return CopyFile(cred, des)
}

// CopyAzureCredentials copies the Azure credentials file.
// Deprecated: Templates now use OpenBao vault provider for credential management.
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
		if err := CopyFile(srcFilePath, destFilePath); err != nil {
			return fmt.Errorf("failed to copy file %s: %w", entry.Name(), err)
		}
	}

	return nil
}

// CopyDir recursively copies a directory tree, including subdirectories and files.
func CopyDir(srcDir, destDir string) error {
	// Create destination directory if it does not exist
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	// Read all entries from source directory
	entries, err := os.ReadDir(srcDir)
	if err != nil {
		return fmt.Errorf("failed to read source directory: %w", err)
	}

	for _, entry := range entries {
		srcPath := filepath.Join(srcDir, entry.Name())
		destPath := filepath.Join(destDir, entry.Name())

		// Handle directories recursively
		if entry.IsDir() {
			if err := CopyDir(srcPath, destPath); err != nil {
				return fmt.Errorf("failed to copy directory %s: %w", entry.Name(), err)
			}
		} else {
			// Copy file
			if err := CopyFile(srcPath, destPath); err != nil {
				return fmt.Errorf("failed to copy file %s: %w", entry.Name(), err)
			}
		}
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

// WriteDocstring writes the provided docstring to the specified file.
// The path will be cleaned and parent directories will be created if they don't exist.
func WriteDocstring(path string, docstring string) error {
	// Clean the path to remove any . or .. elements
	path = filepath.Clean(path)

	// Ensure the parent directory exists
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	return os.WriteFile(path, []byte(docstring), 0644)
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
