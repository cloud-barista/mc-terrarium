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
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/spf13/viper"
)

// ClearResourceGroup godoc
// @Summary Clear the entire directories and configuration files
// @Description Clear the entire directories and configuration files
// @Tags [ResourceGroup] Resource group
// @Accept  json
// @Produce  json
// @Param ResourceGroupId path string true "Resource group ID" default(tofu-rg-01)
// @Success 200 {object} models.Response "OK"
// @Failure 400 {object} models.Response "Bad Request"
// @Failure 503 {object} models.Response "Service Unavailable"
// @Router /rg/{resourceGroupId} [delete]
func ClearResourceGroup(c echo.Context) error {

	rgId := c.Param("resourceGroupId")
	if rgId == "" {
		res := models.Response{Success: false, Text: "Require the resource group ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := viper.GetString("pocmcnettf.root")

	// Check if the working directory exists
	workingDir := projectRoot + "/.tofu/" + rgId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("Not exist resource group (id: %v)", rgId)
		res := models.Response{Success: false, Text: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		res := models.Response{Success: false, Text: "Failed to clear entire directories and configuration files"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := fmt.Sprintf("Successfully cleared all in the resource group (id: %v)", rgId)
	res := models.Response{Success: true, Text: text}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
