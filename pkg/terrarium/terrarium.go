package terrarium

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/cloud-barista/mc-terrarium/pkg/lkvstore"
	"github.com/cloud-barista/mc-terrarium/pkg/tofu"
	"github.com/cloud-barista/mc-terrarium/pkg/tofu/tfclient"
	tfutil "github.com/cloud-barista/mc-terrarium/pkg/tofu/util"
	"github.com/rs/zerolog/log"
)

/*
 * [Note] Terrarium Management
 */

// IssueID issues a terrarium ID
func IssueID(trInfo model.TerrariumInfo) error {

	log.Debug().Msgf("trInfo: %v", trInfo)
	// Check if the terrarium already exists
	if value, exists := lkvstore.Get("/tr/" + trInfo.Id); exists {
		log.Debug().Msgf("value: %v", value)
		return fmt.Errorf("the terrarium (trId: %s) already exist", trInfo.Id)
	}

	// Save the terrarium info
	lkvstore.Put("/tr/"+trInfo.Id, trInfo)

	return nil
}

// GetInfo reads the terrarium info
func GetInfo(trId string) (model.TerrariumInfo, bool, error) {

	ret := model.TerrariumInfo{}
	value, exists := lkvstore.Get("/tr/" + trId)
	if !exists {
		return ret, exists, fmt.Errorf("no terrarium (trId: %s)", trId)
	}

	err := json.Unmarshal([]byte(value), &ret)
	if err != nil {
		return ret, exists, fmt.Errorf("failed to unmarshal terrarium info: %w", err)
	}

	return ret, exists, nil
}

// ReadAllInfo reads all terrarium info
func ReadAllInfo() ([]model.TerrariumInfo, error) {

	terrariumInfoList := []model.TerrariumInfo{}
	values, exists := lkvstore.GetWithPrefix("/tr/")

	if exists {
		for _, value := range values {

			trInfo := model.TerrariumInfo{}
			err := json.Unmarshal([]byte(value), &trInfo)
			if err != nil {
				log.Debug().Msgf("failed to unmarshal terrarium info: %v", err)
				continue
			}
			terrariumInfoList = append(terrariumInfoList, trInfo)
		}
	}

	return terrariumInfoList, nil
}

// UpdateInfo updates the terrarium info
func UpdateInfo(trInfo model.TerrariumInfo) error {

	_, exists := lkvstore.Get("/tr/" + trInfo.Id)
	if !exists {
		return fmt.Errorf("no terrarium (trId: %s)", trInfo.Id)
	}
	lkvstore.Put("/tr/"+trInfo.Id, trInfo)

	return nil
}

// DeleteInfo deletes the terrarium info
func DeleteInfo(trId string) error {

	lkvstore.Delete("/tr/" + trId)

	return nil
}

// GetEnrichments gets the terrarium enrichments from the terrarium info
func GetEnrichments(trId string) (string, bool, error) {
	trInfo, exist, err := GetInfo(trId)
	if !exist {
		log.Error().Msg("no terrarium")
		return "", false, errors.New("no terrarium")
	}

	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium info")
		return "", false, err
	}

	exist = (trInfo.Enrichments != "")
	if !exist {
		return "", false, nil
	}

	return trInfo.Enrichments, exist, nil
}

// GetTerrariumEnvPath gets the terrarium environment path (i.e., a working directory)
func GetTerrariumEnvPath(trId string) (string, error) {
	enrichments, _, err := GetEnrichments(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get enrichments")
		return "", err
	}

	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return "", err2
		}
	}
	return workingDir, nil
}

// SetEnrichments puts the terrarium enrichments to the terrarium info
func SetEnrichments(trId, enrichments string) error {
	trInfo, exist, err := GetInfo(trId)

	if !exist {
		log.Error().Msg("no terrarium")
		return errors.New("no terrarium")
	}
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium info")
		return err
	}

	trInfo.Enrichments = enrichments
	err = UpdateInfo(trInfo)
	if err != nil {
		log.Error().Err(err).Msg("failed to update terrarium info")
		return err
	}
	return nil
}

