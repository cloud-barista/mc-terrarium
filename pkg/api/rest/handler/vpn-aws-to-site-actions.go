package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/terrarium"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/tidwall/gjson"
)

/*
 * [API - AWS to Site VPN] OpenTofu Actions (for fine-grained contorl)
 */

// InitAwsToSiteVpn godoc
// @Summary Init AWS to site VPN
// @Description Init AWS to site VPN
// @Tags [AWS to site VPN] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ReqBody body model.CreateAwsToSiteVpnRequest true "Parameters requied to create the AWS to site VPN"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site/actions/init [post]
func InitAwsToSiteVpn(c echo.Context) error {

	res, err := initAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func initAwsToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	/*
	 * [Input] Get and validate
	 */
	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	req := new(model.CreateAwsToSiteVpnRequest)
	if err := c.Bind(req); err != nil {
		err2 := fmt.Errorf("invalid request format, %v", err)
		log.Warn().Err(err).Msg("invalid request format")
		return emptyRes, err2
	}
	log.Debug().Msgf("%#v", req) // debug

	if req.VpnConfig.TerrariumId == "" {
		req.VpnConfig.TerrariumId = trId
	}

	// Validate the request
	if err := req.VpnConfig.Validate(); err != nil {
		log.Warn().Err(err).Msg("invalid request data")
		return emptyRes, err
	}

	/*
	* [Process] Prepare and execute the init command
	 */

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Set the enrichments
	enrichments := "vpn/aws-to-site"

	// Check if the terrarium is already used for another purpose
	existingEnrichments, exist, err := terrarium.GetEnrichments(trId)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Check if the terrarium is already used for another purpose
	if exist && existingEnrichments != enrichments {
		err := fmt.Errorf("the terrarium (trId: %s) is already used for another purpose", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Set the enrichments
	err = terrarium.SetEnrichments(trId, enrichments)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Set the terrarium environment
	err = terrarium.CreateTerrariumEnv(trId, enrichments)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Set credentials for the terrarium environment
	err = terrarium.SetCredentials(trId, enrichments, "gcp")
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Set the tfvars
	err = terrarium.SaveTfVars(trId, enrichments, req)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Execute the init command
	ret, err := terrarium.Init(trId, reqId)
	if err != nil {
		err2 := fmt.Errorf("failed to initialize an infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	/*
	* [Output] Return the result
	 */

	res := model.Response{
		Success: true,
		Message: "successfully initialized the infrastructure terrarium",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

// PlanAwsToSiteVpn godoc
// @Summary Plan AWS to site VPN
// @Description Plan AWS to site VPN
// @Tags [AWS to site VPN] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site/actions/plan [post]
func PlanAwsToSiteVpn(c echo.Context) error {

	ret, err := planAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, ret)
}

func planAwsToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Execute the plan command
	ret, err := terrarium.Plan(trId, reqId)
	if err != nil {
		err2 := fmt.Errorf("failed to plan the infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	res := model.Response{
		Success: true,
		Message: "successfully planned the infrastructure terrarium",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

// ApplyAwsToSiteVpn godoc
// @Summary Apply AWS to site VPN
// @Description Apply AWS to site VPN
// @Tags [AWS to site VPN] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site/actions/apply [post]
func ApplyAwsToSiteVpn(c echo.Context) error {

	res, err := applyAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func applyAwsToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Execute the apply command
	ret, err := terrarium.Apply(trId, reqId)
	if err != nil {
		err2 := fmt.Errorf("failed to apply the infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	res := model.Response{
		Success: true,
		Message: "successfully applied the infrastructure terrarium",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

// DestroyAwsToSiteVpn godoc
// @Summary Destroy AWS to site VPN
// @Description Destroy AWS to site VPN
// @Tags [AWS to site VPN] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site/actions/destroy [delete]
func DestroyAwsToSiteVpn(c echo.Context) error {

	res, err := destroyAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func destroyAwsToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Define err variable to track errors
	var err error

	// Add a deferred function to refresh state if an error occurs
	defer func() {
		if err != nil {
			log.Info().Msg("Attempting to refresh state after error...")
			_, refreshErr := terrarium.Refresh(trId, reqId)
			if refreshErr != nil {
				log.Error().Err(refreshErr).Msg("Failed to refresh state after error")
			} else {
				log.Info().Msg("Successfully refreshed state after error")
			}
		}
	}()

	// Detach the imported route table for preventing to destroy the imported resource
	err = terrarium.DetachImportedResource(trId, reqId, "aws_route_table.imported_route_table")
	if err != nil {
		err2 := fmt.Errorf("failed to remove the imported route table")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	// Execute the destroy command
	var ret string
	ret, err = terrarium.Destroy(trId, reqId)
	if err != nil {
		err2 := fmt.Errorf("failed to destroy the infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	res := model.Response{
		Success: true,
		Message: "successfully destroyed the infrastructure terrarium",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

// OutputAwsToSiteVpn godoc
// @Summary Output AWS to site VPN
// @Description Output AWS to site VPN
// @Tags [AWS to site VPN] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" Enums(refined, raw) default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site/actions/output [get]
func OutputAwsToSiteVpn(c echo.Context) error {

	res, err := outputAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

func outputAwsToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

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

	// Get the resource info by the detail option
	switch detail {
	case DetailOptions.Refined:
		// Execute the output command
		ret, err := terrarium.Output(trId, reqId, "vpn_info", "-json")
		if err != nil {
			err2 := fmt.Errorf("failed to output the infrastructure terrarium")
			return emptyRes, err2
		}

		var resourceInfo map[string]interface{}
		err = json.Unmarshal([]byte(ret), &resourceInfo)
		if err != nil {
			log.Error().Err(err).Msg("") // error
			return emptyRes, err
		}

		res := model.Response{
			Success: true,
			Message: "refined read resource info (map)",
			Object:  resourceInfo,
		}
		log.Debug().Msgf("%+v", res) // debug

		return res, nil

	case DetailOptions.Raw:

		// Execute the show command
		ret, err := terrarium.Show(trId, reqId, "-json")
		if err != nil {
			err2 := fmt.Errorf("failed to show the infrastructure terrarium")
			log.Error().Err(err).Msg(err2.Error())
			return emptyRes, err2
		}

		// Parse the resource info
		resourcesString := gjson.Get(ret, "values.root_module.resources").String()
		if resourcesString == "" {
			err2 := fmt.Errorf("could not find resource info (trId: %s)", trId)
			log.Warn().Msg(err2.Error())
			return emptyRes, err2
		}

		var resourceInfoList []interface{}
		err = json.Unmarshal([]byte(resourcesString), &resourceInfoList)
		if err != nil {
			err2 := fmt.Errorf("failed to unmarshal resource info")
			log.Error().Err(err).Msg(err2.Error()) // error
			return emptyRes, err2
		}

		res := model.Response{
			Success: true,
			Message: "raw resource info (list)",
			List:    resourceInfoList,
		}
		log.Debug().Msgf("%+v", res) // debug

		return res, nil

	default:
		err := fmt.Errorf("invalid detail option (%s)", detail)
		log.Warn().Err(err).Msg("") // warn

		return emptyRes, err
	}
}

// EmptyOutAwsToSiteVpn godoc
// @Summary EmptyOut AWS to site VPN
// @Description EmptyOut AWS to site VPN
// @Tags [AWS to site VPN] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/aws-to-site/actions/emptyout [delete]
func EmptyOutAwsToSiteVpn(c echo.Context) error {

	res, err := emptyOutAwsToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

func emptyOutAwsToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	enrichments := "vpn/aws-to-site"

	existingEnrichments, exist, err := terrarium.GetEnrichments(trId)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	if !exist || existingEnrichments != enrichments {
		err := fmt.Errorf("the terrarium (trId: %s) is not used for the testbed", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Execute the emptyout command
	err = terrarium.EmptyOutTerrariumEnv(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to empty out the infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err2
	}

	// Unset the enrichments
	err = terrarium.SetEnrichments(trId, "")
	if err != nil {
		err2 := fmt.Errorf("failed to unset the enrichments")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err2
	}

	res := model.Response{
		Success: true,
		Message: "successfully emptied out the infrastructure terrarium",
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}
