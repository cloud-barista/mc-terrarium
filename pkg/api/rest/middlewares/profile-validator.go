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

// Package middlewares is to handle REST API middlewares
package middlewares

import (
	"net/http"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/cloud-barista/mc-terrarium/pkg/terrarium"
	"github.com/labstack/echo/v4"
	"github.com/rs/zerolog/log"
)

const HeaderXCredentialHolder = "X-Credential-Holder"

// CredentialProfileValidator is a middleware to validate the credential profile (holder)
func CredentialProfileValidator(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		trId := c.Param("trId")
		if trId == "" {
			return next(c)
		}

		providedProfile := c.Request().Header.Get(HeaderXCredentialHolder)
		// TODO: Remove this later for more secure credential profile management
		if providedProfile == "" {
			providedProfile = "admin"
		}

		if err := terrarium.ValidateCredentialProfile(trId, providedProfile); err != nil {
			log.Warn().Err(err).Msg("failed to validate credential profile (holder)")
			res := model.Response{Success: false, Message: err.Error()}
			return c.JSON(http.StatusForbidden, res)
		}

		return next(c)
	}
}
