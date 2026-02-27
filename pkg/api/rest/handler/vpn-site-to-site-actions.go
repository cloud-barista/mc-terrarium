package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"sync"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/cloud-barista/mc-terrarium/pkg/terrarium"
	tfutil "github.com/cloud-barista/mc-terrarium/pkg/tofu/util"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
	"github.com/tidwall/gjson"
)

/*
 * [API - Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
 */

// InitSiteToSiteVpn godoc
// @Summary Init Site-to-Site VPN
// @Description Init Site-to-Site VPN
// @Tags [Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param ReqBody body model.CreateSiteToSiteVpnRequest true "Parameters required to create the Site-to-Site VPN"
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site/actions/init [post]
func InitSiteToSiteVpn(c echo.Context) error {

	res, err := initSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		res := model.Response{Success: false, Message: err.Error()}
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func initSiteToSiteVpn(c echo.Context) (model.Response, error) {

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

	req := new(model.CreateSiteToSiteVpnRequest)
	if err := c.Bind(req); err != nil {
		err2 := fmt.Errorf("invalid request format: %w", err)
		log.Warn().Msg(err2.Error())
		return emptyRes, err2
	}
	log.Debug().Msgf("%#v", req) // debug

	if req.VpnConfig.TerrariumId == "" {
		req.VpnConfig.TerrariumId = trId
	}

	// Validate the request
	if err := req.VpnConfig.Validate(); err != nil {
		err2 := fmt.Errorf("invalid VPN configuration: %w", err)
		log.Warn().Msg(err2.Error())
		return emptyRes, err2
	}

	// Get providers from the request
	providers := getProvidersFromRequest(req)

	// Validate that we have at least 2 providers
	if len(providers) != 2 {
		err := fmt.Errorf("site-to-site VPN requires 2 CSPs, got %d", len(providers))
		log.Error().Msg(err.Error())
		return emptyRes, err
	}

	/*
	 * [Process] Prepare and execute the init command
	 */

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	// Set the enrichments
	enrichments := "vpn/site-to-site"

	// Sort providers in alphabetical order
	sort.Strings(providers)

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

	// On the env, the infracode for VPN connection between provider pair should be appended additionally.
	providerPair := fmt.Sprintf("%s-%s", providers[0], providers[1])
	projectRoot := config.Terrarium.Root
	providerTfsDir := projectRoot + "/templates/" + enrichments + "/conn-" + providerPair
	workingDir := projectRoot + "/.terrarium/" + trId + "/" + enrichments
	err = tfutil.CopyFiles(providerTfsDir, workingDir)
	if err != nil {
		err2 := fmt.Errorf("could not find any provider pair (%s) specific template files to terrarium environment", providerPair)
		log.Warn().Err(err).Msg(err2.Error())
	}

	// Set the tfvars
	// Transform the request to match Terraform variables structure
	tfVars := map[string]interface{}{
		"vpn_config": req.VpnConfig,
	}

	err = terrarium.SaveTfVars(trId, enrichments, tfVars)
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
		Message: "successfully initialized the infrastructure terrarium for Site-to-Site VPN",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

func getProvidersFromRequest(req *model.CreateSiteToSiteVpnRequest) []string {
	// Get providers from the request

	providers := []string{}

	if req.VpnConfig.Aws != nil {
		providers = append(providers, "aws")
	}
	if req.VpnConfig.Azure != nil {
		providers = append(providers, "azure")
	}
	if req.VpnConfig.Gcp != nil {
		providers = append(providers, "gcp")
	}
	if req.VpnConfig.Alibaba != nil {
		providers = append(providers, "alibaba")
	}
	if req.VpnConfig.Tencent != nil {
		providers = append(providers, "tencent")
	}
	if req.VpnConfig.Ibm != nil {
		providers = append(providers, "ibm")
	}

	return providers
}

// PlanSiteToSiteVpn godoc
// @Summary Plan Site-to-Site VPN
// @Description Plan Site-to-Site VPN
// @Tags [Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site/actions/plan [post]
func PlanSiteToSiteVpn(c echo.Context) error {

	ret, err := planSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
	}

	return c.JSON(http.StatusOK, ret)
}

func planSiteToSiteVpn(c echo.Context) (model.Response, error) {

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
		Message: "successfully planned the infrastructure terrarium for Site-to-Site VPN",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

// ApplySiteToSiteVpn godoc
// @Summary Apply Site-to-Site VPN
// @Description Apply Site-to-Site VPN
// @Tags [Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 201 {object} model.Response "Created"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site/actions/apply [post]
func ApplySiteToSiteVpn(c echo.Context) error {

	res, err := applySiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func applySiteToSiteVpn(c echo.Context) (model.Response, error) {

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
		Message: "successfully applied the infrastructure terrarium for Site-to-Site VPN",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

// DestroySiteToSiteVpn godoc
// @Summary Destroy Site-to-Site VPN
// @Description Destroy Site-to-Site VPN
// @Tags [Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site/actions/destroy [delete]
func DestroySiteToSiteVpn(c echo.Context) error {

	res, err := destroySiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusCreated, res)
}

func destroySiteToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	trInfo, exists, err := terrarium.GetInfo(trId)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return emptyRes, err
	}
	if !exists {
		err := fmt.Errorf("terrarium (trId: %s) does not exist", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Get the request ID
	reqId := c.Response().Header().Get(echo.HeaderXRequestID)

	if Contains(trInfo.Providers, "aws") {
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
		Message: "successfully destroyed the infrastructure terrarium for Site-to-Site VPN",
		Detail:  ret,
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}

func Contains(slice []string, item string) bool {
	for _, v := range slice {
		if v == item {
			return true
		}
	}
	return false
}

// OutputSiteToSiteVpn godoc
// @Summary Output Site-to-Site VPN
// @Description Output Site-to-Site VPN
// @Tags [Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param detail query string false "Resource info by detail (refined, raw)" Enums(refined, raw) default(refined)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site/actions/output [get]
func OutputSiteToSiteVpn(c echo.Context) error {

	res, err := outputSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

func outputSiteToSiteVpn(c echo.Context) (model.Response, error) {

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
		 * NOTE: Set the output object (e.g., "vpn_info") to get the refined resource info
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

		// Merge the results
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
				continue
			}

			var temp []interface{}
			err = json.Unmarshal([]byte(resourcesInChildModule.String()), &temp)
			if err != nil {
				log.Error().Err(err).Msg("failed to unmarshal child module resources")
				continue
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

// EmptyOutSiteToSiteVpn godoc
// @Summary EmptyOut Site-to-Site VPN
// @Description EmptyOut Site-to-Site VPN
// @Tags [Site-to-Site VPN] OpenTofu Actions (for fine-grained control)
// @Accept json
// @Produce json
// @Param trId path string true "Terrarium ID" default(tr01)
// @Param x-request-id header string false "Custom request ID"
// @Success 200 {object} model.Response "OK"
// @Failure 400 {object} model.Response "Bad Request"
// @Failure 500 {object} model.Response "Internal Server Error"
// @Failure 503 {object} model.Response "Service Unavailable"
// @Router /tr/{trId}/vpn/site-to-site/actions/emptyout [delete]
func EmptyOutSiteToSiteVpn(c echo.Context) error {

	res, err := emptyOutSiteToSiteVpn(c)
	if err != nil {
		log.Error().Err(err).Msg(err.Error())
		return c.JSON(http.StatusInternalServerError, res)
	}

	return c.JSON(http.StatusOK, res)
}

func emptyOutSiteToSiteVpn(c echo.Context) (model.Response, error) {

	emptyRes := model.Response{}

	trId := c.Param("trId")
	if trId == "" {
		err := fmt.Errorf("invalid request, terrarium ID (trId: %s) is required", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	enrichments := "vpn/site-to-site"

	existingEnrichments, exist, err := terrarium.GetEnrichments(trId)
	if err != nil {
		log.Error().Err(err).Msg("failed to get enrichments")
		return emptyRes, err
	}

	if !exist || existingEnrichments != enrichments {
		err := fmt.Errorf("terrarium (trId: %s) is not configured for Site-to-Site VPN", trId)
		log.Warn().Msg(err.Error())
		return emptyRes, err
	}

	// Execute the emptyout command
	err = terrarium.EmptyOutTerrariumEnv(trId)
	if err != nil {
		err2 := fmt.Errorf("failed to empty out the infrastructure terrarium")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	// Unset the enrichments
	err = terrarium.SetEnrichments(trId, "")
	if err != nil {
		err2 := fmt.Errorf("failed to unset the terrarium enrichments")
		log.Error().Err(err).Msg(err2.Error())
		return emptyRes, err
	}

	res := model.Response{
		Success: true,
		Message: "successfully emptied out the infrastructure terrarium for Site-to-Site VPN",
	}

	log.Debug().Msgf("%+v", res) // debug

	return res, nil
}
