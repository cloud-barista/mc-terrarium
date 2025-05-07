package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
)

/*
/ [API - AWS to Site VPN] Resource Operations
*/

// CreateAwsToSiteVpn godoc
// @Summary Create AWS to site VPN
// @Description Create AWS to site VPN
// @Tags [AWS to site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ReqBody body model.CreateAwsToSiteVpnRequest true "Parameters requied to create the AWS to site VPN"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site [post]
func CreateAwsToSiteVpn(c echo.Context) error {

	// Handler workflow by sequenctially running the following operation:
	// 1. Initialize
	// 2. Plan
	// 3. Apply

	res, err := initAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = planAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = applyAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

// GetAwsToSiteVpn godoc
// @Summary Get AWS to site VPN
// @Description Get AWS to site VPN
// @Tags [AWS to site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" Enums(refined, raw) default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site [get]
func GetAwsToSiteVpn(c echo.Context) error {

	// Handler workflow by sequenctially running the following operation:
	// 1. Get

	res, err := outputAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

// DeleteAwsToSiteVpn godoc
// @Summary Delete AWS to site VPN
// @Description Delete AWS to site VPN
// @Tags [AWS to site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site [delete]
func DeleteAwsToSiteVpn(c echo.Context) error {

	// Handler workflow by sequenctially running the following operation:
	// 1. Destroy

	res, err := destroyAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	// res, err = emptyOutAwsToSiteVpn(c)
	// if err != nil {
	// 	log.Error().Err(err).Msg(err.Error())
	// 	return c.JSON(http.StatusInternalServerError, res)
	// }

	return c.JSON(http.StatusOK, res)
}
