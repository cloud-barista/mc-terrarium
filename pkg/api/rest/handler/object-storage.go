/*
Copyright 2019 The Cloud-Barista Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/cloud-barista/mc-terrarium/pkg/terrarium"
	"github.com/cloud-barista/mc-terrarium/pkg/tofu"
	tfutil "github.com/cloud-barista/mc-terrarium/pkg/tofu/util"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/tidwall/gjson"
)

var validProvidersForObjectStorage = map[string]bool{
	"aws":   true,
	"azure": true,
	"gcp":   true,
	"ncp":   true,
}

func getValidProviderListForMessageBroker() []string {
	validProviders := []string{}
	for provider := range validProvidersForObjectStorage {
		if validProvidersForObjectStorage[provider] {
			validProviders = append(validProviders, provider)
		}
	}
	return validProviders
}

// InitEnvForObjectStorage godoc
// @Summary Initialize a multi-cloud terrarium for Object Storage (e.g., AWS S3 Bucket, Azure Blob Storage)
// @Description Initialize a multi-cloud terrarium for Object Storage (e.g., AWS S3 Bucket, Azure Blob Storage)
// @Tags [Object Storage] Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param provider query string false "Provider" Enums(aws, azure) default(aws)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage/env [post]
func InitEnvForObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	provider := c.QueryParam("provider")
	if provider == "" {
		err := fmt.Errorf("invalid request, provider is required")
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	if !validProvidersForObjectStorage[provider] {
		providerList := getValidProviderListForMessageBroker()
		err := fmt.Errorf("invalid request, provider must be one of %v", providerList)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Set the enrichments
	enrichments := "object-storage"

	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	trInfo.Enrichments = enrichments
	err = terrarium.UpdateInfo(trInfo)
	if err != nil {
		err2 := fmt.Errorf("failed to update terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Create a working directory for the terrarium
	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to create a working directory")
			log.Error().Err(err).Msg(err2.Error())
			res := model.Response{Success: false, Message: err2.Error()}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/templates/" + enrichments + "/" + provider

	err = tfutil.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		err2 := fmt.Errorf("failed to copy template files to working directory")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	if provider == "gcp" {
		// Always overwrite credential-gcp.json
		credentialPath := workingDir + "/credential-gcp.json"

		err = tfutil.CopyGCPCredentials(credentialPath)
		if err != nil {
			err2 := fmt.Errorf("failed to copy gcp credentials")
			log.Error().Err(err).Msg(err2.Error())
			res := model.Response{
				Success: false,
				Message: err2.Error(),
			}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/object-storage
	// init: subcommand
	ret, err := tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "init")
	if err != nil {
		err2 := fmt.Errorf("failed to initialize an infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{
		Success: true,
		Message: "the infrastructure terrarium is successfully initialized",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// ClearEnvOfObjectStorage godoc
// @Summary Clear the entire directory and configuration files
// @Description Clear the entire directory and configuration files
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param action query string false "Action" Enums(force) default()
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage/env [delete]
func ClearEnvOfObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := config.Terrarium.Root

	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = os.RemoveAll(workingDir)
	if err != nil {
		err2 := fmt.Errorf("failed to remove working directory and all configuration files")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := "successfully remove all in the working directory"
	res := model.Response{
		Success: true,
		Message: text,
	}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// CreateInfracodeForObjectStorage godoc
// @Summary Create the infracode for Object Storage
// @Description Create the infracode for Object Storage
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ParamsForInfracode body model.CreateInfracodeOfObjectStorageRequest true "Parameters of infracode for Object Storage"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage/infracode [post]
func CreateInfracodeForObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	req := new(model.CreateInfracodeOfObjectStorageRequest)
	if err := c.Bind(req); err != nil {
		err2 := fmt.Errorf("invalid request format, %v", err)
		log.Warn().Err(err).Msg("invalid request format")
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}
	log.Debug().Msgf("%+v", req) // debug

	projectRoot := config.Terrarium.Root

	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Save the tfVars to a file
	tfVarsPath := workingDir + "/terraform.tfvars.json"
	// Note
	// Terraform also automatically loads a number of variable definitions files
	// if they are present:
	// - Files named exactly terraform.tfvars or terraform.tfvars.json.
	// - Any files with names ending in .auto.tfvars or .auto.tfvars.json.

	if req.TfVars.TerrariumID == "" {
		log.Warn().Msgf("terrarium ID is not set, Use path param: %s", trId) // warn
		req.TfVars.TerrariumID = trId
	}

	err = tfutil.SaveTfVars(req.TfVars, tfVarsPath)
	if err != nil {
		err2 := fmt.Errorf("failed to save tfVars to a file")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := model.Response{
		Success: true,
		Message: "the infracode for an object storage is successfully created",
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckInfracodeForObjectStorage godoc
// @Summary Check and show changes by the current infracode
// @Description Check and show changes by the current infracode
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage/plan [post]
func CheckInfracodeForObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root
	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/object-storage
	// subcommand: plan
	ret, err := tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "plan")
	if err != nil {
		err2 := fmt.Errorf("returned: %s", ret)
		log.Error().Err(err).Msg(err2.Error()) // error
		res := model.Response{
			Success: false,
			Message: err2.Error(),
			Detail:  ret,
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{
		Success: true,
		Message: "the infracode checking process is successfully completed",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// CreateObjectStorage godoc
// @Summary Create Object Storage
// @Description Create Object Storage
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage [post]
func CreateObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root
	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/object-storage
	// subcommand: apply
	_, err = tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		err2 := fmt.Errorf("failed, previous request in progress")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/object-storage
	// show: subcommand
	ret, err := tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "output", "-json", "object_storage_info")
	if err != nil {
		err2 := fmt.Errorf("failed to read resource info (detail: %s) specified as 'output' in the state file", "refined")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	var resourceInfo map[string]interface{}
	err = json.Unmarshal([]byte(ret), &resourceInfo)
	if err != nil {
		log.Error().Err(err).Msg("") // error
		res := model.Response{
			Success: false,
			Message: "failed to unmarshal resource info",
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := model.Response{
		Success: true,
		Message: "refined read resource info (map)",
		Object:  resourceInfo,
	}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// GetResourceInfoOfObjectStorage godoc
// @Summary Get resource info of Object Storage
// @Description Get resource info of Object Storage
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" default(refined)
// @Param x-request-id header string false "custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage [get]
func GetResourceInfoOfObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Use this struct like the enum
	var DetailOptions = struct {
		Refined string
		Raw     string
	}{
		Refined: "refined",
		Raw:     "raw",
	}

	// valid detail options
	validDetailOptions := map[string]bool{
		DetailOptions.Refined: true,
		DetailOptions.Raw:     true,
	}

	detail := c.QueryParam("detail")
	detail = strings.ToLower(detail)

	if detail == "" || !validDetailOptions[detail] {
		err := fmt.Errorf("invalid detail (%s), use the default (%s)", detail, DetailOptions.Refined)
		log.Warn().Msg(err.Error())
		detail = DetailOptions.Refined
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root
	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Get the resource info by the detail option
	switch detail {
	case DetailOptions.Refined:
		// Code for handling "refined" detail option

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/object-storage
		// show: subcommand
		ret, err := tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "output", "-json", "object_storage_info")
		if err != nil {
			err2 := fmt.Errorf("failed to read resource info (detail: %s) specified as 'output' in the state file", DetailOptions.Refined)
			log.Error().Err(err).Msg(err2.Error())
			res := model.Response{
				Success: false,
				Message: err2.Error(),
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		var resourceInfo map[string]interface{}
		err = json.Unmarshal([]byte(ret), &resourceInfo)
		if err != nil {
			log.Error().Err(err).Msg("") // error
			res := model.Response{
				Success: false,
				Message: "failed to unmarshal resource info",
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		res := model.Response{
			Success: true,
			Message: "refined read resource info (map)",
			Object:  resourceInfo,
		}
		log.Debug().Msgf("%+v", res) // debug

		return c.JSON(http.StatusOK, res)

	case DetailOptions.Raw:
		// Code for handling "raw" detail option

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/object-storage
		// show: subcommand
		// Get resource info from the state or plan file
		ret, err := tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "show", "-json")
		if err != nil {
			err2 := fmt.Errorf("failed to read resource info (detail: %s) from the state or plan file", DetailOptions.Raw)
			log.Error().Err(err).Msg(err2.Error()) // error
			res := model.Response{
				Success: false,
				Message: err2.Error(),
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		// Parse the resource info
		resourcesString := gjson.Get(ret, "values.root_module.resources").String()
		if resourcesString == "" {
			err2 := fmt.Errorf("could not find resource info (trId: %s)", trId)
			log.Warn().Msg(err2.Error())
			res := model.Response{
				Success: false,
				Message: err2.Error(),
			}
			return c.JSON(http.StatusOK, res)
		}

		var resourceInfoList []interface{}
		err = json.Unmarshal([]byte(resourcesString), &resourceInfoList)
		if err != nil {
			log.Error().Err(err).Msg("") // error
			res := model.Response{
				Success: false,
				Message: "failed to unmarshal resource info",
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		res := model.Response{
			Success: true,
			Message: "raw resource info (list)",
			List:    resourceInfoList,
		}
		log.Debug().Msgf("%+v", res) // debug

		return c.JSON(http.StatusOK, res)
	default:
		err2 := fmt.Errorf("invalid detail option (%s)", detail)
		log.Warn().Err(err2).Msg("") // warn
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}
}

// DestroyObjectStorage godoc
// @Summary Destroy Object Storage
// @Description Destroy Object Storage
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage [delete]
func DestroyObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root
	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Destroy the infrastructure
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}
	// subcommand: destroy
	ret, err := tofu.ExecuteCommand(trId, reqId, "-chdir="+workingDir, "destroy", "-auto-approve")
	if err != nil {
		err2 := fmt.Errorf("failed, previous request in progress")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{
		Success: true,
		Message: fmt.Sprintf("the destroying process is successfully completed (trId: %s, enrichments: %s)", trId, trInfo.Enrichments),
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// GetRequestStatusOfObjectStorage godoc
// @Summary Check the status of a specific request by its ID
// @Description Check the status of a specific request by its ID
// @Tags [Object Storage] Operations
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param requestId path string true "Request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/object-storage/request/{requestId} [get]
func GetRequestStatusOfObjectStorage(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	reqId := c.Param("requestId")
	if reqId == "" {
		err := fmt.Errorf("invalid request, request ID (requestId: %s) is required", reqId)
		log.Warn().Msg(err.Error())
		res := model.Response{
			Success: false,
			Message: err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := config.Terrarium.Root
	// Read and set the enrichments to terrarium information
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	workingDir := projectRoot + "/.terrarium/" + trId + "/" + trInfo.Enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	statusLogFile := fmt.Sprintf("%s/runningLogs/%s.log", workingDir, reqId)

	// Check the statusReport of the request
	statusReport, err := tofu.GetExcutionHistory(trId, statusLogFile)
	if err != nil {
		err2 := fmt.Errorf("failed to get the status of the request")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := model.Response{
		Success: true,
		Message: "the status of a specific request",
		Detail:  statusReport,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
