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
		res := models.Response{Success: false, Text: "Failed to get Tofu version"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}

	return c.JSON(http.StatusOK, res)
}

// TofuShow godoc
// @Summary Show the current state of a saved plan
// @Description Show the current state of a saved plan
// @Tags [Tofu] Commands
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response
// @Failure 503 {object} models.Response
// @Router /tofu/show/{namespaceId} [get]
func TofuShow(c echo.Context) error {

	nsId := c.Param("namespaceId")
	if nsId == "" {
		res := models.Response{Success: false, Text: "nsId is required"}
		return c.JSON(http.StatusBadRequest, res)
	}

	ret, err := tofu.ExecuteCommand("show")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to show the current state of a saved plan"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}

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
// @Success 201 {object} models.Response
// @Failure 400 {object} models.Response
// @Failure 503 {object} models.Response
// @Router /tofu/init [post]
func TofuInit(c echo.Context) error {

	req := new(TofuInitRequest)
	if err := c.Bind(req); err != nil {
		res := models.Response{Success: false, Text: "Invalid request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")
	workingDir := projectRoot + "/.tofu/" + req.NamespaceId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			res := models.Response{Success: false, Text: "Failed to create directory"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy template files to the working directory if not exist
	newMainTfPath := workingDir + "/main.tf"

	if _, err := os.Stat(newMainTfPath); os.IsNotExist(err) {
		templatePath := projectRoot + "/.tofu/template-tfs/ha-vpn-tunnels"

		mainTfPath := templatePath + "/main.tf"

		log.Debug().Msgf("mainTfPath: %s", mainTfPath)
		log.Debug().Msgf("newMainTfPath: %s", newMainTfPath)

		err := tofu.CopyTemplates(mainTfPath, newMainTfPath)
		if err != nil {
			log.Error().Err(err).Msg("Failed to copy main.tf to init")
			res := models.Response{Success: false, Text: "Failed to copy tf files to init"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// Copy gcp credentials to the working directory if not exist
	credentialPath := workingDir + "/credential-gcp.json"

	if _, err := os.Stat(credentialPath); os.IsNotExist(err) {
		err = tofu.CopyGCPCredentials(credentialPath)
		if err != nil {
			log.Error().Err(err).Msg("Failed to copy gcp credentials to init")
			res := models.Response{Success: false, Text: "Failed to copy gcp credentials to init"}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	// global option to set working dir: -chdir=/home/ubuntu/dev/cloud-barista/poc-mc-net-tf/.tofu/{namespaceId}
	// init: subcommand
	ret, err := tofu.ExecuteCommand("-chdir="+workingDir, "init")
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to init"}
		return c.JSON(http.StatusInternalServerError, res)
	}
	res := models.Response{Success: true, Text: ret}

	return c.JSON(http.StatusCreated, res)
}
