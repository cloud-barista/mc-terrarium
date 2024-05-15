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

package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/models"
	"github.com/cloud-barista/mc-terrarium/pkg/tofu"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
	"github.com/tidwall/gjson"
)

// ////////////////////////////////////////////////////
// GCP and AWS

// InitTerrariumForGcpAwsVpn godoc
// @Summary Initialize a multi-cloud terrarium for GCP to AWS VPN tunnel
// @Description Initialize a multi-cloud terrarium for GCP to AWS VPN tunnel
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept json
// @Produce json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} models.ResponseText "Created"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/terrarium [post]
func InitTerrariumForGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("mcterrarium.root")
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to create a working directory")
			log.Error().Err(err).Msg(err2.Error())
			res := models.ResponseText{Success: false, Text: err2.Error()}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/templates/vpn/gcp-aws"

	err := tofu.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		err2 := fmt.Errorf("failed to copy template files to working directory")
		log.Error().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-gcp.json
	credentialPath := workingDir + "/credential-gcp.json"

	err = tofu.CopyGCPCredentials(credentialPath)
	if err != nil {
		err2 := fmt.Errorf("failed to copy gcp credentials")
		log.Error().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}/vpn/gcp-aws
	// init: subcommand
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "init")
	if err != nil {
		err2 := fmt.Errorf("failed to initialize an infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.ResponseText{
		Success: true,
		Text:    ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// ClearGcpAwsVpn godoc
// @Summary Clear the entire directory and configuration files
// @Description Clear the entire directory and configuration files
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} models.ResponseText "OK"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/clear [delete]
func ClearGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		err2 := fmt.Errorf("failed to remove working directory and all configuration files")
		log.Error().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := "successfully remove all in the working directory"
	res := models.ResponseText{
		Success: true,
		Text:    text,
	}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// GetResourceInfoOfGcpAwsVpn godoc
// @Summary Get resource info to configure GCP to AWS VPN tunnels
// @Description Get resource info to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "resource group ID" default(tofu-rg-01)
// @Param detail query string false "Resource info by detail (refined, raw)" default(refined)
// @Param x-request-id header string false "custom request ID"
// @Success 200 {object} models.ResponseText "OK"
// @Success 200 {object} models.ResponseList "OK"
// @Success 200 {object} models.ResponseObject "OK"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws [get]
func GetResourceInfoOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
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
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Get the resource info by the detail option
	switch detail {
	case DetailOptions.Refined:
		// Code for handling "refined" detail option

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}/vpn/gcp-aws
		// show: subcommand
		ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "output", "-json")
		if err != nil {
			err2 := fmt.Errorf("failed to read resource info (detail: %s) specified as 'output' in the state file", DetailOptions.Refined)
			log.Error().Err(err).Msg(err2.Error())
			res := models.ResponseText{
				Success: false,
				Text:    err2.Error(),
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		var resourceInfo map[string]interface{}
		err = json.Unmarshal([]byte(ret), &resourceInfo)
		if err != nil {
			log.Error().Err(err).Msg("") // error
			res := models.ResponseText{
				Success: false,
				Text:    "failed to unmarshal resource info",
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		res := models.ResponseObject{
			Success: true,
			Object:  resourceInfo,
		}
		log.Debug().Msgf("%+v", res) // debug

		return c.JSON(http.StatusOK, res)

	case DetailOptions.Raw:
		// Code for handling "raw" detail option

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}/vpn/gcp-aws
		// show: subcommand
		// Get resource info from the state or plan file
		ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "show", "-json")
		if err != nil {
			err2 := fmt.Errorf("failed to read resource info (detail: %s) from the state or plan file", DetailOptions.Raw)
			log.Error().Err(err).Msg(err2.Error()) // error
			res := models.ResponseText{
				Success: false,
				Text:    err2.Error(),
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		// Parse the resource info
		resourcesString := gjson.Get(ret, "values.root_module.resources").String()
		if resourcesString == "" {
			err2 := fmt.Errorf("could not find resource info (rgId: %s)", rgId)
			log.Warn().Msg(err2.Error())
			res := models.ResponseText{
				Success: false,
				Text:    err2.Error(),
			}
			return c.JSON(http.StatusOK, res)
		}

		var resourceInfoList []interface{}
		err = json.Unmarshal([]byte(resourcesString), &resourceInfoList)
		if err != nil {
			log.Error().Err(err).Msg("") // error
			res := models.ResponseText{
				Success: false,
				Text:    "failed to unmarshal resource info",
			}
			return c.JSON(http.StatusInternalServerError, res)
		}

		res := models.ResponseList{
			Success: true,
			List:    resourceInfoList,
		}
		log.Debug().Msgf("%+v", res) // debug

		return c.JSON(http.StatusOK, res)
	default:
		err2 := fmt.Errorf("invalid detail option (%s)", detail)
		log.Warn().Err(err2).Msg("") // warn
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}
}

type CreateBluprintOfGcpAwsVpnRequest struct {
	TfVars models.TfVarsGcpAwsVpnTunnel `json:"tfVars"`
}

// CreateInfracodeOfGcpAwsVpn godoc
// @Summary Create the infracode to configure GCP to AWS VPN tunnels
// @Description Create the infracode to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param ParamsForInfracode body CreateBluprintOfGcpAwsVpnRequest true "Parameters requied to create the infracode to configure GCP to AWS VPN tunnels"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} models.ResponseText "Created"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 500 {object} models.ResponseTextWithDetails "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/infracode [post]
func CreateInfracodeOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	req := new(CreateBluprintOfGcpAwsVpnRequest)
	if err := c.Bind(req); err != nil {
		err2 := fmt.Errorf("invalid request format, %v", err)
		log.Warn().Err(err).Msg("invalid request format")
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
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

	if req.TfVars.ResourceGroupId == "" {
		log.Warn().Msgf("resource group ID is not set, Use path param: %s", rgId) // warn
		req.TfVars.ResourceGroupId = rgId
	}

	err := tofu.SaveGcpAwsTfVarsToFile(req.TfVars, tfVarsPath)
	if err != nil {
		err2 := fmt.Errorf("failed to save tfVars to a file")
		log.Error().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.ResponseText{
		Success: true,
		Text:    "Successfully created the infracode to configure GCP to AWS VPN tunnels",
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckInfracodeOfGcpAwsVpn godoc
// @Summary Check and show changes by the current infracode to configure GCP to AWS VPN tunnels
// @Description Check and show changes by the current infracode to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} models.ResponseTextWithDetails "OK"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 500 {object} models.ResponseTextWithDetails "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/plan [post]
func CheckInfracodeOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}/vpn/gcp-aws
	// subcommand: plan
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "plan")
	if err != nil {
		err2 := fmt.Errorf("encountered an issue during the infracode checking process")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := models.ResponseTextWithDetails{
			Success: false,
			Text:    err2.Error(),
			Details: ret,
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.ResponseTextWithDetails{
		Success: true,
		Text:    "successfully completed the infracode checking process",
		Details: ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// CreateGcpAwsVpn godoc
// @Summary Create network resources for VPN tunnel in GCP and AWS
// @Description Create network resources for VPN tunnel in GCP and AWS
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} models.ResponseTextWithDetails "Created"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws [post]
func CreateGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}/vpn/gcp-aws
	// subcommand: apply
	ret, err := tofu.ExecuteTofuCommandAsync(rgId, reqId, "-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		err2 := fmt.Errorf("failed, previous request in progress")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.ResponseTextWithDetails{
		Success: true,
		Text:    "successfully accepted the request to deploy resource (currently being processed)",
		Details: ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// DestroyGcpAwsVpn godoc
// @Summary Destroy network resources that were used to configure GCP as an AWS VPN tunnel
// @Description Destroy network resources that were used to configure GCP as an AWS VPN tunnel
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} models.ResponseText "OK"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 500 {object} models.ResponseTextWithDetails "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws [delete]
func DestroyGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("mcterrarium.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Remove the state of the imported resources
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}/vpn/gcp-aws
	// subcommand: state rm
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "state", "rm", "aws_route_table.imported_route_table")
	if err != nil {
		err2 := fmt.Errorf("failed to remove the state of the imported resources")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := models.ResponseTextWithDetails{
			Success: false,
			Text:    err2.Error(),
			Details: ret,
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Remove the imported resources to prevent destroying them
	err = tofu.TruncateFile(workingDir + "/imports.tf")
	if err != nil {
		err2 := fmt.Errorf("failed to truncate imports.tf")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Destroy the infrastructure
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.tofu/{resourceGroupId}
	// subcommand: destroy
	ret, err = tofu.ExecuteTofuCommandAsync(rgId, reqId, "-chdir="+workingDir, "destroy", "-auto-approve")
	if err != nil {
		err2 := fmt.Errorf("failed, previous request in progress")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.ResponseTextWithDetails{
		Success: true,
		Text:    "successfully accepted the request to destroy the resouces (currently being processed)",
		Details: ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// GetRequestStatusOfGcpAwsVpn godoc
// @Summary Check the status of a specific request by its ID
// @Description Check the status of a specific request by its ID
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param requestId path string true "Request ID"
// @Success 200 {object} models.ResponseText "OK"
// @Failure 400 {object} models.ResponseText "Bad Request"
// @Failure 500 {object} models.ResponseText "Internal Server Error"
// @Failure 503 {object} models.ResponseText "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/request/{requestId}/status [get]
func GetRequestStatusOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		err := fmt.Errorf("invalid request, resource groud ID (rgId: %s) is required", rgId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	reqId := c.Param("requestId")
	if reqId == "" {
		err := fmt.Errorf("invalid request, request ID (requestId: %s) is required", reqId)
		log.Warn().Msg(err.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err.Error(),
		}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("mcterrarium.root")
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err2 := fmt.Errorf("working directory dose not exist")
		log.Warn().Err(err).Msg(err2.Error())
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}
	statusLogFile := fmt.Sprintf("%s/runningLogs/%s.log", workingDir, reqId)

	// Check the statusReport of the request
	statusReport, err := tofu.GetRunningStatus(rgId, statusLogFile)
	if err != nil {
		err2 := fmt.Errorf("failed to get the status of the request")
		log.Error().Err(err).Msg(err2.Error()) // error
		res := models.ResponseText{
			Success: false,
			Text:    err2.Error(),
		}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.ResponseText{
		Success: true,
		Text:    statusReport,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
