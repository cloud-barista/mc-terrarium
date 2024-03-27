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
// GCP and AWS
type InitGcpAndAwsForVpnTunnelRequest struct {
	ResourceGroupId string `json:"resourceGroupId" default:"tofu-rg-01"`
}

// InitGcpAndAwsForVpn godoc
// @Summary Initialize GCP and AWS to configure VPN tunnels
// @Description Initialize GCP and AWS to configure VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/init [post]
func InitGcpAndAwsForVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	// @Param InitCSPs body InitGcpAndAwsForVpnTunnelRequest true "Init GCP and AWS"
	// req := new(InitGcpAndAwsForVpnTunnelRequest)
	// if err := c.Bind(req); err != nil {
	// 	res := models.Response{Success: false, Text: "Invalid request"}
	// 	return c.JSON(http.StatusBadRequest, res)
	// }

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			res := models.Response{Success: false, Text: "Failed to create directory"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/templates/vpn/gcp-aws"

	err := tofu.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to copy template files to working directory"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-gcp.json
	credentialPath := workingDir + "/credential-gcp.json"

	err = tofu.CopyGCPCredentials(credentialPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy gcp credentials to init")
		res := models.Response{Success: false, Text: "Failed to copy gcp credentials to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-aws
	// init: subcommand
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "init")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

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
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/clear [delete]
func ClearGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
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

// GetStateOfGcpAwsVpn godoc
// @Summary Get the current state of a saved plan to configure GCP to AWS VPN tunnels
// @Description Get the current state of a saved plan to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/state [get]
func GetStateOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-aws
	// show: subcommand
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "show")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to show the current state of a saved plan"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

type CreateBluprintOfGcpAwsVpnRequest struct {
	ResourceGroupId string                       `json:"resourceGroupId" default:"tofu-rg-01"`
	TfVars          models.TfVarsGcpAwsVpnTunnel `json:"tfVars"`
}

// CreateBluprintOfGcpAwsVpn godoc
// @Summary Create a blueprint to configure GCP to AWS VPN tunnels
// @Description Create a blueprint to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param ParamsForBlueprint body CreateBluprintOfGcpAwsVpnRequest true "Parameters requied to create a blueprint to configure GCP to AWS VPN tunnels"
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/blueprint [post]
func CreateBluprintOfGcpAwsVpn(c echo.Context) error {

	req := new(CreateBluprintOfGcpAwsVpnRequest)
	if err := c.Bind(req); err != nil {
		res := models.Response{Success: false, Text: "Invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + req.ResourceGroupId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource groupe (id: %v)", req.ResourceGroupId)
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

	err := tofu.SaveGcpAwsTfVarsToFile(req.TfVars, tfVarsPath)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to save tfVars to a file"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: "Successfully created a blueprint to configure GCP to AWS VPN tunnels"}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckBluprintOfGcpAwsVpn godoc
// @Summary Show changes required by the current blueprint to configure GCP to AWS VPN tunnels
// @Description Show changes required by the current blueprint to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/plan [post]
func CheckBluprintOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-aws
	// subcommand: plan
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "plan")
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

// CreateGcpAwsVpn godoc
// @Summary Create network resources for VPN tunnel in GCP and AWS
// @Description Create network resources for VPN tunnel in GCP and AWS
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws [post]
func CreateGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resouce group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-aws
	// subcommand: apply
	ret, err := tofu.ExecuteTofuCommandAsync(rgId, reqId, "-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to deploy network resources to configure GCP to AWS VPN tunnels"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

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
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws [delete]
func DestroyGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Remove the state of the imported resources
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}/vpn/gcp-aws
	// subcommand: state rm
	ret, err := tofu.ExecuteTofuCommand(rgId, reqId, "-chdir="+workingDir, "state", "rm", "aws_route_table.imported_route_table")
	if err != nil {
		text := fmt.Sprintf("Failed to destroy: %s", ret)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Remove the imported resources to prevent destroying them
	err = tofu.TruncateFile(workingDir + "/imports.tf")
	if err != nil {
		log.Error().Err(err).Msg("Failed to truncate imports.tf") // error
		text := fmt.Sprintf("failed to destroy: %s", err)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Destroy the infrastructure
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{resourceGroupId}
	// subcommand: destroy
	ret, err = tofu.ExecuteTofuCommandAsync(rgId, reqId, "-chdir="+workingDir, "destroy", "-auto-approve")
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

// GetRequestStatusOfGcpAwsVpn godoc
// @Summary Get the status of the request to configure GCP to AWS VPN tunnels
// @Description Get the status of the request to configure GCP to AWS VPN tunnels
// @Tags [VPN] GCP to AWS VPN tunnel configuration
// @Accept  json
// @Produce  json
// @Param resourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Param requestId path string true "Request ID"
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId}/vpn/gcp-aws/request/{requestId}/status [get]
func GetRequestStatusOfGcpAwsVpn(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	reqId := c.Param("requestId")
	if reqId == "" {
		res := models.Response{Success: false, Text: "Require the request ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")
	workingDir := projectRoot + "/.tofu/" + rgId + "/vpn/gcp-aws"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		errMsg := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		log.Error().Err(err).Msg(errMsg) // debug
		res := models.Response{Success: false, Text: errMsg}
		return c.JSON(http.StatusInternalServerError, res)
	}

	statusLogFile := fmt.Sprintf("%s/runningLogs/%s.log", workingDir, reqId)

	// Check the statusReport of the request
	statusReport, err := tofu.GetRunningStatus(rgId, statusLogFile)
	if err != nil {
		log.Error().Err(err).Msg("Failed to get the status of the request") // error
		res := models.Response{Success: false, Text: "Failed to get the status of the request"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: statusReport}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
