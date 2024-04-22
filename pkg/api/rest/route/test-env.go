package route

import (
	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /mc-net/test-env/...
func RegisterRoutesForTestEnv(g *echo.Group) {
	g.POST("/test-env/init", handlers.InitTestEnv)
	g.DELETE("/test-env/clear", handlers.ClearTestEnv)
	g.GET("/test-env/state", handlers.GetStateOfTestEnv)
	g.POST("/test-env/blueprint", handlers.CreateBlueprintOfTestEnv)
	g.POST("/test-env/plan", handlers.CheckBlueprintOfTestEnv)
	g.POST("/test-env", handlers.CreateTestEnv)
	g.DELETE("/test-env", handlers.DestroyTestEnv)
	g.GET("/test-env/request/:requestId/status", handlers.GetRequestStatusOfTestEnv)
}
