package route

import (
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handlers"
	"github.com/labstack/echo/v4"
)

// /terrarium/sample/*
func RegisterSampleRoutes(g *echo.Group) {
	g.GET("/users", handlers.GetUsers)
	g.GET("/users/:id", handlers.GetUser)
	g.POST("/users", handlers.CreateUser)
	g.PUT("/users/:id", handlers.UpdateUser)
	g.DELETE("/users/:id", handlers.DeleteUser)
}
