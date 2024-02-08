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

	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/models"
	"github.com/cloud-barista/poc-mc-net-tf/pkg/tofu"
	"github.com/labstack/echo/v4"
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
		res := models.Response{Success: false, Message: "Failed to get Tofu version"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Message: ret}

	return c.JSON(http.StatusOK, res)
}
