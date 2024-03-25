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
	"github.com/rs/zerolog/log"
)

// Health godoc
// @Summary Check API server is running
// @Description Check API server is running
// @Tags [System] Utility
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response
// @Failure 503 {object} models.Response
// @Router /health [get]
func Health(c echo.Context) error {
	res := models.Response{Success: true, Text: "POC-MC-Net-TF API server is running"}

	return c.JSON(http.StatusOK, res)
}

// HTTPVersion godoc
// @Summary Check HTTP version of incoming request
// @Description Checks and logs the HTTP version of the incoming request to the server console.
// @Tags [System] Utility
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response
// @Failure 404 {object} models.Response
// @Failure 500 {object} models.Response
// @Router /httpVersion [get]
func HTTPVersion(c echo.Context) error {
	// Access the *http.Request object from the echo.Context
	req := c.Request()

	// Determine the HTTP protocol version of the request
	res := models.Response{Success: true, Text: req.Proto}

	return c.JSON(http.StatusOK, res)
}

// TofuVersion godoc
// @Summary Check Tofu version
// @Description Check Tofu version
// @Tags [System] Utility
// @Accept  json
// @Produce  json
// @Success 200 {object} models.Response
// @Failure 503 {object} models.Response
// @Router /tofuVersion [get]
func TofuVersion(c echo.Context) error {

	ret, err := tofu.GetTofuVersion()
	if err != nil {
		res := models.Response{Success: false, Text: "failed to get Tofu version"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	res := models.Response{Success: true, Text: ret}

	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
