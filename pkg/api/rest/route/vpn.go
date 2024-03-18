package route

import (
	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /mc-net/rg/:rgId/vpn/...
func RegisterRoutesForVPN(g *echo.Group) {
	// GCP and AWS
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/init", handlers.InitGcpAndAwsForVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-aws/clear", handlers.ClearGcpAwsVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-aws/state", handlers.GetStateOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/blueprint", handlers.CreateBluprintOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/plan", handlers.CheckBluprintOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws", handlers.CreateGcpAwsVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-aws", handlers.DestroyGcpAwsVpn)

	// GCP and Azure
}