// CreateEnv sets the terrarium environment
func CreateEnv(trInfo model.TerrariumInfo) error {

	/*
	 * [Note] Validate the terrarium info
	 */
	if trInfo.Id == "" {
		err := fmt.Errorf("not specified the terrarium ID")
		log.Error().Msg(err.Error())
		return err
	}
	if trInfo.Enrichments == "" {
		err := fmt.Errorf("not specified the terrarium enrichments")
		log.Error().Msg(err.Error())
		return err
	}
	if len(trInfo.Providers) == 0 {
		err := fmt.Errorf("not specified the desired providers")
		log.Error().Msg(err.Error())
		return err
	}

	trId := trInfo.Id
	enrichments := trInfo.Enrichments
	providers := trInfo.Providers

	// Check if the terrarium environment exists (i.e., a terrarium environment)
	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return err2
		}
	}

	// Copy template files and modules to the terrarium environment (overwrite)
	templateTfsPath := projectRoot + "/templates/" + enrichments

	// Copy the template files to the terrarium environment
	err := tfutil.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		err2 := fmt.Errorf("failed to copy the template files to terrarium environment")
		log.Error().Err(err).Msg(err2.Error())

		return err2
	}

	// (If it exists) copy the provider specific template files to the terrarium environment
	for _, provider := range providers {
		providerTfsDir := projectRoot + "/templates/" + enrichments + "/" + provider
		err = tfutil.CopyFiles(providerTfsDir, workingDir)
		if err != nil {
			err2 := fmt.Errorf("could not find any provider (%s) specific template files to terrarium environment", provider)
			log.Warn().Err(err).Msg(err2.Error())
		}
	}

	// (If it exists) Copy modules if it exists
	srcModuleDir := templateTfsPath + "/modules"
	dstModuleDir := workingDir + "/modules"
	err = tfutil.CopyDir(srcModuleDir, dstModuleDir)
	if err != nil {
		err2 := fmt.Errorf("could not find any modules for terrarium environment")
		log.Warn().Err(err).Msg(err2.Error())
	}

	return nil
}

func SetCustomOutputsTf(trId, enrichments string, customOutputs string) error {
	// Check if the terrarium environment exists (i.e., a terrarium environment)
	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return err2
		}
	}

	// Create the custom outputs file
	customOutputsPath := workingDir + "/custom-output.tf"
	err := tfutil.WriteDocstring(customOutputsPath, customOutputs)
	if err != nil {
		err2 := fmt.Errorf("failed to create the custom outputs file")
		log.Error().Err(err).Msg(err2.Error())
		return err2
	}
	return nil
}

// SetCredentials sets the credentials for the terrarium environment
func SetCredentials(trId, enrichments string, csps ...string) error {

	// Check if the terrarium environment exists (i.e., a terrarium environment)
	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return err2
		}
	}

	// Copy the credentials to the terrarium environment
	for _, csp := range csps {
		switch csp {
		case "gcp":
			credentialPath := workingDir + "/credential-gcp.json"
			err := tfutil.CopyGCPCredentials(credentialPath)
			if err != nil {
				err2 := fmt.Errorf("failed to copy gcp credentials")
				log.Error().Err(err).Msg(err2.Error())
				return err2
			}
			// case "azure":
			// 	credentialPath := workingDir + "/credential-azure.env"
			// 	err := tfutil.CopyAzureCredentials(credentialPath)
			// 	if err != nil {
			// 		err2 := fmt.Errorf("failed to copy azure credentials")
			// 		log.Error().Err(err).Msg(err2.Error())
			// 		return err2
			// 	}
		}
	}
	return nil
}

// SaveTfVars sets the tofu variables for the terrarium environment
func SaveTfVars(trId, enrichments string, tfVars any) error {

	// Check if the terrarium environment exists (i.e., a terrarium environment)
	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return err2
		}
	}

	// Create the tfvars file
	// [Note] OpenTofu automatically loads variable definitions files
	// if they are present:
	// - Files named exactly terraform.tfvars or terraform.tfvars.json.
	// - Any files with names ending in .auto.tfvars or .auto.tfvars.json.
	tfVarsPath := workingDir + "/terraform.tfvars.json"
	err := tfutil.SaveTfVars(tfVars, tfVarsPath)
	if err != nil {
		err2 := fmt.Errorf("failed to create the tfvars file")
		log.Error().Err(err).Msg(err2.Error())
		return err2
	}
	return nil
}

// EmptyOutTerrariumEnv truncates the terrarium environment
func EmptyOutTerrariumEnv(trId string) error {

	// Check if the terrarium environment exists (i.e., a terrarium environment)
	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return err2
		}
	}

	// Check if a previous request is still in progress
	currentStatus, exists := tofu.GetExecutionStatus(trId)
	if exists && currentStatus == "Running" {
		return errors.New("the request is still in progress")
	}

	// Empty out the terrarium environment
	// note: keep the terrarium environment directory

	// Get entries in the terrarium environment
	entries, err := os.ReadDir(workingDir)
	if err != nil {
		log.Error().Err(err).Msgf("failed to read the terrarium environment (dir: %s)", workingDir)
		return err
	}

	// Remove all entries in the terrarium environment
	for _, entry := range entries {
		entryPath := filepath.Join(workingDir, entry.Name())
		err := os.RemoveAll(entryPath)
		if err != nil {
			log.Error().Err(err).Msgf("failed to empty out the terrarium environment (dir: %s)", entryPath)
			return err
		}
	}

	return nil
}

