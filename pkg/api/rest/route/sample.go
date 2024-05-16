package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/labstack/echo/v4"
)

// /terrarium/sample/*
func RegisterSampleRoutes(g *echo.Group) {
	g.GET("/users", handler.GetUsers)
	g.GET("/users/:id", handler.GetUser)
	g.POST("/users", handler.CreateUser)
	g.PUT("/users/:id", handler.UpdateUser)
	g.DELETE("/users/:id", handler.DeleteUser)
}
