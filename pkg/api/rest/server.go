/*
Copyright 2019 The Cloud-Barista Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Package server is to handle REST API
package server

import (
	"context"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"crypto/subtle"
	"fmt"
	"os"

	"net/http"

	// Black import (_) is for running a package's init() function without using its other contents.
	"github.com/cloud-barista/mc-terrarium/pkg/config"
	"github.com/cloud-barista/mc-terrarium/pkg/readyz"
	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"

	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/handler"
	"github.com/cloud-barista/mc-terrarium/pkg/api/rest/middlewares"

	// REST API (echo)
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"

	// echo-swagger middleware
	_ "github.com/cloud-barista/mc-terrarium/api"
	echoSwagger "github.com/swaggo/echo-swagger"
)

//var masterConfigInfos confighandler.MASTERCONFIGTYPE

const (
	infoColor    = "\033[1;34m%s\033[0m"
	noticeColor  = "\033[1;36m%s\033[0m"
	warningColor = "\033[1;33m%s\033[0m"
	errorColor   = "\033[1;31m%s\033[0m"
	debugColor   = "\033[0;36m%s\033[0m"
)

const (
	website = " https://github.com/cloud-barista/mc-terrarium"
	banner  = `    
 ________________________________________________
 

 ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗
 ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
 ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ 
 ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  
 ██║  ██║███████╗██║  ██║██████╔╝   ██║   
 ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   
 
████████╗███████╗██████╗ ██████╗  █████╗ ██████╗ ██╗██╗   ██╗███╗   ███╗
╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██║   ██║████╗ ████║
   ██║   █████╗  ██████╔╝██████╔╝███████║██████╔╝██║██║   ██║██╔████╔██║
   ██║   ██╔══╝  ██╔══██╗██╔══██╗██╔══██║██╔══██╗██║██║   ██║██║╚██╔╝██║
   ██║   ███████╗██║  ██║██║  ██║██║  ██║██║  ██║██║╚██████╔╝██║ ╚═╝ ██║
   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝
 
 
 Mutli-cloud Infrastructure Enrichment Technology
 ________________________________________________`
)

// RunServer func start Rest API server
func RunServer(port string) {

	log.Info().Msg("Setting mc-terrarium REST API server")

	e := echo.New()

	// Middleware
	// e.Use(middleware.Logger()) // default logger middleware in echo

	APILogSkipPatterns := [][]string{
		{"/terrarium/api"},
		// {"/mcis", "option=status"},
	}

	// Custom logger middleware with zerolog
	e.Use(middlewares.Zerologger(APILogSkipPatterns))

	// Recover middleware recovers from panics anywhere in the chain, and handles the control to the centralized HTTP error handler.
	e.Use(middleware.Recover())

	// limit the application to 20 requests/sec using the default in-memory store
	e.Use(middleware.RateLimiter(middleware.NewRateLimiterMemoryStore(20)))

	// Custom middleware to issue request ID and details
	e.Use(middlewares.RequestIdAndDetailsIssuer)

	// Custom middleware for tracing
	e.Use(middlewares.TracingMiddleware)

	e.HideBanner = true
	//e.colorer.Printf(banner, e.colorer.Red("v"+Version), e.colorer.Blue(website))

	allowedOrigins := config.Terrarium.API.Allow.Origins
	if allowedOrigins == "" {
		log.Fatal().Msg("allow_ORIGINS env variable for CORS is " + allowedOrigins +
			". Please provide a proper value and source setup.env again. EXITING...")
	}

	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{allowedOrigins},
		AllowMethods: []string{http.MethodGet, http.MethodPut, http.MethodPost, http.MethodDelete},
	}))

	// Conditions to prevent abnormal operation due to typos (e.g., ture, falss, etc.)
	enableAuth := config.Terrarium.API.Auth.Enabled

	apiUser := config.Terrarium.API.Username
	apiPass := config.Terrarium.API.Password

	if enableAuth {
		e.Use(middleware.BasicAuthWithConfig(middleware.BasicAuthConfig{
			// Skip authentication for some routes that do not require authentication
			Skipper: func(c echo.Context) bool {
				if c.Path() == "/terrarium/readyz" ||
					c.Path() == "/terrarium/httpVersion" {
					return true
				}
				return false
			},
			Validator: func(username, password string, c echo.Context) (bool, error) {
				// Be careful to use constant time comparison to prevent timing attacks
				if subtle.ConstantTimeCompare([]byte(username), []byte(apiUser)) == 1 {
					// bcrypt verification
					err := bcrypt.CompareHashAndPassword([]byte(apiPass), []byte(password))
					if err == nil {
						return true, nil
					}
				}
				return false, nil
			},
		}))
	}

	fmt.Print("\n ")
	fmt.Print(banner)
	fmt.Print("\n\n")
	fmt.Println(" Website/repository: ")
	fmt.Printf(infoColor, website)
	fmt.Print("\n\n")

	// Route for system management
	swaggerRedirect := func(c echo.Context) error {
		return c.Redirect(http.StatusMovedPermanently, "/terrarium/api/index.html")
	}
	e.GET("/terrarium/api", swaggerRedirect)
	e.GET("/terrarium/api/", swaggerRedirect)
	e.GET("/terrarium/api/*", echoSwagger.WrapHandler)
	// e.GET("/terrarium/swagger/*", echoSwagger.WrapHandler)
	// e.GET("/terrarium/swaggerActive", rest_common.RestGetSwagger)

	e.GET("/terrarium/readyz", handler.Readyz)
	e.GET("/terrarium/httpVersion", handler.HTTPVersion)
	e.GET("/terrarium/tofuVersion", handler.TofuVersion)

	// A terrarium group has /terrarium as prefix
	gTr := e.Group("/terrarium")

	// Terrarium APIs
	gTr.POST("/tr", handler.IssueTerrarium)
	gTr.GET("/tr", handler.ReadAllTerrarium)
	gTr.GET("/tr/:trId", handler.ReadTerrarium)
	gTr.DELETE("/tr/:trId", handler.EraseTerrarium)

	// [Testbed] Resource operations (high-level APIs for resource-centric operations)
	gTr.POST("/tr/:trId/testbed", handler.CreateTestbed)
	gTr.GET("/tr/:trId/testbed", handler.GetTestbed)
	// gTr.UPDATE("/tr/:trId/testbed", handler.UpdateTestbed)
	gTr.DELETE("/tr/:trId/testbed", handler.DeleteTestbed)

	// [Testbed] Tofu Actions (low-level APIs for advanced control)
	gTr.POST("/tr/:trId/testbed/actions/init", handler.InitTestbed)
	gTr.POST("/tr/:trId/testbed/actions/plan", handler.PlanTestbed)
	gTr.POST("/tr/:trId/testbed/actions/apply", handler.ApplyTestbed)
	gTr.DELETE("/tr/:trId/testbed/actions/destroy", handler.DestroyTestbed)
	gTr.GET("/tr/:trId/testbed/actions/output", handler.OutputTestbed)
	gTr.DELETE("/tr/:trId/testbed/actions/emptyout", handler.EmptyOutTestbed)

	// [AWS-to-site VPN] Resource operations (high-level APIs for resource-centric operations)
	gTr.POST("/tr/:trId/vpn/aws-to-site", handler.CreateAwsToSiteVpn)
	gTr.GET("/tr/:trId/vpn/aws-to-site", handler.GetAwsToSiteVpn)
	// gTr.UPDATE("/tr/:trId/vpn/aws-to-site", handler.UpdateAwsToSiteVpn)
	gTr.DELETE("/tr/:trId/vpn/aws-to-site", handler.DeleteAwsToSiteVpn)

	// [AWS-to-site VPN] Tofu Actions (low-level APIs for advanced control)
	gTr.POST("/tr/:trId/vpn/aws-to-site/actions/init", handler.InitAwsToSiteVpn)
	gTr.POST("/tr/:trId/vpn/aws-to-site/actions/plan", handler.PlanAwsToSiteVpn)
	gTr.POST("/tr/:trId/vpn/aws-to-site/actions/apply", handler.ApplyAwsToSiteVpn)
	gTr.DELETE("/tr/:trId/vpn/aws-to-site/actions/destroy", handler.DestroyAwsToSiteVpn)
	gTr.GET("/tr/:trId/vpn/aws-to-site/actions/output", handler.OutputAwsToSiteVpn)
	gTr.DELETE("/tr/:trId/vpn/aws-to-site/actions/emptyout", handler.EmptyOutAwsToSiteVpn)

	// [Site-to-Site VPN] Resource operations (high-level APIs for resource-centric operations)
	gTr.POST("/tr/:trId/vpn/site-to-site", handler.CreateSiteToSiteVpn)
	gTr.GET("/tr/:trId/vpn/site-to-site", handler.GetSiteToSiteVpn)
	// gTr.PUT("/tr/:trId/vpn/site-to-site", handler.UpdateSiteToSiteVpn)
	gTr.DELETE("/tr/:trId/vpn/site-to-site", handler.DeleteSiteToSiteVpn)

	// [Site-to-Site VPN] Tofu Actions (low-level APIs for advanced control)
	gTr.POST("/tr/:trId/vpn/site-to-site/actions/init", handler.InitSiteToSiteVpn)
	gTr.POST("/tr/:trId/vpn/site-to-site/actions/plan", handler.PlanSiteToSiteVpn)
	gTr.POST("/tr/:trId/vpn/site-to-site/actions/apply", handler.ApplySiteToSiteVpn)
	gTr.DELETE("/tr/:trId/vpn/site-to-site/actions/destroy", handler.DestroySiteToSiteVpn)
	gTr.GET("/tr/:trId/vpn/site-to-site/actions/output", handler.OutputSiteToSiteVpn)
	gTr.DELETE("/tr/:trId/vpn/site-to-site/actions/emptyout", handler.EmptyOutSiteToSiteVpn)

	// VPN APIs
	// GCP and AWS
	gTr.POST("/tr/:trId/vpn/gcp-aws/env", handler.InitEnvForGcpAwsVpn)
	gTr.DELETE("/tr/:trId/vpn/gcp-aws/env", handler.ClearGcpAwsVpn)
	gTr.GET("/tr/:trId/vpn/gcp-aws", handler.GetResourceInfoOfGcpAwsVpn)
	gTr.POST("/tr/:trId/vpn/gcp-aws/infracode", handler.CreateInfracodeOfGcpAwsVpn)
	gTr.POST("/tr/:trId/vpn/gcp-aws/plan", handler.CheckInfracodeOfGcpAwsVpn)
	gTr.POST("/tr/:trId/vpn/gcp-aws", handler.CreateGcpAwsVpn)
	gTr.DELETE("/tr/:trId/vpn/gcp-aws", handler.DestroyGcpAwsVpn)
	gTr.GET("/tr/:trId/vpn/gcp-aws/request/:requestId", handler.GetRequestStatusOfGcpAwsVpn)

	// GCP and Azure
	gTr.POST("/tr/:trId/vpn/gcp-azure/env", handler.InitEnvForGcpAzureVpn)
	gTr.DELETE("/tr/:trId/vpn/gcp-azure/env", handler.ClearGcpAzureVpn)
	gTr.GET("/tr/:trId/vpn/gcp-azure", handler.GetResourceInfoOfGcpAzureVpn)
	gTr.POST("/tr/:trId/vpn/gcp-azure/infracode", handler.CreateInfracodeOfGcpAzureVpn)
	gTr.POST("/tr/:trId/vpn/gcp-azure/plan", handler.CheckInfracodeOfGcpAzureVpn)
	gTr.POST("/tr/:trId/vpn/gcp-azure", handler.CreateGcpAzureVpn)
	gTr.DELETE("/tr/:trId/vpn/gcp-azure", handler.DestroyGcpAzureVpn)
	gTr.GET("/tr/:trId/vpn/gcp-azure/request/:requestId", handler.GetRequestStatusOfGcpAzureVpn)

	// SQL database APIs
	gTr.POST("/tr/:trId/sql-db/env", handler.InitEnvForSqlDb)
	gTr.DELETE("/tr/:trId/sql-db/env", handler.ClearEnvOfSqlDb)
	gTr.POST("/tr/:trId/sql-db/infracode", handler.CreateInfracodeForSqlDb)
	gTr.POST("/tr/:trId/sql-db/plan", handler.CheckInfracodeForSqlDb)
	gTr.POST("/tr/:trId/sql-db", handler.CreateSqlDb)
	gTr.GET("/tr/:trId/sql-db", handler.GetResourceInfoOfSqlDb)
	gTr.DELETE("/tr/:trId/sql-db", handler.DestroySqlDb)
	gTr.GET("/tr/:trId/sql-db/request/:requestId", handler.GetRequestStatusOfSqlDb)

	// Object Storage APIs
	gTr.POST("/tr/:trId/object-storage/env", handler.InitEnvForObjectStorage)
	gTr.DELETE("/tr/:trId/object-storage/env", handler.ClearEnvOfObjectStorage)
	gTr.POST("/tr/:trId/object-storage/infracode", handler.CreateInfracodeForObjectStorage)
	gTr.POST("/tr/:trId/object-storage/plan", handler.CheckInfracodeForObjectStorage)
	gTr.POST("/tr/:trId/object-storage", handler.CreateObjectStorage)
	gTr.GET("/tr/:trId/object-storage", handler.GetResourceInfoOfObjectStorage)
	gTr.DELETE("/tr/:trId/object-storage", handler.DestroyObjectStorage)
	gTr.GET("/tr/:trId/object-storage/request/:requestId", handler.GetRequestStatusOfObjectStorage)

	// Message Broker APIs
	gTr.POST("/tr/:trId/message-broker/env", handler.InitEnvForMessageBroker)
	gTr.DELETE("/tr/:trId/message-broker/env", handler.ClearEnvOfMessageBroker)
	gTr.POST("/tr/:trId/message-broker/infracode", handler.CreateInfracodeForMessageBroker)
	gTr.POST("/tr/:trId/message-broker/plan", handler.CheckInfracodeForMessageBroker)
	gTr.POST("/tr/:trId/message-broker", handler.CreateMessageBroker)
	gTr.GET("/tr/:trId/message-broker", handler.GetResourceInfoOfMessageBroker)
	gTr.DELETE("/tr/:trId/message-broker", handler.DestroyMessageBroker)
	gTr.GET("/tr/:trId/message-broker/request/:requestId", handler.GetRequestStatusOfMessageBroker)

	selfEndpoint := config.Terrarium.Self.Endpoint
	apidashboard := " http://" + selfEndpoint + "/terrarium/api"

	// if enableAuth {
	// 	fmt.Println(" Access to API dashboard" + " (username: " + apiUser + " / password: " + apiPass + "): ")
	// }
	fmt.Printf(noticeColor, apidashboard)
	fmt.Println("\n ")

	// A context for graceful shutdown (It is based on the signal package)selfEndpoint := os.Getenv("SELF_ENDPOINT")
	// NOTE -
	// Use os.Interrupt Ctrl+C or Ctrl+Break on Windows
	// Use syscall.KILL for Kill(can't be caught or ignored) (POSIX)
	// Use syscall.SIGTERM for Termination (ANSI)
	// Use syscall.SIGINT for Terminal interrupt (ANSI)
	// Use syscall.SIGQUIT for Terminal quit (POSIX)
	gracefulShutdownContext, stop := signal.NotifyContext(context.TODO(),
		os.Interrupt, syscall.SIGKILL, syscall.SIGTERM, syscall.SIGINT, syscall.SIGQUIT)
	defer stop()

	// Wait graceful shutdown (and then main thread will be finished)
	var wg sync.WaitGroup

	wg.Add(1)
	go func(wg *sync.WaitGroup) {
		defer wg.Done()

		// Block until a signal is triggered
		<-gracefulShutdownContext.Done()

		fmt.Println("\n[Stop] mc-terrarium REST API server")
		log.Info().Msg("stopping mc-terrarium REST API server")
		ctx, cancel := context.WithTimeout(context.TODO(), 3*time.Second)
		defer cancel()

		if err := e.Shutdown(ctx); err != nil {
			e.Logger.Panic(err)
		}
	}(&wg)

	log.Info().Msg("starting mc-terrarium REST API server")
	port = fmt.Sprintf(":%s", port)
	readyz.SetReady(true)
	if err := e.Start(port); err != nil && err != http.ErrServerClosed {
		e.Logger.Panic("shuttig down the server")
	}

	wg.Wait()
}
