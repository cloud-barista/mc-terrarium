package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/labstack/echo/v4"
)

// /terrarium/tr/:trId/...
func RegisterRoutesForRG(g *echo.Group) {
	g.POST("/tr", handler.IssueTerrarium)
	g.GET("/tr", handler.ReadAllTerrarium)
	g.GET("/tr/:trId", handler.ReadTerrarium)
	g.DELETE("/tr/:trId", handler.EraseTerrarium)
}
