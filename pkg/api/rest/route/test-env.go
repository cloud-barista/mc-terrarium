package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/labstack/echo/v4"
)

// /terrarium/test-env/...
func RegisterRoutesForTestEnv(g *echo.Group) {
	g.POST("/test-env/init", handler.InitTerrariumForTestEnv)
	g.DELETE("/test-env/env", handler.ClearTestEnv)
	g.GET("/test-env", handler.GetResouceInfoOfTestEnv)
	g.POST("/test-env/infracode", handler.CreateInfracodeOfTestEnv)
	g.POST("/test-env/plan", handler.CheckInfracodeOfTestEnv)
	g.POST("/test-env", handler.CreateTestEnv)
	g.DELETE("/test-env", handler.DestroyTestEnv)
	g.GET("/test-env/request/:requestId/status", handler.GetRequestStatusOfTestEnv)
}
