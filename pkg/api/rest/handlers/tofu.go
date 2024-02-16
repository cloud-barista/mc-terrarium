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

// TofuVersion godoc
// @Summary Check Tofu version
// @Description Check Tofu version
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response
// @Failure 503 {object} models.Response
// @Router /tofu/version [get]
func TofuVersion(c echo.Context) error {

	ret, err := tofu.ExecuteCommand("version")
	if err != nil {
		res := models.Response{Success: false, Text: "failed to get Tofu version"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// TofuShow godoc
// @Summary Show the current state of a saved plan
// @Description Show the current state of a saved plan
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param namespaceId path string true "Namespace ID"
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/show/{namespaceId} [get]
func TofuShow(c echo.Context) error {

	nsId := c.Param("namespaceId")
	if nsId == "" {
		res := models.Response{Success: false, Text: "namespace ID is rquired"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + nsId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("the namespace (id: %v) does not exist", nsId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// show: subcommand
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "show")
	if err != nil {
		res := models.Response{Success: false, Text: "failed to destroy"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// TofuCleanup godoc
// @Summary Cleanup the namespace
// @Description Cleanup the namespace
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param namespaceId path string true "Namespace ID"
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/cleanup/{namespaceId} [delete]
func TofuCleanup(c echo.Context) error {

	nsId := c.Param("namespaceId")
	if nsId == "" {
		res := models.Response{Success: false, Text: "namespace ID is rquired"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + nsId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("the namespace (id: %v) does not exist", nsId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "failed to cleanup"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := fmt.Sprintf("The namespace (%v) is cleaned up successfully", nsId)
	res := models.Response{Success: true, Text: text}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

type TofuInitRequest struct {
	NamespaceId string `json:"namespaceId"`
}

// TofuInit godoc
// @Summary Prepare your working directory for other commands
// @Description Prepare your working directory for other commands
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param TofuInitRequest body TofuInitRequest true "TofuInitRequest"
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/init [post]
func TofuInit(c echo.Context) error {

	req := new(TofuInitRequest)
	if err := c.Bind(req); err != nil {
		res := models.Response{Success: false, Text: "invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")
	workingDir := projectRoot + "/.tofu/" + req.NamespaceId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			res := models.Response{Success: false, Text: "failed to create directory"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory if not exist
	newMainTfPath := workingDir + "/main.tf"

	// Alway overwrite main.tf
	templatePath := projectRoot + "/.tofu/template-tfs/init"

	mainTfPath := templatePath + "/main.tf"

	log.Debug().Msgf("mainTfPath: %s", mainTfPath)
	log.Debug().Msgf("newMainTfPath: %s", newMainTfPath)

	err := tofu.CopyTemplateFile(mainTfPath, newMainTfPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy main.tf to init")
		res := models.Response{Success: false, Text: "failed to copy tf files to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-gcp.json
	credentialPath := workingDir + "/credential-gcp.json"

	err = tofu.CopyGCPCredentials(credentialPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy gcp credentials to init")
		res := models.Response{Success: false, Text: "failed to copy gcp credentials to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// init: subcommand
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "init")
	if err != nil {
		res := models.Response{Success: false, Text: "failed to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

type TofuConfigVPNTunnelsRequest struct {
	NamespaceId string                  `json:"namespaceId"`
	TfVars      models.TfVarsVPNTunnels `json:"tfVars"`
}

// TofuConfigVPNTunnels godoc
// @Summary Create configurations for VPN tunnels
// @Description Create configurations for VPN tunnels
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param ConfigVPNTunnels body TofuConfigVPNTunnelsRequest true "Create configurations for VPN tunnels"
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/config/vpn-tunnels [post]
func TofuConfigVPNTunnels(c echo.Context) error {

	req := new(TofuConfigVPNTunnelsRequest)
	if err := c.Bind(req); err != nil {
		res := models.Response{Success: false, Text: "invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + req.NamespaceId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("the namespace (id: %v) does not exist", req.NamespaceId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/.tofu/template-tfs/ha-vpn-tunnels"

	err := tofu.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "failed to copy template files to working directory"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Save the tfVars to a file
	tfVarsPath := workingDir + "/terraform.tfvars.json"
	// Note
	// Terraform also automatically loads a number of variable definitions files
	// if they are present:
	// - Files named exactly terraform.tfvars or terraform.tfvars.json.
	// - Any files with names ending in .auto.tfvars or .auto.tfvars.json.

	err = tofu.SaveTfVarsToFile(req.TfVars, tfVarsPath)
	if err != nil {
		res := models.Response{Success: false, Text: "failed to save tfVars to a file"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: "configurations for VPN tunnels are created successfully"}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

type TofuPlanVPNTunnelsRequest struct {
	NamespaceId string `json:"namespaceId"`
}

// TofuPlanVPNTunnels godoc
// @Summary Show changes required by the current configuration for VPN tunnels
// @Description Show changes required by the current configuration for VPN tunnels
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param namespaceId path string true "Namespace ID"
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/plan/vpn-tunnels/{namespaceId} [post]
func TofuPlanVPNTunnels(c echo.Context) error {

	nsId := c.Param("namespaceId")
	if nsId == "" {
		res := models.Response{Success: false, Text: "namespace ID is rquired"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + nsId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("the namespace (id: %v) does not exist", nsId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// subcommand: plan
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "plan")
	if err != nil {
		log.Error().Err(err).Msg("Failed to plan") // error
		text := fmt.Sprintf("failed to plan\n%s", ret)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// TofuApplyVPNTunnels godoc
// @Summary Create or update infrastructure for VPN tunnels
// @Description Create or update infrastructure for VPN tunnels
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param namespaceId path string true "Namespace ID"
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/apply/vpn-tunnels/{namespaceId} [post]
func TofuApplyVPNTunnels(c echo.Context) error {

	nsId := c.Param("namespaceId")
	if nsId == "" {
		res := models.Response{Success: false, Text: "namespace ID is rquired"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + nsId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("the namespace (id: %v) does not exist", nsId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// subcommand: apply
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		res := models.Response{Success: false, Text: "failed to apply"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// TofuDestroyVPNTunnels godoc
// @Summary Destroy previously-created infrastructure for VPN tunnels
// @Description Destroy previously-created infrastructure for VPN tunnels
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Param namespaceId path string true "Namespace ID"
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /tofu/destroy/vpn-tunnels/{namespaceId} [delete]
func TofuDestroyVPNTunnels(c echo.Context) error {

	nsId := c.Param("namespaceId")
	if nsId == "" {
		res := models.Response{Success: false, Text: "namespace ID is rquired"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + nsId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("the namespace (id: %v) does not exist", nsId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Remove the state of the imported resources
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// subcommand: state rm
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "state", "rm", "aws_route_table.my-imported-aws-route-table")
	if err != nil {
		text := fmt.Sprintf("failed to destroy: %s", ret)
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
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// subcommand: destroy
	ret, err = tofu.ExecuteCommand("-chdir="+workingDir, "destroy", "-auto-approve")
	if err != nil {
		log.Error().Err(err).Msg("Failed to destroy") // error
		text := fmt.Sprintf("failed to destroy: %s", ret)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}
