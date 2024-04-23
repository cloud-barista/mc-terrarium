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
	g.GET("/rg/:resourceGroupId/vpn/gcp-aws/resource/info", handlers.GetAllResourceInfoOfGcpAwsVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-aws/resource/id", handlers.GetAllResourceIdOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/blueprint", handlers.CreateBlueprintOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/plan", handlers.CheckBlueprintOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws", handlers.CreateGcpAwsVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-aws", handlers.DestroyGcpAwsVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-aws/request/:requestId/status", handlers.GetRequestStatusOfGcpAwsVpn)

	// GCP and Azure
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure/init", handlers.InitGcpAndAzureForVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-azure/clear", handlers.ClearGcpAzureVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-azure/resource/info", handlers.GetAllResourceInfoOfGcpAzureVpn)
	g.GET("rg/:resourceGroupId/vpn/gcp-azure/resource/id", handlers.GetAllResourceIdOfGcpAzureVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure/blueprint", handlers.CreateBlueprintOfGcpAzureVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure/plan", handlers.CheckBlueprintOfGcpAzureVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure", handlers.CreateGcpAzureVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-azure", handlers.DestroyGcpAzureVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-azure/request/:requestId/status", handlers.GetRequestStatusOfGcpAzureVpn)
}
