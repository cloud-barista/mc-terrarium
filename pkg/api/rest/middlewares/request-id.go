package middlewares

import (
	"fmt"
	"time"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/model"
	"github.com/labstack/echo/v4"
)

func RequestIdAndDetailsIssuer(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		// log.Debug().Msg("Start - Request ID middleware")

		// Make x-request-id visible to all handlers
		c.Response().Header().Set("Access-Control-Expose-Headers", model.HeaderXRequestId)

		// Get or generate Request ID
		reqID := c.Request().Header.Get(model.HeaderXRequestId)
		if reqID == "" {
			reqID = fmt.Sprintf("%d", time.Now().UnixNano())
			c.Request().Header.Set(model.HeaderXRequestId, reqID)
		}

		// //log.Trace().Msgf("(Request ID middleware) Request ID: %s", reqID)
		// if _, ok := common.RequestMap.Load(reqID); ok {
		// 	return fmt.Errorf("the x-request-id is already in use")
		// }

		// Set "x-request-id" in response header
		c.Response().Header().Set(model.HeaderXRequestId, reqID)

		// details := common.RequestDetails{
		// 	StartTime:   time.Now(),
		// 	Status:      "Handling",
		// 	RequestInfo: common.ExtractRequestInfo(c.Request()),
		// }
		// common.RequestMap.Store(reqID, details)

		// log.Debug().Msg("End - Request ID middleware")

		return next(c)
	}
}
