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
// Test env

// InitTestEnv godoc
// @Summary Initialize test environment
// @Description Initialize test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env/init [post]
func InitTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			res := models.Response{Success: false, Text: "Failed to create directory"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/.tofu/template-tfs/test-env"

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

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/test-env
	// init: subcommand
	ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "init")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// ClearTestEnv godoc
// @Summary Clear the entire directory and configuration files
// @Description Clear the entire directory and configuration files
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env/clear [delete]
func ClearTestEnv(c echo.Context) error {

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test-env"
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to clear entire directory and configuration files"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := "Successfully cleared all in the test environment"
	res := models.Response{Success: true, Text: text}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// GetStateOfTestEnv godoc
// @Summary Get the current state of a saved plan of test environment
// @Description Get the current state of a saved plan of test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env/state [get]
func GetStateOfTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/test-env
	// show: subcommand
	ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "show")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to show the current state of a saved plan"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

type CreateBluprintOfTestEnvRequest struct {
	TfVars models.TfVarsTestEnv `json:"tfVars"`
}

// CreateBluprintOfGcpAzureVpn godoc
// @Summary Create a blueprint to configure test environment
// @Description Create a blueprint to configure test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Param ParamsForBlueprint body CreateBluprintOfTestEnvRequest true "Parameters requied to create a blueprint to configure test environment"
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env/blueprint [post]
func CreateBluprintOfTestEnv(c echo.Context) error {

	req := new(CreateBluprintOfTestEnvRequest)
	if err := c.Bind(req); err != nil {
		res := models.Response{Success: false, Text: "Invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
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

	err := tofu.SaveTestEnvTfVarsToFile(req.TfVars, tfVarsPath)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to save tfVars to a file"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: "Successfully created a blueprint to configure test environment"}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckBluprintOfTestEnv godoc
// @Summary Show changes required by the current blueprint to configure test environment
// @Description Show changes required by the current blueprint to configure test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env/plan [post]
func CheckBluprintOfTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environemt"
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/test-env
	// subcommand: plan
	ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "plan")
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

// CreateTestEnv godoc
// @Summary Create test environment
// @Description Create test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 201 {object} models.Response "Created"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env [post]
func CreateTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/test-env
	// subcommand: apply
	ret, err := tofu.ExecuteTofuCommandAsync("test-env", reqId, "-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to deploy test environment"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// DestroyTestEnv godoc
// @Summary Destroy test environment
// @Description Destroy test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env [delete]
func DestroyTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Destroy the infrastructure
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/test-env
	// subcommand: destroy
	ret, err := tofu.ExecuteTofuCommandAsync("test-env", reqId, "-chdir="+workingDir, "destroy", "-auto-approve")
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

// GetRequestStatusOfTestEnv godoc
// @Summary Get the status of the request to configure test environment
// @Description Get the status of the request to configure test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Param requestId path string true "Request ID"
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /test-env/request/{requestId}/status [get]
func GetRequestStatusOfTestEnv(c echo.Context) error {

	reqId := c.Param("requestId")
	if reqId == "" {
		res := models.Response{Success: false, Text: "Require the request ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")
	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	statusLogFile := fmt.Sprintf("%s/runningLogs/%s.log", workingDir, reqId)

	// Check the statusReport of the request
	statusReport, err := tofu.GetRunningStatus("test-env", statusLogFile)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to get the status of the request"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: statusReport}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
