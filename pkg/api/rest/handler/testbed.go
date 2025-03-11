package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
)

/*
/ [API - Multi-Cloud Testbed] Resource Operations
*/

// CreateTestbed godoc
// @Summary Create the testbed
// @Description Create the testbed
// @Tags [Testbed] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed [post]
func CreateTestbed(c echo.Context) error {

	// Handler workflow by sequenctially running the following operation:
	// 1. Initialize
	// 2. Plan
	// 3. Apply

	res, err := initTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = planTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}
	
	res, err = applyTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

// GetTestbed godoc
// @Summary Get the testbed
// @Description Get the testbed
// @Tags [Testbed] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" Enums(refined, raw) default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed [get]
func GetTestbed(c echo.Context) error {
	
	// Handler workflow by sequenctially running the following operation:
	// 1. Get

	res, err := outputTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

// DeleteTestbed godoc
// @Summary Delete the testbed
// @Description Delete the testbed
// @Tags [Testbed] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed [delete]
func DeleteTestbed(c echo.Context) error {
	
	// Handler workflow by sequenctially running the following operation:
	// 1. Destroy

	res, err := destroyTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	// res, err = cleanTestbed(c)
	// if err != nil {
	// 	log.Error().Err(err).Msg(err.Error())
	// 	return c.JSON(http.StatusInternalServerError, res)
	// }

	return c.JSON(http.StatusOK, res)
}
