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
	"fmt"
	"net/http"
	"os"

	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/models"
	"github.com/cloud-barista/poc-mc-net-tf/pkg/tofu"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

// ////////////////////////////////////////////////////
// GCP and Azure

// type InitGcpAndAzureForVpnTunnelRequest struct {
// 	ResourceGroupId string `json:"resourceGroupId" default:"tofu-rg-01"`
// }

// InitGcpAndAzureForVpn godoc
// @Summary Initialize GCP and Azure to configure VPN tunnels
// @Description Initialize GCP and Azure to configure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure/init [post]
func InitGcpAndAzureForVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	// // @Param InitCSPs body InitGcpAndAzureForVpnTunnelRequest true "Init GCP and Azure"
	// req := new(InitGcpAndAzureForVpnTunnelRequest)
	// if err := c.Bind(req); err != nil {
	// 	res := models.Response{Success: false, Text: "Invalid request"}
	// 	return c.JSON(http.StatusBadRequest, res)
	// }

	projectRoot := viper.GetString("pocmcnettf.root")
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			res := models.Response{Success: false, Text: "Failed to create directory"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/.tofu/template-tfs/vpn/gcp-azure"

	err := tofu.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to copy template files to working directory"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-gcp.json
	gcpCredentialPath := workingDir + "/credential-gcp.json"

	err = tofu.CopyGCPCredentials(gcpCredentialPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy gcp credentials to init")
		res := models.Response{Success: false, Text: "Failed to copy gcp credentials to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	azureCredentialPath := workingDir + "/credential-azure.env"
	err = tofu.CopyAzureCredentials(azureCredentialPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy azure credentials to init")
		res := models.Response{Success: false, Text: "Failed to copy azure credentials to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-azure
	// init: subcommand
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "init")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// ClearGcpAzureVpn godoc
// @Summary Clear the entire directory and configuration files
// @Description Clear the entire directory and configuration files
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure/clear [delete]
func ClearGcpAzureVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to clear entire directory and configuration files"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := fmt.Sprintf("Successfully cleared all in the resource group (id: %v)", rgId)
	res := models.Response{Success: true, Text: text}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// GetStateOfGcpAzureVpn godoc
// @Summary Get the current state of a saved plan to configure GCP to Azure VPN tunnels
// @Description Get the current state of a saved plan to configure GCP to Azure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure/state [get]
func GetStateOfGcpAzureVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-azure
	// show: subcommand
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "show")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to show the current state of a saved plan"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

type CreateBluprintOfGcpAzureVpnRequest struct {
	TfVars models.TfVarsGcpAzureVpnTunnel `json:"tfVars"`
}

// CreateBluprintOfGcpAzureVpn godoc
// @Summary Create a blueprint to configure GCP to Azure VPN tunnels
// @Description Create a blueprint to configure GCP to Azure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param ParamsForBlueprint body CreateBluprintOfGcpAzureVpnRequest true "Parameters requied to create a blueprint to configure GCP to Azure VPN tunnels"
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure/blueprint [post]
func CreateBluprintOfGcpAzureVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	req := new(CreateBluprintOfGcpAzureVpnRequest)
	if err := c.Bind(req); err != nil {
		res := models.Response{Success: false, Text: "Invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource groupe (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Save the tfVars to a file
	tfVarsPath := workingDir + "/terraform.tfvars.json"
	// Note
	// Terraform also automatically loads a number of variable definitions files
	// if they are present:
	// - Files named exactly terraform.tfvars or terraform.tfvars.json.
	// - Any files with names ending in .auto.tfvars or .auto.tfvars.json.

	err := tofu.SaveGcpAzureTfVarsToFile(req.TfVars, tfVarsPath)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to save tfVars to a file"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: "Successfully created a blueprint to configure GCP to Azure VPN tunnels"}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckBluprintOfGcpAzureVpn godoc
// @Summary Show changes required by the current blueprint to configure GCP to Azure VPN tunnels
// @Description Show changes required by the current blueprint to configure GCP to Azure VPN tunnels
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure/plan [post]
func CheckBluprintOfGcpAzureVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-azure
	// subcommand: plan
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "plan")
	if err != nil {
		log.Error().Err(err).Msg("Failed to plan") // error
		text := fmt.Sprintf("Failed to plan\n(ret: %s)", ret)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// CreateGcpAzureVpn godoc
// @Summary Create network resources for VPN tunnel in GCP and Azure
// @Description Create network resources for VPN tunnel in GCP and Azure
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure [post]
func CreateGcpAzureVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resouce group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-azure
	// subcommand: apply
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to deploy network resources to configure GCP to Azure VPN tunnels"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// DestroyGcpAzureVpn godoc
// @Summary Destroy network resources that were used to configure GCP as an Azure VPN tunnel
// @Description Destroy network resources that were used to configure GCP as an Azure VPN tunnel
// @Tags [VPN] GCP to Azure VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-azure [delete]
func DestroyGcpAzureVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-azure"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Destroy the infrastructure
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}
	// subcommand: destroy
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "destroy", "-auto-approve")
	if err != nil {
		log.Error().Err(err).Msg("Failed to destroy") // error
		text := fmt.Sprintf("Failed to destroy: %s", ret)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}
