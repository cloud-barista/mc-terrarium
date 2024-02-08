package route

import (
	"github.com/cloud-barista/poc-mc-net-tf/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /mc-net/tofu/*
func RegisterTofuRoutes(g *echo.Group) {
	g.GET("/version", handlers.TofuVersion)
	g.GET("/show", handlers.TofuShow)
}
