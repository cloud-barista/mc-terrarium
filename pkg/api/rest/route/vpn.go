package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/labstack/echo/v4"
)

// /terrarium/rg/:rgId/vpn/...
func RegisterRoutesForVPN(g *echo.Group) {
	// GCP and AWS
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/terrarium", handler.InitTerrariumForGcpAwsVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-aws/clear", handler.ClearGcpAwsVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-aws", handler.GetResourceInfoOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/infracode", handler.CreateInfracodeOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws/plan", handler.CheckInfracodeOfGcpAwsVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-aws", handler.CreateGcpAwsVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-aws", handler.DestroyGcpAwsVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-aws/request/:requestId", handler.GetRequestStatusOfGcpAwsVpn)

	// GCP and Azure
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure/terrarium", handler.InitTerrariumForGcpAzureVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-azure/clear", handler.ClearGcpAzureVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-azure/resource/info", handler.GetResourceInfoOfGcpAzureVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure/infracode", handler.CreateInfracodeOfGcpAzureVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure/plan", handler.CheckInfracodeOfGcpAzureVpn)
	g.POST("/rg/:resourceGroupId/vpn/gcp-azure", handler.CreateGcpAzureVpn)
	g.DELETE("/rg/:resourceGroupId/vpn/gcp-azure", handler.DestroyGcpAzureVpn)
	g.GET("/rg/:resourceGroupId/vpn/gcp-azure/request/:requestId", handler.GetRequestStatusOfGcpAzureVpn)
}