// RecoverImportTf recovers the imports.tf file
func RecoverImportTf(trId string) error {

	// Check if the terrarium environment exists (i.e., a terrarium environment)
	trInfo, exist, err := GetInfo(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium info")
		return err
	}

	if !exist {
		err := fmt.Errorf("no terrarium (trId: %s)", trId)
		log.Error().Msg(err.Error())
		return err
	}

	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to set the terrarium environment (trId: %s)", trId)
			log.Error().Err(err).Msg(err2.Error())
			return err2
		}
	}

	// Check if the imports.tf file exists
	importsTfPath := workingDir + "/imports.tf"

	// Copy template files and modules to the terrarium environment (overwrite)
	templateTfsPath := projectRoot + "/templates/" + trInfo.Enrichments + "/imports.tf"

	// Copy the imports.tf to the terrarium environment
	if err := tfutil.CopyFile(templateTfsPath, importsTfPath); err != nil {
		err2 := fmt.Errorf("failed to copy the imports.tf file to terrarium environment")
		log.Error().Err(err).Msg(err2.Error())
		return err2
	}

	return nil
}

/*
 * [Note] Terrarium actions powered by OpenTofu
 */

// Init prepares a terrarium environment for other commands (i.e., a terrarium environment)
func Init(trId, reqId string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: init
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	ret, err := tfcli.Init().Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// Plan shows changes required by the current configuration
func Plan(trId, reqId string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: plan
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	ret, err := tfcli.Plan().Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// Apply creates or updates infrastructure
func Apply(trId, reqId string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: apply
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	ret, err := tfcli.Apply().Auto().Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// Destroy destroys previously-created infrastructure
func Destroy(trId, reqId string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: destroy
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	ret, err := tfcli.Destroy().Auto().Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// Output shows output values from your root module
func Output(trId, reqId, name string, options ...string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: output
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	tfcli.Output()
	// Check if options includes "-json"
	for _, option := range options {
		if option == "-json" {
			tfcli.Json()
			break
		}
	}

	ret, err := tfcli.SetArg(name).Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// Show shows the current state or a save plan
func Show(trId, reqId string, options ...string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: output
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	tfcli.Show()
	// Check if options includes "-json"
	for _, option := range options {
		if option == "-json" {
			tfcli.Json()
			break
		}
	}

	ret, err := tfcli.Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// State reads and outputs a OpenTofu state or plan file in a human-readable form
func State(trId, reqId, subcommand string, args ...string) (string, error) {

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	tfcli := tfclient.NewClient(trId, reqId).SetChdir(workingDir).State()

	switch subcommand {
	case "pull":
		tfcli.Pull()
	case "push":
		tfcli.Push()
	case "list":
		tfcli.List()
	case "rm":
		tfcli.Remove()
	}

	ret, err := tfcli.SetArgs(args...).Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// Refresh refreshes the state file
func Refresh(trId, reqId string) (string, error) {
	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return "", err
	}

	// Execute tofu command: refresh
	tfcli := tfclient.NewClient(trId, reqId)
	tfcli.SetChdir(workingDir)

	ret, err := tfcli.Refresh().Exec()
	if err != nil {
		log.Error().Err(err).Msg("failed to execute tofu command")
		return "", err
	}

	return ret, nil
}

// DetachImportedResource detaches an imported resource from the state
func DetachImportedResource(trId, reqId, resourceId string) error {

	_, err := State(trId, reqId, "rm", resourceId)
	if err != nil {
		err2 := fmt.Errorf("failed to remove the imported route table")
		log.Error().Err(err).Msg(err2.Error())
		return err
	}

	// Get working directory
	workingDir, err := GetTerrariumEnvPath(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get terrarium environment path")
		return err
	}

	// Remove the imported resources to prevent destroying them
	err = tfutil.TruncateFile(workingDir + "/imports.tf")
	if err != nil {
		err2 := fmt.Errorf("failed to truncate imports.tf")
		log.Error().Err(err).Msg(err2.Error()) // error
		return err
	}

	return nil
}
