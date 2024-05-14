package route

import (
	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /mc-net/test-env/...
func RegisterRoutesForTestEnv(g *echo.Group) {
	g.POST("/test-env/init", handlers.InitTerrariumForTestEnv)
	g.DELETE("/test-env/clear", handlers.ClearTestEnv)
	g.GET("/test-env", handlers.GetResouceInfoOfTestEnv)
	g.POST("/test-env/infracode", handlers.CreateInfracodeOfTestEnv)
	g.POST("/test-env/plan", handlers.CheckInfracodeOfTestEnv)
	g.POST("/test-env", handlers.CreateTestEnv)
	g.DELETE("/test-env", handlers.DestroyTestEnv)
	g.GET("/test-env/request/:requestId/status", handlers.GetRequestStatusOfTestEnv)
}
