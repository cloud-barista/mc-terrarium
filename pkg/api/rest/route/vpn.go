package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/labstack/echo/v4"
)

// /terrarium/tr/:trId/vpn/...
func RegisterRoutesForVPN(g *echo.Group) {
	// GCP and AWS
	g.POST("/tr/:trId/vpn/gcp-aws/env", handler.InitEnvForGcpAwsVpn)
	g.DELETE("/tr/:trId/vpn/gcp-aws/clear", handler.ClearGcpAwsVpn)
	g.GET("/tr/:trId/vpn/gcp-aws", handler.GetResourceInfoOfGcpAwsVpn)
	g.POST("/tr/:trId/vpn/gcp-aws/infracode", handler.CreateInfracodeOfGcpAwsVpn)
	g.POST("/tr/:trId/vpn/gcp-aws/plan", handler.CheckInfracodeOfGcpAwsVpn)
	g.POST("/tr/:trId/vpn/gcp-aws", handler.CreateGcpAwsVpn)
	g.DELETE("/tr/:trId/vpn/gcp-aws", handler.DestroyGcpAwsVpn)
	g.GET("/tr/:trId/vpn/gcp-aws/request/:requestId", handler.GetRequestStatusOfGcpAwsVpn)

	// GCP and Azure
	g.POST("/tr/:trId/vpn/gcp-azure/env", handler.InitEnvForGcpAzureVpn)
	g.DELETE("/tr/:trId/vpn/gcp-azure/clear", handler.ClearGcpAzureVpn)
	g.GET("/tr/:trId/vpn/gcp-azure", handler.GetResourceInfoOfGcpAzureVpn)
	g.POST("/tr/:trId/vpn/gcp-azure/infracode", handler.CreateInfracodeOfGcpAzureVpn)
	g.POST("/tr/:trId/vpn/gcp-azure/plan", handler.CheckInfracodeOfGcpAzureVpn)
	g.POST("/tr/:trId/vpn/gcp-azure", handler.CreateGcpAzureVpn)
	g.DELETE("/tr/:trId/vpn/gcp-azure", handler.DestroyGcpAzureVpn)
	g.GET("/tr/:trId/vpn/gcp-azure/request/:requestId", handler.GetRequestStatusOfGcpAzureVpn)
}
