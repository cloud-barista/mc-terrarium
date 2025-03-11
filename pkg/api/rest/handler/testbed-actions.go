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
 * [API - Multi-Cloud Testbed] OpenTofu Actions (for fine-grained contorl)
 */

// InitTestbed godoc
// @Summary Init testbed
// @Description Init testbed
// @Tags [Testbed] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed/actions/init [post]
func InitTestbed(c echo.Context) error {

	res, err := initTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func initTestbed(c echo.Context) (model.Response, error) {

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

	/*
	* [Process] Prepare and execute the init command
	*/

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Set the enrichments
	enrichments := "testbed"

	err := terrarium.SetEnrichments(trId, enrichments)
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

	/*
	 * NOTE: Set CSPs' credentials for the terrarium environment
	 */
	err = terrarium.SetCredentials(trId, enrichments, "gcp")
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	err = terrarium.SetCredentials(trId, enrichments, "azure")
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Set the anonymous struct for terrarium_id tfvars
	var anon = &struct {
    TerrariumId string `json:"terrarium_id"`
	}{TerrariumId: trId}

	// Set the tfvars
	err = terrarium.SaveTfVars(trId, enrichments, anon)
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

// PlanTestbed godoc
// @Summary Plan the testbed
// @Description Plan the testbed
// @Tags [Testbed] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed/actions/plan [post]
func PlanTestbed(c echo.Context) error {
	
	ret, err := planTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}
		
	return c.JSON(http.StatusOK, ret)
}

func planTestbed(c echo.Context) (model.Response, error) {

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

// ApplyTestbed godoc
// @Summary Apply the testbed
// @Description Apply the testbed
// @Tags [Testbed] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed/actions/apply [post]
func ApplyTestbed(c echo.Context) error {
	
	res, err := applyTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func applyTestbed(c echo.Context) (model.Response, error) {

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

// DestroyTestbed godoc
// @Summary Destroy the testbed
// @Description Destroy the testbed
// @Tags [Testbed] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed/actions/destroy [delete]
func DestroyTestbed(c echo.Context) error {

	res, err := destroyTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func destroyTestbed(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}
	
	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Execute the destroy command
	ret, err := terrarium.Destroy(trId, reqId)
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

// OutputTestbed godoc
// @Summary Output the testbed
// @Description Output the testbed
// @Tags [Testbed] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" Enums(refined, raw) default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed/actions/output [get]
func OutputTestbed(c echo.Context) error {

	res, err := outputTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}
		
	return c.JSON(http.StatusOK, res)
}

func outputTestbed(c echo.Context) (model.Response, error) {

	
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
		
		/*
		 * NOTE: Set the output object (e.g., "testbed_info") to get the refined resource info
	 	 */
		ret, err := terrarium.Output(trId, reqId, "testbed_info", "-json") 
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

// EmptyOutTestbed godoc
// @Summary EmptyOut the testbed
// @Description EmptyOut the testbed
// @Tags [Testbed] OpenTofu Actions (for fine-grained contorl)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/testbed/actions/emptyout [delete]
func EmptyOutTestbed(c echo.Context) error {

	res, err := emptyOutTestbed(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}	

	return c.JSON(http.StatusOK, res)
}

func emptyOutTestbed(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Execute the emptyout command
	err := terrarium.EmptyOutTerrariumEnv(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to empty out the infrastructure terrarium")
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
