package route

import (
	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /mc-net/tofu/*
func RegisterTofuRoutes(g *echo.Group) {
	g.GET("/version", handlers.TofuVersion)
	g.POST("/init", handlers.TofuInit)
	g.DELETE("/cleanup/:namespaceId", handlers.TofuCleanup)
	g.GET("/show/:namespaceId", handlers.TofuShow)
	g.POST("/config/vpn-tunnels", handlers.TofuConfigVPNTunnels)
	g.POST("/plan/vpn-tunnels/:namespaceId", handlers.TofuPlanVPNTunnels)
	g.POST("/apply/vpn-tunnels/:namespaceId", handlers.TofuApplyVPNTunnels)
	g.DELETE("/destroy/vpn-tunnels/:namespaceId", handlers.TofuDestroyVPNTunnels)
}
