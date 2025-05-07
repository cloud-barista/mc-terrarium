package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"

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
	providers := []string{"aws", req.VpnConfig.TargetCsp.Type}

	// Check if the terrarium is already used for another purpose
	trInfo, _, err := terrarium.GetInfo(trId)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}
	if trInfo.Enrichments != "" && trInfo.Enrichments != enrichments {
		err := fmt.Errorf("the terrarium (trId: %s) is already used for another purpose", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Set the terrarium information
	trInfo.Enrichments = enrichments
	trInfo.Providers = providers

	// Update the terrarium info
	err = terrarium.UpdateInfo(trInfo)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}

	// Create the terrarium environment
	err = terrarium.CreateEnv(trInfo)
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
		log.Info().Msg("recover imports.tf and refresh state for the next destroy request")

		// Recover the imports.tf
		recoverErr := terrarium.RecoverImportTf(trId)
		if recoverErr != nil {
			log.Error().Err(recoverErr).Msg("Failed to recover imports.tf")
		} else {
			log.Info().Msg("Successfully recovered imports.tf")
		}

		// Refresh the state
		_, refreshErr := terrarium.Refresh(trId, reqId)
		if refreshErr != nil {
			log.Error().Err(refreshErr).Msg("Failed to refresh state after error")
		} else {
			log.Info().Msg("Successfully refreshed state after error")
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

		/*
		 * NOTE: Set the output object (e.g., "testbed_info") to get the refined resource info
		 */

		trInfo, exists, err := terrarium.GetInfo(trId)
		if err != nil {
			log.Error().Err(err).Msg(err.Error())
			return emptyRes, err
		}
		if !exists {
			err2 := fmt.Errorf("no terrarium with the given ID (trId: %s)", trId)
			log.Warn().Msg(err2.Error())
			return emptyRes, err2
		}

		// In-parallel, retrieve and merge the resource info
		providers := trInfo.Providers
		if len(providers) == 0 {
			err2 := fmt.Errorf("no providers in the terrarium (trId: %s)", trId)
			log.Warn().Msg(err2.Error())
			return emptyRes, err2
		}
		// function-scoped struct for secure or robust error handling in goroutines
		type resultWithError struct {
			provider     string
			resourceInfo string
			err          error
		}
		results := make(chan resultWithError, len(providers)) // buffered channel to prevent goroutine leaks

		var wg sync.WaitGroup
		for _, provider := range providers {
			wg.Add(1)
			provider := provider // ! Important: This prevents closure capture
			go func() {
				defer wg.Done()
				// Retrieve provider's resource info
				targetObject := fmt.Sprintf("%s_vpn_info", provider)
				resourceInfo, err := terrarium.Output(trId, reqId, targetObject, "-json")
				if err != nil {
					results <- resultWithError{
						provider: provider,
						err:      fmt.Errorf("failed to get output for provider '%s': %w", provider, err),
					}
					return
				}

				results <- resultWithError{
					provider:     provider,
					resourceInfo: resourceInfo,
					err:          nil,
				}
			}()
		}

		wg.Wait()
		close(results)

		// Merge th results
		var allResourceInfo = make(map[string]any)

		log.Debug().Msgf("trId: %s", trId)
		allResourceInfo["terrarium_id"] = trId

		for res := range results {
			if res.err != nil {
				log.Error().Err(res.err).Msg("") // error
				continue                         // or handle the error as needed
			}

			var resourceInfo map[string]any
			err = json.Unmarshal([]byte(res.resourceInfo), &resourceInfo)
			if err != nil {
				log.Error().Err(err).Msg("") // error
				return emptyRes, err
			}

			// Merge resourceInfo directly into allResourceInfo
			mergeResourceInfo(allResourceInfo, resourceInfo)
		}

		// Optional: return error if any individual result has error
		// for _, res := range collected {
		// 	if res.err != nil {
		// 		return collected, res.err // or accumulate all errors if needed
		// 	}
		// }

		res := model.Response{
			Success: true,
			Message: "refined read resource info (map)",
			Object:  allResourceInfo,
		}

		// Pretty print the JSON for better readability in logs
		prettyRes, err := json.MarshalIndent(res, "", "  ")
		if err != nil {
			log.Error().Err(err).Msg("Failed to marshal pretty JSON")
		}
		log.Debug().Msgf("\n%+v", string(prettyRes)) // debug

		return res, nil

	case DetailOptions.Raw:

		// Execute the show command
		ret, err := terrarium.Show(trId, reqId, "-json")
		if err != nil {
			err2 := fmt.Errorf("failed to show the infrastructure terrarium")
			log.Error().Err(err).Msg(err2.Error())
			return emptyRes, err2
		}

		var allResources []interface{}
		// Parse the resource info in root module
		resourceInRootModule := gjson.Get(ret, "values.root_module.resources").String()
		if resourceInRootModule == "" {
			err2 := fmt.Errorf("could not find resource info (trId: %s)", trId)
			log.Warn().Msg(err2.Error())
			return emptyRes, err2
		}

		err = json.Unmarshal([]byte(resourceInRootModule), &allResources)
		if err != nil {
			err2 := fmt.Errorf("failed to unmarshal resource info")
			log.Error().Err(err).Msg(err2.Error()) // error
			return emptyRes, err2
		}

		// Parse the resource info in child modules
		resourcesInChildModules := gjson.Get(ret, "values.root_module.child_modules.#.resources").Array()
		if len(resourcesInChildModules) == 0 {
			err2 := fmt.Errorf("could not find resource info (trId: %s)", trId)
			log.Warn().Msg(err2.Error())
		}

		for _, resourcesInChildModule := range resourcesInChildModules {
			if resourcesInChildModule.String() == "" {
				err2 := fmt.Errorf("could not find resource info (trId: %s)", trId)
				log.Warn().Msg(err2.Error())
				return emptyRes, err2
			}

			var temp []interface{}
			err = json.Unmarshal([]byte(resourcesInChildModule.String()), &temp)
			if err != nil {
				err2 := fmt.Errorf("failed to unmarshal resource info")
				log.Error().Err(err).Msg(err2.Error()) // error
				return emptyRes, err2
			}

			allResources = append(allResources, temp...)
		}

		res := model.Response{
			Success: true,
			Message: "raw resource info (list)",
			List:    allResources,
		}

		// Pretty print the JSON for better readability in logs
		prettyRes, err := json.MarshalIndent(res, "", "  ")
		if err != nil {
			log.Error().Err(err).Msg("Failed to marshal pretty JSON")
		}
		log.Debug().Msgf("\n%+v", string(prettyRes)) // debug

		return res, nil

	default:
		err := fmt.Errorf("invalid detail option (%s)", detail)
		log.Warn().Err(err).Msg("") // warn

		return emptyRes, err
	}
}

// mergeResourceInfo recursively merges the new resource information into the existing map
// It modifies the existing map directly
func mergeResourceInfo(existing, new map[string]any) {
	// Handle nil cases
	if existing == nil || new == nil {
		return
	}

	for k, v := range new {
		// Check if the key exists in the existing map
		valueInExisting, ok := existing[k]
		if !ok {
			existing[k] = v
			continue
		}

		// If both values are maps, recursively merge them
		if existingMap, ok1 := valueInExisting.(map[string]any); ok1 {
			if newMap, ok2 := v.(map[string]any); ok2 {
				mergeResourceInfo(existingMap, newMap)
				continue
			}
		}

		// If both values are slices, append them
		if existingSlice, ok1 := valueInExisting.([]any); ok1 {
			if newSlice, ok2 := v.([]any); ok2 {
				existing[k] = append(existingSlice, newSlice...)
				continue
			}
		}

		// For incompatible types or primitives, prefer the new value
		existing[k] = v
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
		err := fmt.Errorf("the terrarium (trId: %s) is used for the other purpose (%s)", trId, existingEnrichments)
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
