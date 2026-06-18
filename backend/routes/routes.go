package routes

import (
    "time"
    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/config"
    "github.com/WonahGodwino/emr-issue-logger/backend/controllers"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/middleware"
)

func SetupRouter(cfg *config.Config, db *database.CouchbaseDB) *gin.Engine {
    router := gin.Default()

    router.Use(cors.New(cors.Config{
        AllowOrigins:     cfg.CORSAllowedOrigins,
        AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
        MaxAge:           12 * time.Hour,
    }))

    router.GET("/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })

    authController := controllers.NewAuthController(db, cfg)
    ticketController := controllers.NewTicketController(db)

    api := router.Group("/api/v1")
    {
        auth := api.Group("/auth")
        {
            auth.POST("/register", authController.Register)
            auth.POST("/login", authController.Login)
            auth.POST("/refresh", authController.RefreshToken)
        }

        protected := api.Group("")
        protected.Use(middleware.AuthMiddleware(cfg))
        {
            userController := controllers.NewUserController(db)
            protected.GET("/users/me", userController.GetCurrentUser)
            protected.PUT("/users/me", userController.UpdateProfile)

            tickets := protected.Group("/tickets")
            {
                tickets.POST("", ticketController.CreateTicket)
                tickets.GET("", ticketController.GetTickets)
                tickets.GET("/:id", ticketController.GetTicket)
                tickets.PUT("/:id", ticketController.UpdateTicket)
                tickets.POST("/:id/status", ticketController.UpdateTicketStatus)
                tickets.POST("/:id/screenshots", ticketController.UploadScreenshot)
                tickets.DELETE("/:id", ticketController.DeleteTicket)
                tickets.POST("/:id/recall", ticketController.RecallTicket)
            }

            admin := protected.Group("/admin")
            admin.Use(middleware.AdminMiddleware())
            {
                adminController := controllers.NewAdminController(db)
                admin.GET("/dashboard", adminController.GetDashboardStats)
                admin.GET("/users", adminController.GetAllUsers)
                admin.PUT("/users/:userId/states", adminController.AssignStatesToAdmin)
                admin.GET("/tickets", adminController.GetAllTickets)
                admin.PUT("/tickets/:id/assign", adminController.AssignTicket)

                // States & Facilities (SUPER_ADMIN only)
                superAdmin := admin.Group("/states")
                superAdmin.Use(middleware.SuperAdminMiddleware())
                {
                    sfc := controllers.NewStateFacilityController(db)
                    superAdmin.POST("", sfc.CreateState)
                    superAdmin.GET("", sfc.GetStates)
                    superAdmin.GET("/facilities/template", sfc.DownloadCSVTemplate)
                    superAdmin.PUT("/:stateId", sfc.UpdateState)
                    superAdmin.DELETE("/:stateId", sfc.DeleteState)

                    facilities := superAdmin.Group("/:stateId/facilities")
                    {
                        facilities.POST("", sfc.CreateFacility)
                        facilities.GET("", sfc.GetFacilities)
                        facilities.POST("/upload", sfc.BulkUploadFacilities)
                        facilities.POST("/upload-csv", sfc.BulkUploadCSV)
                        facilities.PUT("/:facilityId", sfc.UpdateFacility)
                        facilities.DELETE("/:facilityId", sfc.DeleteFacility)
                    }
                }
            }
        }
    }

    return router
}