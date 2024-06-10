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
	"github.com/cloud-barista/mc-terrarium/pkg/terrarium"
	"github.com/cloud-barista/mc-terrarium/pkg/tofu"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
	"github.com/tidwall/gjson"
)

// ////////////////////////////////////////////////////
// GCP and Azure

// InitEnvForGcpAzureVpn godoc
// @Summary Initialize a multi-cloud terrarium for GCP to Azure VPN tunnel
// @Description Initialize a multi-cloud terrarium for GCP to Azure VPN tunnel
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure/env [post]
func InitEnvForGcpAzureVpn(c echo.Context) error {

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

	// Set the enrichments
	enrichments := "vpn/gcp-azure"

	// Read and set the enrichments to terrarium information
	trInfo, err := terrarium.ReadTerrariumInfo(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to read terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	trInfo.Enrichments = enrichments
	err = terrarium.UpdateTerrariumInfo(trInfo)
	if err != nil {
		err2 := fmt.Errorf("failed to update terrarium information")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{Success: false, Message: err2.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	projectRoot := viper.GetString("mcterrarium.root")
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to create a working directory")
			log.Error().Err(err).Msg(err2.Error())
			res := model.Response{
				Success: false,
				Message: err2.Error(),
			}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/templates/" + enrichments

	err = tofu.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		err2 := fmt.Errorf("failed to copy template files to working directory")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-gcp.json
	gcpCredentialPath := workingDir + "/credential-gcp.json"

	err = tofu.CopyGCPCredentials(gcpCredentialPath)
	if err != nil {
		err2 := fmt.Errorf("failed to copy gcp credentials")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-azure.env
	azureCredentialPath := workingDir + "/credential-azure.env"
	err = tofu.CopyAzureCredentials(azureCredentialPath)
	if err != nil {
		err2 := fmt.Errorf("failed to copy azure credentials")
		log.Error().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/vpn/gcp-azure
	// init: subcommand
	ret, err := tofu.ExecuteTofuCommand(trId, reqId, "-chdir="+workingDir, "init")
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

// ClearGcpAzureVpn godoc
// @Summary Clear the entire directory and configuration files
// @Description Clear the entire directory and configuration files
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure/env [delete]
func ClearGcpAzureVpn(c echo.Context) error {

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

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err := os.RemoveAll(workingDir)
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

// GetResourceInfoOfGcpAzureVpn godoc
// @Summary Get resource info to configure GCP to Azure VPN tunnels
// @Description Get resource info to configure GCP to Azure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure [get]
func GetResourceInfoOfGcpAzureVpn(c echo.Context) error {

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

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
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

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/vpn/gcp-aws
		// show: subcommand
		ret, err := tofu.ExecuteTofuCommand(trId, reqId, "-chdir="+workingDir, "output", "-json")
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

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/vpn/gcp-aws
		// show: subcommand
		// Get resource info from the state or plan file
		ret, err := tofu.ExecuteTofuCommand(trId, reqId, "-chdir="+workingDir, "show", "-json")
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
			Message: "raw read resource info (list)",
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

// CreateInfracodeOfGcpAzureVpn godoc
// @Summary Create the infracode to configure GCP to Azure VPN tunnels
// @Description Create the infracode to configure GCP to Azure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ParamsForInfracode body model.CreateInfracodeOfGcpAzureVpnRequest true "Parameters requied to create the infracode to configure GCP to Azure VPN tunnels"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure/infracode [post]
func CreateInfracodeOfGcpAzureVpn(c echo.Context) error {

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

	req := new(model.CreateInfracodeOfGcpAzureVpnRequest)
	if err := c.Bind(req); err != nil {
		err2 := fmt.Errorf("invalid request format, %v", err)
		log.Warn().Err(err).Msg("invalid request format")
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
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

	if req.TfVars.TerrariumId == "" {
		log.Warn().Msgf("terrarium ID is not set, Use path param: %s", trId) // warn
		req.TfVars.TerrariumId = trId
	}

	err := tofu.SaveGcpAzureTfVarsToFile(req.TfVars, tfVarsPath)
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
		Message: "the infracode to configure GCP to Azure VPN tunnels is Successfully created",
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckInfracodeOfGcpAzureVpn godoc
// @Summary Check and show changes by the current infracode to configure GCP to Azure VPN tunnels
// @Description Check and show changes by the current infracode to configure GCP to Azure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure/plan [post]
func CheckInfracodeOfGcpAzureVpn(c echo.Context) error {

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

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/vpn/gcp-azure
	// subcommand: plan
	ret, err := tofu.ExecuteTofuCommand(trId, reqId, "-chdir="+workingDir, "plan")
	if err != nil {
		err2 := fmt.Errorf("encountered an issue during the infracode checking process")
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

// CreateGcpAzureVpn godoc
// @Summary Create network resources for VPN tunnel in GCP and Azure
// @Description Create network resources for VPN tunnel in GCP and Azure
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure [post]
func CreateGcpAzureVpn(c echo.Context) error {

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

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := model.Response{
			Success: false,
			Message: err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/vpn/gcp-azure
	// subcommand: apply
	ret, err := tofu.ExecuteTofuCommandAsync(trId, reqId, "-chdir="+workingDir, "apply", "-auto-approve")
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
		Message: "the request (id: " + reqId + ") is successfully accepted and still deploying resource",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// DestroyGcpAzureVpn godoc
// @Summary Destroy network resources that were used to configure GCP as an Azure VPN tunnel
// @Description Destroy network resources that were used to configure GCP as an Azure VPN tunnel
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure [delete]
func DestroyGcpAzureVpn(c echo.Context) error {

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

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
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
	ret, err := tofu.ExecuteTofuCommand(trId, reqId, "-chdir="+workingDir, "destroy", "-auto-approve")
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
		Message: "the destroying process is successfully completed (trId: " + trId + ", enrichments: vpn/gcp-aws)",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// GetRequestStatusOfGcpAzureVpn godoc
// @Summary Check the status of a specific request by its ID
// @Description Check the status of a specific request by its ID
// @Tags [VPN] GCP to Azure VPN tunnel configuration (under development)
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param requestId path string true "Request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/gcp-azure/request/{requestId} [get]
func GetRequestStatusOfGcpAzureVpn(c echo.Context) error {

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

	projectRoot := viper.GetString("mcterrarium.root")
	workingDir := projectRoot + "/.terrarium/" + trId + "/vpn/gcp-azure"
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
	statusReport, err := tofu.GetRunningStatus(trId, statusLogFile)
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
