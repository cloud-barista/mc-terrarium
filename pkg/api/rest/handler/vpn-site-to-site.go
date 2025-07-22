package handler

import (
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
)

/*
/ [API - Site-to-Site VPN] Resource Operations
*/

// CreateSiteToSiteVpn godoc
// @Summary Create Site-to-Site VPN
// @Description Create Site-to-Site VPN between two cloud sites
// @Tags [Site-to-Site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ReqBody body model.CreateSiteToSiteVpnRequest true "Parameters required to create the Site-to-Site VPN"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site [post]
func CreateSiteToSiteVpn(c echo.Context) error {

	// Handler workflow by sequentially running the following operation:
	// 1. Initialize
	// 2. Plan
	// 3. Apply

	res, err := initSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = planSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = applySiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

// GetSiteToSiteVpn godoc
// @Summary Get Site-to-Site VPN
// @Description Get Site-to-Site VPN information
// @Tags [Site-to-Site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" Enums(refined, raw) default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site [get]
func GetSiteToSiteVpn(c echo.Context) error {

	// Handler workflow by sequentially running the following operation:
	// 1. Get

	res, err := outputSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

// UpdateSiteToSiteVpn godoc
// @Summary Update Site-to-Site VPN
// @Description Update Site-to-Site VPN configuration
// @Tags [Site-to-Site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ReqBody body model.CreateSiteToSiteVpnRequest true "Parameters required to update the Site-to-Site VPN"
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site [put]
func UpdateSiteToSiteVpn(c echo.Context) error {

	// Handler workflow by sequentially running the following operation:
	// 1. Plan (with updated configuration)
	// 2. Apply

	res, err := planSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = applySiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

// DeleteSiteToSiteVpn godoc
// @Summary Delete Site-to-Site VPN
// @Description Delete Site-to-Site VPN
// @Tags [Site-to-Site VPN] Resource Operations
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site [delete]
func DeleteSiteToSiteVpn(c echo.Context) error {

	// Handler workflow by sequentially running the following operation:
	// 1. Destroy
	// 2. EmptyOut

	res, err := destroySiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	res, err = emptyOutSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}
