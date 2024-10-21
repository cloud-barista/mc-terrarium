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
	"fmt"
	"net/http"
	"os"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/cloud-barista/mc-terrarium/pkg/terrarium"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
)

// IssueTerrarium godoc
// @Summary Issue/create a terrarium
// @Description Issue/create a terrarium
// @Tags [Terrarium] An environment to enrich the multi-cloud infrastructure
// @Accept  json
// @Produce  json
// @Param TerrariumInfo body model.TerrariumInfo true "Information for a new terrarium"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr [post]
func IssueTerrarium(c echo.Context) error {

	reqTrInfo := new(model.TerrariumInfo)
	if err := c.Bind(reqTrInfo); err != nil {
		res := model.Response{Success: false, Message: "failed to bind the request"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := config.Terrarium.Root

	trId := reqTrInfo.Id

	// Create the the working directory if it dosen't exist
	workingDir := projectRoot + "/.terrarium/" + trId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		err := os.MkdirAll(workingDir, 0755)
		if err != nil {
			err2 := fmt.Errorf("failed to create a working directory")
			log.Error().Err(err).Msg(err2.Error())
			res := model.Response{Success: false, Message: err2.Error()}
			return c.JSON(http.StatusInternalServerError, res)
		}
	}

	err := terrarium.IssueTerrarium(*reqTrInfo)

	if err != nil {
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	trInfo, err := terrarium.ReadTerrariumInfo(trId)
	if err != nil {
		text := fmt.Sprintf("no terrarium with the given ID (trId: %s)", trId)
		res := model.Response{Success: true, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	return c.JSON(http.StatusOK, trInfo)
}

// ReadAllTerrarium godoc
// @Summary Read all terrarium
// @Description Read all terrarium
// @Tags [Terrarium] An environment to enrich the multi-cloud infrastructure
// @Accept  json
// @Produce  json
// @Success 200 {array} model.TerrariumInfo "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr [get]
func ReadAllTerrarium(c echo.Context) error {

	trInfoList, _ := terrarium.ReadAllTerrariumInfo()

	return c.JSON(http.StatusOK, trInfoList)
}

// ReadTerrarium godoc
// @Summary Read a terrarium
// @Description Read a terrarium
// @Tags [Terrarium] An environment to enrich the multi-cloud infrastructure
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Success 200 {object} model.TerrariumInfo "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId} [get]
func ReadTerrarium(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		res := model.Response{Success: false, Message: "require the terrarium ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	trInfo, err := terrarium.ReadTerrariumInfo(trId)
	if err != nil {
		text := fmt.Sprintf("no terrarium with the given ID (trId: %s)", trId)
		res := model.Response{Success: true, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	return c.JSON(http.StatusOK, trInfo)
}

// EraseTerrarium godoc
// @Summary Erase the entire terrarium including directories and configuration files
// @Description Erase the entire terrarium including directories and configuration files
// @Tags [Terrarium] An environment to enrich the multi-cloud infrastructure
// @Accept  json
// @Produce  json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId} [delete]
func EraseTerrarium(c echo.Context) error {

	trId := c.Param("trId")
	if trId == "" {
		res := model.Response{Success: false, Message: "require the terrarium ID"}
		return c.JSON(http.StatusBadRequest, res)
	}

	projectRoot := config.Terrarium.Root

	// Check if the working directory exists
	workingDir := projectRoot + "/.terrarium/" + trId
	if _, err := os.Stat(workingDir); os.IsNotExist(err) {
		text := fmt.Sprintf("not exist terrarium (id: %v)", trId)
		res := model.Response{Success: false, Message: text}
		return c.JSON(http.StatusBadRequest, res)
	}

	err := os.RemoveAll(workingDir)
	if err != nil {
		res := model.Response{Success: false, Message: "failed to erase the entire terrarium"}
		return c.JSON(http.StatusInternalServerError, res)
	}

	err = terrarium.DeleteTerrariumInfo(trId)
	if err != nil {
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	text := fmt.Sprintf("successfully erased the entire terrarium (trId: %v)", trId)
	res := model.Response{Success: true, Message: text}
	log.Debug().Msgf("%+v", res) // debug

	return c.JSON(http.StatusOK, res)
}
