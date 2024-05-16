package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/labstack/echo/v4"
)

// /terrarium/rg/:rgId/...
func RegisterRoutesForRG(g *echo.Group) {
	g.DELETE("/rg/:resourceGroupId", handler.ClearResourceGroup)

}
