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
	"github.com/cloud-barista/mc-terrarium/pkg/tofu"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/tidwall/gjson"
)

// ////////////////////////////////////////////////////
// Test env

// InitTerrariumForTestEnv godoc
// @Summary Initialize a multi-cloud terrarium for test environment
// @Description Initialize a multi-cloud terrarium for test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env/init [post]
func InitTerrariumForTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			res := model.Response{Success: false, Message: "Failed to create directory"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory (overwrite)
	templateTfsPath := projectRoot + "/templates/test-env"

	err := tofu.CopyFiles(templateTfsPath, workingDir)
	if err != nil {
		res := model.Response{Success: false, Message: "Failed to copy template files to working directory"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// Always overwrite credential-gcp.json
	gcpCredentialPath := workingDir + "/credential-gcp.json"

	err = tofu.CopyGCPCredentials(gcpCredentialPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy gcp credentials to init")
		res := model.Response{Success: false, Message: "Failed to copy gcp credentials to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	azureCredentialPath := workingDir + "/credential-azure.env"
	err = tofu.CopyAzureCredentials(azureCredentialPath)
	if err != nil {
		log.Error().Err(err).Msg("Failed to copy azure credentials to init")
		res := model.Response{Success: false, Message: "Failed to copy azure credentials to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/test-env
	// init: subcommand
	ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "init")
	if err != nil {
		res := model.Response{Success: false, Message: "Failed to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{
		Success: true,
		Message: "successfully initialized the multi-cloud terrarium for test environment",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// ClearTestEnv godoc
// @Summary Clear the entire directory and configuration files
// @Description Clear the entire directory and configuration files
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env/env [delete]
func ClearTestEnv(c echo.Context) error {

	projectRoot := config.Terrarium.Root

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test-env"
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		res := model.Response{Success: false, Message: "Failed to clear entire directory and configuration files"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := "Successfully cleared all in the test environment"
	res := model.Response{Success: true, Message: text}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// GetResouceInfoOfTestEnv godoc
// @Summary Get all resource info of test environment
// @Description Get all resource info of test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Param detail query string false "Resource info by detail (refined, raw)" default(refined)
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env [get]
func GetResouceInfoOfTestEnv(c echo.Context) error {

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

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
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
		ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "output", "-json")
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
			Message: "refined resource info (map)",
			Object:  resourceInfo,
		}
		log.Debug().Msgf("%+v", res) // debug

		return c.JSON(http.StatusOK, res)

	case DetailOptions.Raw:
		// Code for handling "raw" detail option

		// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/{trId}/vpn/gcp-aws
		// show: subcommand
		// Get resource info from the state or plan file
		ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "show", "-json")
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
			err2 := fmt.Errorf("could not find resource info (trId: %s)", "test-env")
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

// CreateInfrcodeOfGcpAzureVpn godoc
// @Summary Create the infracode to configure test environment
// @Description Create the infracode to configure test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Param ParamsForInfracode body model.CreateInfracodeOfTestEnvRequest true "Parameters requied to create the infracode to configure test environment"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env/infracode [post]
func CreateInfracodeOfTestEnv(c echo.Context) error {

	req := new(model.CreateInfracodeOfTestEnvRequest)
	if err := c.Bind(req); err != nil {
		res := model.Response{Success: false, Message: "Invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := config.Terrarium.Root

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := model.Response{Success: false, Message: text}
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
		res := model.Response{Success: false, Message: "Failed to save tfVars to a file"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := model.Response{Success: true, Message: "Successfully created the infracode to configure test environment"}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// CheckInfracodeOfTestEnv godoc
// @Summary Check the infracode and show changes of test environment
// @Description Check the infracode and show changes of test environment
// @Tags [Test env] Test environment management
// @Accept json
// @Produce json
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env/plan [post]
func CheckInfracodeOfTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environemt"
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/test-env
	// subcommand: plan
	ret, err := tofu.ExecuteTofuCommand("test-env", reqId, "-chdir="+workingDir, "plan")
	if err != nil {
		log.Error().Err(err).Msg("Failed to plan") // error
		text := fmt.Sprintf("Failed to plan\n(ret: %s)", ret)
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{Success: true, Message: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}

// CreateTestEnv godoc
// @Summary Create test environment
// @Description Create test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env [post]
func CreateTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/test-env
	// subcommand: apply
	ret, err := tofu.ExecuteTofuCommandAsync("test-env", reqId, "-chdir="+workingDir, "apply", "-auto-approve")
	if err != nil {
		res := model.Response{Success: false, Message: "Failed to deploy test environment"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{Success: true, Message: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusCreated, res)
}

// DestroyTestEnv godoc
// @Summary Destroy test environment
// @Description Destroy test environment
// @Tags [Test env] Test environment management
// @Accept  json
// @Produce  json
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env [delete]
func DestroyTestEnv(c echo.Context) error {

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	projectRoot := config.Terrarium.Root

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	// Destroy the infrastructure
	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/mc-terrarium/.terrarium/test-env
	// subcommand: destroy
	ret, err := tofu.ExecuteTofuCommandAsync("test-env", reqId, "-chdir="+workingDir, "destroy", "-auto-approve")
	if err != nil {
		log.Error().Err(err).Msg("Failed to destroy") // error
		text := fmt.Sprintf("Failed to destroy: %s", ret)
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := model.Response{Success: true, Message: ret}

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
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /test-env/request/{requestId}/status [get]
func GetRequestStatusOfTestEnv(c echo.Context) error {

	reqId := c.Param("requestId")
	if reqId == "" {
		res := model.Response{Success: false, Message: "Require the request ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := config.Terrarium.Root
	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/test-env"
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := "Not exist test environment"
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	statusLogFile := fmt.Sprintf("%s/runningLogs/%s.log", workingDir, reqId)

	// Check the statusReport of the request
	statusReport, err := tofu.GetRunningStatus("test-env", statusLogFile)
	if err != nil {
		res := model.Response{Success: false, Message: "Failed to get the status of the request"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := model.Response{Success: true, Message: statusReport}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
