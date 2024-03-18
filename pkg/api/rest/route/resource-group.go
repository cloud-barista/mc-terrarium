package route

import (
	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /mc-net/rg/:rgId/...
func RegisterRoutesForRG(g *echo.Group) {
	g.DELETE("/rg/:resourceGroupId", handlers.ClearResourceGroup)

}
