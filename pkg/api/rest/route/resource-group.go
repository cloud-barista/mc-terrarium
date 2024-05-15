package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /terrarium/rg/:rgId/...
func RegisterRoutesForRG(g *echo.Group) {
	g.DELETE("/rg/:resourceGroupId", handlers.ClearResourceGroup)

}
