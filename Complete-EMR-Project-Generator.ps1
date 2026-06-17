# Complete-EMR-Project-Generator.ps1
# Run this from: C:\ECEWS_emr_issue_log

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EMR ISSUE LOGGER - COMPLETE PROJECT" -ForegroundColor Cyan
Write-Host "  Generating ALL files (Backend + Frontend)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = "C:\ECEWS_emr_issue_log"
$backendPath = "$rootPath\backend"
$frontendPath = "$rootPath\frontend"

# ============================================
# CREATE BACKEND DIRECTORY STRUCTURE
# ============================================
Write-Host "📁 Creating Backend directories..." -ForegroundColor Yellow

$backendDirs = @(
    "$backendPath\cmd\server",
    "$backendPath\config",
    "$backendPath\routes",
    "$backendPath\controllers",
    "$backendPath\services",
    "$backendPath\repositories",
    "$backendPath\models",
    "$backendPath\dto",
    "$backendPath\middleware",
    "$backendPath\validators",
    "$backendPath\helpers",
    "$backendPath\database",
    "$backendPath\constants",
    "$backendPath\interfaces",
    "$backendPath\events",
    "$backendPath\websocket",
    "$backendPath\tests\unit",
    "$backendPath\tests\integration",
    "$backendPath\tests\mocks",
    "$backendPath\docs"
)

foreach ($dir in $backendDirs) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}
Write-Host "✅ Backend directories created" -ForegroundColor Green

# ============================================
# CREATE FRONTEND DIRECTORY STRUCTURE
# ============================================
Write-Host "📁 Creating Frontend directories..." -ForegroundColor Yellow

$frontendDirs = @(
    "$frontendPath\src\app\core\guards",
    "$frontendPath\src\app\core\interceptors",
    "$frontendPath\src\app\core\services",
    "$frontendPath\src\app\core\models",
    "$frontendPath\src\app\shared\components\navbar",
    "$frontendPath\src\app\shared\components\sidebar",
    "$frontendPath\src\app\shared\components\footer",
    "$frontendPath\src\app\shared\components\loader",
    "$frontendPath\src\app\shared\components\status-badge",
    "$frontendPath\src\app\shared\components\pagination",
    "$frontendPath\src\app\shared\components\search",
    "$frontendPath\src\app\shared\components\confirmation-dialog",
    "$frontendPath\src\app\shared\components\ticket-card",
    "$frontendPath\src\app\shared\components\statistics-card",
    "$frontendPath\src\app\shared\components\toast",
    "$frontendPath\src\app\shared\directives",
    "$frontendPath\src\app\shared\pipes",
    "$frontendPath\src\app\pages\login",
    "$frontendPath\src\app\pages\register",
    "$frontendPath\src\app\pages\dashboard",
    "$frontendPath\src\app\pages\profile",
    "$frontendPath\src\app\pages\create-ticket",
    "$frontendPath\src\app\pages\my-tickets",
    "$frontendPath\src\app\pages\ticket-details",
    "$frontendPath\src\app\pages\edit-ticket",
    "$frontendPath\src\app\pages\admin-dashboard",
    "$frontendPath\src\app\pages\manage-users",
    "$frontendPath\src\app\pages\manage-tickets",
    "$frontendPath\src\app\pages\not-found",
    "$frontendPath\src\app\pages\unauthorized",
    "$frontendPath\src\environments",
    "$frontendPath\src\assets\images",
    "$frontendPath\src\assets\fonts"
)

foreach ($dir in $frontendDirs) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}
Write-Host "✅ Frontend directories created" -ForegroundColor Green

# ============================================
# BACKEND FILES
# ============================================

# ============================================
# 1. BACKEND - go.mod
# ============================================
Write-Host "📄 Creating backend files..." -ForegroundColor Yellow

$goMod = @"
module github.com/yourusername/emr-issue-logger/backend

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/golang-jwt/jwt/v5 v5.0.0
    github.com/google/uuid v1.3.0
    github.com/joho/godotenv v1.5.1
    go.mongodb.org/mongo-driver v1.12.1
    golang.org/x/crypto v0.14.0
    github.com/gin-contrib/cors v1.4.0
)
"@
$goMod | Out-File -FilePath "$backendPath\go.mod" -Encoding UTF8

# ============================================
# 2. BACKEND - .env
# ============================================
$envFile = @"
PORT=8080
MONGODB_URI=mongodb://localhost:27017
MONGODB_DATABASE=emr_issue_logger
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
BCRYPT_COST=12
CORS_ALLOWED_ORIGINS=http://localhost:4200
ENVIRONMENT=development
"@
$envFile | Out-File -FilePath "$backendPath\.env" -Encoding UTF8

# ============================================
# 3. BACKEND - main.go
# ============================================
$mainGo = @"
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/yourusername/emr-issue-logger/backend/config"
    "github.com/yourusername/emr-issue-logger/backend/database"
    "github.com/yourusername/emr-issue-logger/backend/routes"
)

func main() {
    cfg := config.LoadConfig()
    db := database.NewMongoDB(cfg)
    defer db.Close()

    if err := db.CreateIndexes(context.Background()); err != nil {
        log.Fatalf("Failed to create indexes: %v", err)
    }

    if err := db.Seed(context.Background()); err != nil {
        log.Printf("Warning: Failed to seed data: %v", err)
    }

    router := routes.SetupRouter(cfg, db)

    srv := &http.Server{
        Addr:           ":" + cfg.Port,
        Handler:        router,
        ReadTimeout:    10 * time.Second,
        WriteTimeout:   10 * time.Second,
        MaxHeaderBytes: 1 << 20,
    }

    go func() {
        log.Printf("Server starting on port %s", cfg.Port)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }
    log.Println("Server exited properly")
}
"@
$mainGo | Out-File -FilePath "$backendPath\cmd\server\main.go" -Encoding UTF8

# ============================================
# 4. BACKEND - config.go
# ============================================
$configGo = @"
package config

import (
    "log"
    "os"
    "strconv"
    "time"
    "github.com/joho/godotenv"
)

type Config struct {
    Port               string
    MongoDBURI         string
    MongoDBDatabase    string
    JWTSecret          string
    JWTAccessExpiry    time.Duration
    JWTRefreshExpiry   time.Duration
    BcryptCost         int
    CORSAllowedOrigins []string
    Environment        string
}

func LoadConfig() *Config {
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found, using environment variables")
    }

    accessExpiry, _ := time.ParseDuration(getEnv("JWT_ACCESS_EXPIRY", "15m"))
    refreshExpiry, _ := time.ParseDuration(getEnv("JWT_REFRESH_EXPIRY", "7d"))
    bcryptCost, _ := strconv.Atoi(getEnv("BCRYPT_COST", "12"))

    return &Config{
        Port:               getEnv("PORT", "8080"),
        MongoDBURI:         getEnv("MONGODB_URI", "mongodb://localhost:27017"),
        MongoDBDatabase:    getEnv("MONGODB_DATABASE", "emr_issue_logger"),
        JWTSecret:          getEnv("JWT_SECRET", "default-secret-change-me"),
        JWTAccessExpiry:    accessExpiry,
        JWTRefreshExpiry:   refreshExpiry,
        BcryptCost:         bcryptCost,
        CORSAllowedOrigins: []string{getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:4200")},
        Environment:        getEnv("ENVIRONMENT", "development"),
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
"@
$configGo | Out-File -FilePath "$backendPath\config\config.go" -Encoding UTF8

# ============================================
# 5. BACKEND - models/user.go
# ============================================
$userModel = @"
package models

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type UserRole string

const (
    RoleAdmin UserRole = "admin"
    RoleUser  UserRole = "user"
)

type User struct {
    ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    UserID    string             `bson:"user_id" json:"userId"`
    Username  string             `bson:"username" json:"username"`
    Email     string             `bson:"email" json:"email"`
    Password  string             `bson:"password" json:"-"`
    FullName  string             `bson:"full_name" json:"fullName"`
    Role      UserRole           `bson:"role" json:"role"`
    CreatedAt time.Time          `bson:"created_at" json:"createdAt"`
    UpdatedAt time.Time          `bson:"updated_at" json:"updatedAt"`
    IsActive  bool               `bson:"is_active" json:"isActive"`
}

type UserResponse struct {
    ID        string    `json:"id"`
    UserID    string    `json:"userId"`
    Username  string    `json:"username"`
    Email     string    `json:"email"`
    FullName  string    `json:"fullName"`
    Role      UserRole  `json:"role"`
    CreatedAt time.Time `json:"createdAt"`
}

func (u *User) ToResponse() UserResponse {
    return UserResponse{
        ID:        u.ID.Hex(),
        UserID:    u.UserID,
        Username:  u.Username,
        Email:     u.Email,
        FullName:  u.FullName,
        Role:      u.Role,
        CreatedAt: u.CreatedAt,
    }
}
"@
$userModel | Out-File -FilePath "$backendPath\models\user.go" -Encoding UTF8

# ============================================
# 6. BACKEND - models/ticket.go
# ============================================
$ticketModel = @"
package models

import (
    "time"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

type TicketStatus string

const (
    StatusPending    TicketStatus = "pending"
    StatusInProgress TicketStatus = "in-progress"
    StatusResolved   TicketStatus = "resolved"
)

type TicketCategory string

const (
    CategorySystemIssue   TicketCategory = "system-issue"
    CategoryDataIntegrity TicketCategory = "data-integrity"
    CategoryPerformance   TicketCategory = "performance"
    CategoryUIUX          TicketCategory = "ui-ux"
    CategoryIntegration   TicketCategory = "integration"
    CategoryOther         TicketCategory = "other"
)

type StatusHistory struct {
    Status    TicketStatus `bson:"status" json:"status"`
    Timestamp time.Time    `bson:"timestamp" json:"timestamp"`
    UpdatedBy string       `bson:"updated_by" json:"updatedBy"`
    Note      string       `bson:"note,omitempty" json:"note,omitempty"`
}

type Ticket struct {
    ID                  primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    TicketID            string             `bson:"ticket_id" json:"ticketId"`
    Title               string             `bson:"title" json:"title"`
    Description         string             `bson:"description" json:"description"`
    ReporterUserID      string             `bson:"reporter_user_id" json:"reporterUserId"`
    Category            TicketCategory     `bson:"category" json:"category"`
    OrderOfImpact       int                `bson:"order_of_impact" json:"orderOfImpact"`
    IsNewRequirement    bool               `bson:"is_new_requirement" json:"isNewRequirement"`
    Status              TicketStatus       `bson:"status" json:"status"`
    StatusHistory       []StatusHistory    `bson:"status_history" json:"statusHistory"`
    AssignedTo          string             `bson:"assigned_to,omitempty" json:"assignedTo,omitempty"`
    ResolutionNotes     string             `bson:"resolution_notes,omitempty" json:"resolutionNotes,omitempty"`
    CreatedAt           time.Time          `bson:"created_at" json:"createdAt"`
    UpdatedAt           time.Time          `bson:"updated_at" json:"updatedAt"`
    ResolvedAt          *time.Time         `bson:"resolved_at,omitempty" json:"resolvedAt,omitempty"`
    IsRecalled          bool               `bson:"is_recalled" json:"isRecalled"`
    RecalledAt          *time.Time         `bson:"recalled_at,omitempty" json:"recalledAt,omitempty"`
    RecallReason        string             `bson:"recall_reason,omitempty" json:"recallReason,omitempty"`
}

type TicketResponse struct {
    ID               string         `json:"id"`
    TicketID         string         `json:"ticketId"`
    Title            string         `json:"title"`
    Description      string         `json:"description"`
    ReporterUserID   string         `json:"reporterUserId"`
    Category         TicketCategory `json:"category"`
    OrderOfImpact    int            `json:"orderOfImpact"`
    IsNewRequirement bool           `json:"isNewRequirement"`
    Status           TicketStatus   `json:"status"`
    StatusHistory    []StatusHistory `json:"statusHistory"`
    AssignedTo       string         `json:"assignedTo,omitempty"`
    ResolutionNotes  string         `json:"resolutionNotes,omitempty"`
    CreatedAt        time.Time      `json:"createdAt"`
    UpdatedAt        time.Time      `json:"updatedAt"`
    ResolvedAt       *time.Time     `json:"resolvedAt,omitempty"`
    IsRecalled       bool           `json:"isRecalled"`
    RecalledAt       *time.Time     `json:"recalledAt,omitempty"`
    RecallReason     string         `json:"recallReason,omitempty"`
}

func (t *Ticket) ToResponse() TicketResponse {
    return TicketResponse{
        ID:               t.ID.Hex(),
        TicketID:         t.TicketID,
        Title:            t.Title,
        Description:      t.Description,
        ReporterUserID:   t.ReporterUserID,
        Category:         t.Category,
        OrderOfImpact:    t.OrderOfImpact,
        IsNewRequirement: t.IsNewRequirement,
        Status:           t.Status,
        StatusHistory:    t.StatusHistory,
        AssignedTo:       t.AssignedTo,
        ResolutionNotes:  t.ResolutionNotes,
        CreatedAt:        t.CreatedAt,
        UpdatedAt:        t.UpdatedAt,
        ResolvedAt:       t.ResolvedAt,
        IsRecalled:       t.IsRecalled,
        RecalledAt:       t.RecalledAt,
        RecallReason:     t.RecallReason,
    }
}
"@
$ticketModel | Out-File -FilePath "$backendPath\models\ticket.go" -Encoding UTF8

# ============================================
# 7. BACKEND - helpers/ticketid.go
# ============================================
$ticketIdHelper = @"
package helpers

import (
    "fmt"
    "math/rand"
    "time"
)

func GenerateTicketID() string {
    now := time.Now()
    dateStr := now.Format("20060102")
    
    const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    b := make([]byte, 5)
    for i := range b {
        b[i] = charset[rand.Intn(len(charset))]
    }
    
    return fmt.Sprintf("TICK-%s-%s", dateStr, string(b))
}
"@
$ticketIdHelper | Out-File -FilePath "$backendPath\helpers\ticketid.go" -Encoding UTF8

# ============================================
# 8. BACKEND - helpers/password.go
# ============================================
$passwordHelper = @"
package helpers

import (
    "golang.org/x/crypto/bcrypt"
)

func HashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

func CheckPasswordHash(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
"@
$passwordHelper | Out-File -FilePath "$backendPath\helpers\password.go" -Encoding UTF8

# ============================================
# 9. BACKEND - helpers/jwt.go
# ============================================
$jwtHelper = @"
package helpers

import (
    "errors"
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type JWTClaims struct {
    UserID   string `json:"userId"`
    Email    string `json:"email"`
    Role     string `json:"role"`
    Username string `json:"username"`
    jwt.RegisteredClaims
}

func GenerateAccessToken(userID, email, role, username, secret string, expiry time.Duration) (string, error) {
    claims := JWTClaims{
        UserID:   userID,
        Email:    email,
        Role:     role,
        Username: username,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiry)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString, secret string) (*JWTClaims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, errors.New("invalid signing method")
        }
        return []byte(secret), nil
    })

    if err != nil {
        return nil, err
    }

    if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
        return claims, nil
    }

    return nil, errors.New("invalid token")
}
"@
$jwtHelper | Out-File -FilePath "$backendPath\helpers\jwt.go" -Encoding UTF8

# ============================================
# 10. BACKEND - middleware/auth.go
# ============================================
$authMiddleware = @"
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/yourusername/emr-issue-logger/backend/config"
    "github.com/yourusername/emr-issue-logger/backend/helpers"
)

func AuthMiddleware(cfg *config.Config) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
            c.Abort()
            return
        }

        parts := strings.Split(authHeader, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
            c.Abort()
            return
        }

        tokenString := parts[1]
        claims, err := helpers.ValidateToken(tokenString, cfg.JWTSecret)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
            c.Abort()
            return
        }

        c.Set("user_id", claims.UserID)
        c.Set("email", claims.Email)
        c.Set("role", claims.Role)
        c.Set("username", claims.Username)

        c.Next()
    }
}

func AdminMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        role, exists := c.Get("role")
        if !exists || role != "admin" {
            c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
            c.Abort()
            return
        }
        c.Next()
    }
}
"@
$authMiddleware | Out-File -FilePath "$backendPath\middleware\auth.go" -Encoding UTF8

# ============================================
# 11. BACKEND - database/mongodb.go
# ============================================
$mongoDb = @"
package database

import (
    "context"
    "log"
    "time"
    "github.com/yourusername/emr-issue-logger/backend/config"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

type MongoDB struct {
    Client *mongo.Client
    DB     *mongo.Database
    Config *config.Config
}

func NewMongoDB(cfg *config.Config) *MongoDB {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    clientOptions := options.Client().ApplyURI(cfg.MongoDBURI)
    client, err := mongo.Connect(ctx, clientOptions)
    if err != nil {
        log.Fatalf("Failed to connect to MongoDB: %v", err)
    }

    if err := client.Ping(ctx, nil); err != nil {
        log.Fatalf("Failed to ping MongoDB: %v", err)
    }

    db := client.Database(cfg.MongoDBDatabase)
    log.Println("Connected to MongoDB successfully")

    return &MongoDB{
        Client: client,
        DB:     db,
        Config: cfg,
    }
}

func (m *MongoDB) Close() {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    if err := m.Client.Disconnect(ctx); err != nil {
        log.Printf("Error disconnecting from MongoDB: %v", err)
    }
}

func (m *MongoDB) CreateIndexes(ctx context.Context) error {
    users := m.DB.Collection("users")
    _, err := users.Indexes().CreateMany(ctx, []mongo.IndexModel{
        {Keys: bson.D{{Key: "email", Value: 1}}, Options: options.Index().SetUnique(true)},
        {Keys: bson.D{{Key: "username", Value: 1}}, Options: options.Index().SetUnique(true)},
        {Keys: bson.D{{Key: "user_id", Value: 1}}, Options: options.Index().SetUnique(true)},
    })
    if err != nil {
        return err
    }

    tickets := m.DB.Collection("tickets")
    _, err = tickets.Indexes().CreateMany(ctx, []mongo.IndexModel{
        {Keys: bson.D{{Key: "ticket_id", Value: 1}}, Options: options.Index().SetUnique(true)},
        {Keys: bson.D{{Key: "reporter_user_id", Value: 1}}},
        {Keys: bson.D{{Key: "status", Value: 1}}},
        {Keys: bson.D{{Key: "category", Value: 1}}},
    })
    return err
}
"@
$mongoDb | Out-File -FilePath "$backendPath\database\mongodb.go" -Encoding UTF8

# ============================================
# 12. BACKEND - database/seed.go
# ============================================
$seedDb = @"
package database

import (
    "context"
    "log"
    "time"
    "github.com/yourusername/emr-issue-logger/backend/models"
    "go.mongodb.org/mongo-driver/bson"
    "golang.org/x/crypto/bcrypt"
)

func (m *MongoDB) Seed(ctx context.Context) error {
    users := m.DB.Collection("users")
    count, err := users.CountDocuments(ctx, bson.M{"email": "admin@emr.com"})
    if err != nil {
        return err
    }

    if count == 0 {
        hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("Admin@123"), bcrypt.DefaultCost)
        admin := models.User{
            UserID:     "ADMIN-001",
            Username:   "admin",
            Email:      "admin@emr.com",
            Password:   string(hashedPassword),
            FullName:   "System Administrator",
            Role:       models.RoleAdmin,
            CreatedAt:  time.Now(),
            UpdatedAt:  time.Now(),
            IsActive:   true,
        }
        if _, err := users.InsertOne(ctx, admin); err != nil {
            return err
        }
        log.Println("Admin user created successfully")
    }
    return nil
}
"@
$seedDb | Out-File -FilePath "$backendPath\database\seed.go" -Encoding UTF8

# ============================================
# 13. BACKEND - routes/routes.go
# ============================================
$routesFile = @"
package routes

import (
    "time"
    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    "github.com/yourusername/emr-issue-logger/backend/config"
    "github.com/yourusername/emr-issue-logger/backend/controllers"
    "github.com/yourusername/emr-issue-logger/backend/database"
    "github.com/yourusername/emr-issue-logger/backend/middleware"
)

func SetupRouter(cfg *config.Config, db *database.MongoDB) *gin.Engine {
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
                tickets.DELETE("/:id", ticketController.DeleteTicket)
                tickets.POST("/:id/recall", ticketController.RecallTicket)
            }

            admin := protected.Group("/admin")
            admin.Use(middleware.AdminMiddleware())
            {
                adminController := controllers.NewAdminController(db)
                admin.GET("/dashboard", adminController.GetDashboardStats)
                admin.GET("/users", adminController.GetAllUsers)
                admin.GET("/tickets", adminController.GetAllTickets)
                admin.PUT("/tickets/:id/assign", adminController.AssignTicket)
            }
        }
    }

    return router
}
"@
$routesFile | Out-File -FilePath "$backendPath\routes\routes.go" -Encoding UTF8

# ============================================
# 14. BACKEND - controllers/auth_controller.go
# ============================================
$authController = @"
package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/yourusername/emr-issue-logger/backend/config"
    "github.com/yourusername/emr-issue-logger/backend/database"
    "github.com/yourusername/emr-issue-logger/backend/helpers"
    "github.com/yourusername/emr-issue-logger/backend/models"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/mongo"
)

type AuthController struct {
    DB     *database.MongoDB
    Config *config.Config
}

func NewAuthController(db *database.MongoDB, cfg *config.Config) *AuthController {
    return &AuthController{DB: db, Config: cfg}
}

type RegisterRequest struct {
    Username string ` + "`json:\"username\" binding:\"required,min=3,max=50\"`" + `
    Email    string ` + "`json:\"email\" binding:\"required,email\"`" + `
    Password string ` + "`json:\"password\" binding:\"required,min=8\"`" + `
    FullName string ` + "`json:\"fullName\" binding:\"required\"`" + `
}

type LoginRequest struct {
    Email    string ` + "`json:\"email\" binding:\"required,email\"`" + `
    Password string ` + "`json:\"password\" binding:\"required\"`" + `
}

type AuthResponse struct {
    AccessToken  string              ` + "`json:\"accessToken\"`" + `
    RefreshToken string              ` + "`json:\"refreshToken\"`" + `
    User         models.UserResponse ` + "`json:\"user\"`" + `
}

func (ac *AuthController) Register(c *gin.Context) {
    var req RegisterRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    users := ac.DB.DB.Collection("users")
    var existingUser models.User
    
    err := users.FindOne(c.Request.Context(), bson.M{"email": req.Email}).Decode(&existingUser)
    if err == nil {
        c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
        return
    }

    err = users.FindOne(c.Request.Context(), bson.M{"username": req.Username}).Decode(&existingUser)
    if err == nil {
        c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
        return
    }

    hashedPassword, err := helpers.HashPassword(req.Password)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
        return
    }

    userID := "USR-" + helpers.GenerateTicketID()[5:10]
    user := models.User{
        UserID:    userID,
        Username:  req.Username,
        Email:     req.Email,
        Password:  hashedPassword,
        FullName:  req.FullName,
        Role:      models.RoleUser,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
        IsActive:  true,
    }

    _, err = users.InsertOne(c.Request.Context(), user)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "message": "User registered successfully",
        "user":    user.ToResponse(),
    })
}

func (ac *AuthController) Login(c *gin.Context) {
    var req LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    users := ac.DB.DB.Collection("users")
    var user models.User
    err := users.FindOne(c.Request.Context(), bson.M{"email": req.Email}).Decode(&user)
    if err != nil {
        if err == mongo.ErrNoDocuments {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
            return
        }
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find user"})
        return
    }

    if !user.IsActive {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Account is deactivated"})
        return
    }

    if !helpers.CheckPasswordHash(req.Password, user.Password) {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }

    accessToken, err := helpers.GenerateAccessToken(
        user.UserID, user.Email, string(user.Role), user.Username,
        ac.Config.JWTSecret, ac.Config.JWTAccessExpiry,
    )
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
        return
    }

    refreshToken, err := helpers.GenerateAccessToken(
        user.UserID, user.Email, string(user.Role), user.Username,
        ac.Config.JWTSecret, ac.Config.JWTRefreshExpiry,
    )
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate refresh token"})
        return
    }

    c.JSON(http.StatusOK, AuthResponse{
        AccessToken: accessToken,
        RefreshToken: refreshToken,
        User: user.ToResponse(),
    })
}

func (ac *AuthController) RefreshToken(c *gin.Context) {
    var req struct {
        RefreshToken string ` + "`json:\"refreshToken\" binding:\"required\"`" + `
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    claims, err := helpers.ValidateToken(req.RefreshToken, ac.Config.JWTSecret)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
        return
    }

    accessToken, err := helpers.GenerateAccessToken(
        claims.UserID, claims.Email, claims.Role, claims.Username,
        ac.Config.JWTSecret, ac.Config.JWTAccessExpiry,
    )
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"accessToken": accessToken})
}
"@
$authController | Out-File -FilePath "$backendPath\controllers\auth_controller.go" -Encoding UTF8

# ============================================
# 15. BACKEND - controllers/ticket_controller.go
# ============================================
$ticketController = @"
package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/yourusername/emr-issue-logger/backend/database"
    "github.com/yourusername/emr-issue-logger/backend/helpers"
    "github.com/yourusername/emr-issue-logger/backend/models"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/mongo/options"
)

type TicketController struct {
    DB *database.MongoDB
}

func NewTicketController(db *database.MongoDB) *TicketController {
    return &TicketController{DB: db}
}

type CreateTicketRequest struct {
    Title            string                ` + "`json:\"title\" binding:\"required,min=5,max=200\"`" + `
    Description      string                ` + "`json:\"description\" binding:\"required,min=10\"`" + `
    Category         models.TicketCategory ` + "`json:\"category\" binding:\"required\"`" + `
    OrderOfImpact    int                   ` + "`json:\"orderOfImpact\" binding:\"required,min=1,max=5\"`" + `
    IsNewRequirement bool                  ` + "`json:\"isNewRequirement\"`" + `
}

type UpdateTicketRequest struct {
    Title          string                ` + "`json:\"title,omitempty\"`" + `
    Description    string                ` + "`json:\"description,omitempty\"`" + `
    Category       models.TicketCategory ` + "`json:\"category,omitempty\"`" + `
    OrderOfImpact  int                   ` + "`json:\"orderOfImpact,omitempty\"`" + `
    Status         models.TicketStatus   ` + "`json:\"status,omitempty\"`" + `
    ResolutionNotes string               ` + "`json:\"resolutionNotes,omitempty\"`" + `
}

func (tc *TicketController) CreateTicket(c *gin.Context) {
    var req CreateTicketRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, _ := c.Get("user_id")
    tickets := tc.DB.DB.Collection("tickets")

    var ticketID string
    for {
        ticketID = helpers.GenerateTicketID()
        var existingTicket models.Ticket
        err := tickets.FindOne(c.Request.Context(), bson.M{"ticket_id": ticketID}).Decode(&existingTicket)
        if err != nil {
            break
        }
    }

    ticket := models.Ticket{
        TicketID:         ticketID,
        Title:            req.Title,
        Description:      req.Description,
        ReporterUserID:   userID.(string),
        Category:         req.Category,
        OrderOfImpact:    req.OrderOfImpact,
        IsNewRequirement: req.IsNewRequirement,
        Status:           models.StatusPending,
        StatusHistory: []models.StatusHistory{
            {Status: models.StatusPending, Timestamp: time.Now(), UpdatedBy: userID.(string), Note: "Ticket created"},
        },
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
        IsRecalled: false,
    }

    _, err := tickets.InsertOne(c.Request.Context(), ticket)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create ticket"})
        return
    }

    c.JSON(http.StatusCreated, ticket.ToResponse())
}

func (tc *TicketController) GetTickets(c *gin.Context) {
    tickets := tc.DB.DB.Collection("tickets")
    userID, _ := c.Get("user_id")
    role, _ := c.Get("role")

    query := bson.M{}
    if role != "admin" {
        query["reporter_user_id"] = userID.(string)
    }

    cursor, err := tickets.Find(c.Request.Context(), query)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tickets"})
        return
    }
    defer cursor.Close(c.Request.Context())

    var ticketList []models.Ticket
    if err := cursor.All(c.Request.Context(), &ticketList); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to decode tickets"})
        return
    }

    responses := make([]models.TicketResponse, len(ticketList))
    for i, ticket := range ticketList {
        responses[i] = ticket.ToResponse()
    }

    c.JSON(http.StatusOK, gin.H{"tickets": responses, "count": len(responses)})
}

func (tc *TicketController) GetTicket(c *gin.Context) {
    ticketID := c.Param("id")
    tickets := tc.DB.DB.Collection("tickets")

    var ticket models.Ticket
    err := tickets.FindOne(c.Request.Context(), bson.M{"ticket_id": ticketID}).Decode(&ticket)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    c.JSON(http.StatusOK, ticket.ToResponse())
}

func (tc *TicketController) UpdateTicket(c *gin.Context) {
    ticketID := c.Param("id")
    var req UpdateTicketRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    tickets := tc.DB.DB.Collection("tickets")
    var ticket models.Ticket
    err := tickets.FindOne(c.Request.Context(), bson.M{"ticket_id": ticketID}).Decode(&ticket)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    userID, _ := c.Get("user_id")
    role, _ := c.Get("role")

    if role != "admin" && ticket.ReporterUserID != userID.(string) {
        c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
        return
    }

    if req.Status != "" && req.Status != ticket.Status {
        ticket.StatusHistory = append(ticket.StatusHistory, models.StatusHistory{
            Status: req.Status,
            Timestamp: time.Now(),
            UpdatedBy: userID.(string),
            Note: req.ResolutionNotes,
        })
        ticket.Status = req.Status
        if req.Status == models.StatusResolved {
            now := time.Now()
            ticket.ResolvedAt = &now
        }
    }

    if req.Title != "" { ticket.Title = req.Title }
    if req.Description != "" { ticket.Description = req.Description }
    if req.Category != "" { ticket.Category = req.Category }
    if req.OrderOfImpact > 0 { ticket.OrderOfImpact = req.OrderOfImpact }
    ticket.UpdatedAt = time.Now()

    update := bson.M{"$set": ticket}
    _, err = tickets.UpdateOne(c.Request.Context(), bson.M{"ticket_id": ticketID}, update)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ticket"})
        return
    }

    c.JSON(http.StatusOK, ticket.ToResponse())
}

func (tc *TicketController) DeleteTicket(c *gin.Context) {
    ticketID := c.Param("id")
    tickets := tc.DB.DB.Collection("tickets")

    var ticket models.Ticket
    err := tickets.FindOne(c.Request.Context(), bson.M{"ticket_id": ticketID}).Decode(&ticket)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    if ticket.Status != models.StatusPending {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Only pending tickets can be deleted"})
        return
    }

    _, err = tickets.DeleteOne(c.Request.Context(), bson.M{"ticket_id": ticketID})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket deleted successfully"})
}

func (tc *TicketController) RecallTicket(c *gin.Context) {
    ticketID := c.Param("id")
    var req struct {
        Reason string ` + "`json:\"reason\" binding:\"required\"`" + `
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    tickets := tc.DB.DB.Collection("tickets")
    var ticket models.Ticket
    err := tickets.FindOne(c.Request.Context(), bson.M{"ticket_id": ticketID}).Decode(&ticket)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    if ticket.Status != models.StatusPending {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Only pending tickets can be recalled"})
        return
    }

    userID, _ := c.Get("user_id")
    if ticket.ReporterUserID != userID.(string) {
        c.JSON(http.StatusForbidden, gin.H{"error": "Only the reporter can recall the ticket"})
        return
    }

    now := time.Now()
    ticket.IsRecalled = true
    ticket.RecalledAt = &now
    ticket.RecallReason = req.Reason
    ticket.UpdatedAt = now
    ticket.StatusHistory = append(ticket.StatusHistory, models.StatusHistory{
        Status: models.StatusPending,
        Timestamp: now,
        UpdatedBy: userID.(string),
        Note: "Ticket recalled: " + req.Reason,
    })

    update := bson.M{"$set": ticket}
    _, err = tickets.UpdateOne(c.Request.Context(), bson.M{"ticket_id": ticketID}, update)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to recall ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket recalled successfully", "ticket": ticket.ToResponse()})
}
"@
$ticketController | Out-File -FilePath "$backendPath\controllers\ticket_controller.go" -Encoding UTF8

# ============================================
# 16. BACKEND - controllers/user_controller.go
# ============================================
$userController = @"
package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/yourusername/emr-issue-logger/backend/database"
    "github.com/yourusername/emr-issue-logger/backend/models"
    "go.mongodb.org/mongo-driver/bson"
)

type UserController struct {
    DB *database.MongoDB
}

func NewUserController(db *database.MongoDB) *UserController {
    return &UserController{DB: db}
}

type UpdateProfileRequest struct {
    FullName string ` + "`json:\"fullName,omitempty\"`" + `
    Username string ` + "`json:\"username,omitempty\"`" + `
}

func (uc *UserController) GetCurrentUser(c *gin.Context) {
    userID, _ := c.Get("user_id")
    users := uc.DB.DB.Collection("users")
    
    var user models.User
    err := users.FindOne(c.Request.Context(), bson.M{"user_id": userID}).Decode(&user)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
        return
    }

    c.JSON(http.StatusOK, user.ToResponse())
}

func (uc *UserController) UpdateProfile(c *gin.Context) {
    var req UpdateProfileRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, _ := c.Get("user_id")
    users := uc.DB.DB.Collection("users")

    update := bson.M{"updated_at": time.Now()}
    if req.FullName != "" { update["full_name"] = req.FullName }
    if req.Username != "" { update["username"] = req.Username }

    _, err := users.UpdateOne(c.Request.Context(), bson.M{"user_id": userID}, bson.M{"$set": update})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
        return
    }

    var user models.User
    err = users.FindOne(c.Request.Context(), bson.M{"user_id": userID}).Decode(&user)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch updated user"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Profile updated successfully", "user": user.ToResponse()})
}
"@
$userController | Out-File -FilePath "$backendPath\controllers\user_controller.go" -Encoding UTF8

# ============================================
# 17. BACKEND - controllers/admin_controller.go
# ============================================
$adminController = @"
package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/yourusername/emr-issue-logger/backend/database"
    "github.com/yourusername/emr-issue-logger/backend/models"
    "go.mongodb.org/mongo-driver/bson"
)

type AdminController struct {
    DB *database.MongoDB
}

func NewAdminController(db *database.MongoDB) *AdminController {
    return &AdminController{DB: db}
}

func (ac *AdminController) GetDashboardStats(c *gin.Context) {
    tickets := ac.DB.DB.Collection("tickets")
    users := ac.DB.DB.Collection("users")

    totalTickets, _ := tickets.CountDocuments(c.Request.Context(), bson.M{})
    pendingTickets, _ := tickets.CountDocuments(c.Request.Context(), bson.M{"status": models.StatusPending})
    inProgressTickets, _ := tickets.CountDocuments(c.Request.Context(), bson.M{"status": models.StatusInProgress})
    resolvedTickets, _ := tickets.CountDocuments(c.Request.Context(), bson.M{"status": models.StatusResolved})
    totalUsers, _ := users.CountDocuments(c.Request.Context(), bson.M{})
    recalledTickets, _ := tickets.CountDocuments(c.Request.Context(), bson.M{"is_recalled": true})

    c.JSON(http.StatusOK, gin.H{
        "totalTickets": totalTickets,
        "pendingTickets": pendingTickets,
        "inProgressTickets": inProgressTickets,
        "resolvedTickets": resolvedTickets,
        "totalUsers": totalUsers,
        "recalledTickets": recalledTickets,
    })
}

func (ac *AdminController) GetAllUsers(c *gin.Context) {
    users := ac.DB.DB.Collection("users")
    cursor, err := users.Find(c.Request.Context(), bson.M{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
        return
    }
    defer cursor.Close(c.Request.Context())

    var userList []models.User
    cursor.All(c.Request.Context(), &userList)

    responses := make([]models.UserResponse, len(userList))
    for i, user := range userList {
        responses[i] = user.ToResponse()
    }

    c.JSON(http.StatusOK, responses)
}

func (ac *AdminController) GetAllTickets(c *gin.Context) {
    tickets := ac.DB.DB.Collection("tickets")
    cursor, err := tickets.Find(c.Request.Context(), bson.M{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tickets"})
        return
    }
    defer cursor.Close(c.Request.Context())

    var ticketList []models.Ticket
    cursor.All(c.Request.Context(), &ticketList)

    responses := make([]models.TicketResponse, len(ticketList))
    for i, ticket := range ticketList {
        responses[i] = ticket.ToResponse()
    }

    c.JSON(http.StatusOK, responses)
}

func (ac *AdminController) AssignTicket(c *gin.Context) {
    ticketID := c.Param("id")
    var req struct {
        AssignedTo string ` + "`json:\"assignedTo\" binding:\"required\"`" + `
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    tickets := ac.DB.DB.Collection("tickets")
    update := bson.M{
        "$set": bson.M{
            "assigned_to": req.AssignedTo,
            "updated_at": time.Now(),
        },
    }

    result, err := tickets.UpdateOne(c.Request.Context(), bson.M{"ticket_id": ticketID}, update)
    if err != nil || result.MatchedCount == 0 {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket assigned successfully"})
}
"@
$adminController | Out-File -FilePath "$backendPath\controllers\admin_controller.go" -Encoding UTF8

# ============================================
# 18. BACKEND - Dockerfile
# ============================================
$backendDockerfile = @"
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
COPY --from=builder /app/.env .
EXPOSE 8080
CMD ["./main"]
"@
$backendDockerfile | Out-File -FilePath "$backendPath\Dockerfile" -Encoding UTF8

Write-Host "✅ Backend files created" -ForegroundColor Green

# ============================================
# FRONTEND FILES (Continued from previous)
# ============================================

# ============================================
# 19. FRONTEND - app.module.ts
# ============================================
Write-Host "📄 Creating frontend files..." -ForegroundColor Yellow

$appModule = @"
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { CommonModule } from '@angular/common';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

// Core
import { AuthInterceptor } from './core/interceptors/auth.interceptor';
import { ErrorInterceptor } from './core/interceptors/error.interceptor';
import { LoadingInterceptor } from './core/interceptors/loading.interceptor';

// Services
import { AuthService } from './core/services/auth.service';
import { TicketService } from './core/services/ticket.service';
import { UserService } from './core/services/user.service';
import { ToastService } from './core/services/toast.service';
import { LoadingService } from './core/services/loading.service';

// Pages
import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { ProfileComponent } from './pages/profile/profile.component';
import { CreateTicketComponent } from './pages/create-ticket/create-ticket.component';
import { MyTicketsComponent } from './pages/my-tickets/my-tickets.component';
import { TicketDetailsComponent } from './pages/ticket-details/ticket-details.component';
import { EditTicketComponent } from './pages/edit-ticket/edit-ticket.component';
import { AdminDashboardComponent } from './pages/admin-dashboard/admin-dashboard.component';
import { ManageTicketsComponent } from './pages/manage-tickets/manage-tickets.component';
import { ManageUsersComponent } from './pages/manage-users/manage-users.component';
import { NotFoundComponent } from './pages/not-found/not-found.component';
import { UnauthorizedComponent } from './pages/unauthorized/unauthorized.component';

// Shared Components
import { NavbarComponent } from './shared/components/navbar/navbar.component';
import { SidebarComponent } from './shared/components/sidebar/sidebar.component';
import { FooterComponent } from './shared/components/footer/footer.component';
import { StatusBadgeComponent } from './shared/components/status-badge/status-badge.component';
import { TicketCardComponent } from './shared/components/ticket-card/ticket-card.component';
import { StatisticsCardComponent } from './shared/components/statistics-card/statistics-card.component';
import { LoaderComponent } from './shared/components/loader/loader.component';
import { ToastComponent } from './shared/components/toast/toast.component';
import { ConfirmationDialogComponent } from './shared/components/confirmation-dialog/confirmation-dialog.component';
import { PaginationComponent } from './shared/components/pagination/pagination.component';
import { SearchComponent } from './shared/components/search/search.component';

// Directives & Pipes
import { AutoFocusDirective } from './shared/directives/auto-focus.directive';
import { ClickOutsideDirective } from './shared/directives/click-outside.directive';
import { ReplacePipe } from './shared/pipes/replace.pipe';
import { TruncatePipe } from './shared/pipes/truncate.pipe';

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent, RegisterComponent, DashboardComponent, ProfileComponent,
    CreateTicketComponent, MyTicketsComponent, TicketDetailsComponent, EditTicketComponent,
    AdminDashboardComponent, ManageTicketsComponent, ManageUsersComponent,
    NotFoundComponent, UnauthorizedComponent,
    NavbarComponent, SidebarComponent, FooterComponent, StatusBadgeComponent,
    TicketCardComponent, StatisticsCardComponent, LoaderComponent, ToastComponent,
    ConfirmationDialogComponent, PaginationComponent, SearchComponent,
    AutoFocusDirective, ClickOutsideDirective, ReplacePipe, TruncatePipe
  ],
  imports: [
    BrowserModule, CommonModule, AppRoutingModule, FormsModule, ReactiveFormsModule, HttpClientModule
  ],
  providers: [
    AuthService, TicketService, UserService, ToastService, LoadingService,
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: ErrorInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: LoadingInterceptor, multi: true }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
"@
$appModule | Out-File -FilePath "$frontendPath\src\app\app.module.ts" -Encoding UTF8

# ============================================
# 20. FRONTEND - app-routing.module.ts
# ============================================
$appRouting = @"
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { AdminGuard } from './core/guards/admin.guard';

import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { ProfileComponent } from './pages/profile/profile.component';
import { CreateTicketComponent } from './pages/create-ticket/create-ticket.component';
import { MyTicketsComponent } from './pages/my-tickets/my-tickets.component';
import { TicketDetailsComponent } from './pages/ticket-details/ticket-details.component';
import { EditTicketComponent } from './pages/edit-ticket/edit-ticket.component';
import { AdminDashboardComponent } from './pages/admin-dashboard/admin-dashboard.component';
import { ManageTicketsComponent } from './pages/manage-tickets/manage-tickets.component';
import { ManageUsersComponent } from './pages/manage-users/manage-users.component';
import { NotFoundComponent } from './pages/not-found/not-found.component';
import { UnauthorizedComponent } from './pages/unauthorized/unauthorized.component';

const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'profile', component: ProfileComponent, canActivate: [AuthGuard] },
  { path: 'tickets/create', component: CreateTicketComponent, canActivate: [AuthGuard] },
  { path: 'tickets', component: MyTicketsComponent, canActivate: [AuthGuard] },
  { path: 'tickets/:id', component: TicketDetailsComponent, canActivate: [AuthGuard] },
  { path: 'tickets/:id/edit', component: EditTicketComponent, canActivate: [AuthGuard] },
  { path: 'admin/dashboard', component: AdminDashboardComponent, canActivate: [AuthGuard, AdminGuard] },
  { path: 'admin/tickets', component: ManageTicketsComponent, canActivate: [AuthGuard, AdminGuard] },
  { path: 'admin/users', component: ManageUsersComponent, canActivate: [AuthGuard, AdminGuard] },
  { path: 'unauthorized', component: UnauthorizedComponent },
  { path: '**', component: NotFoundComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
"@
$appRouting | Out-File -FilePath "$frontendPath\src\app\app-routing.module.ts" -Encoding UTF8

# ============================================
# 21. FRONTEND - app.component.ts
# ============================================
$appComponent = @"
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  template: `
    <app-navbar *ngIf="isAuthenticated"></app-navbar>
    <app-sidebar *ngIf="isAuthenticated"></app-sidebar>
    <main [class.with-sidebar]="isAuthenticated">
      <router-outlet></router-outlet>
    </main>
    <app-footer *ngIf="isAuthenticated"></app-footer>
    <app-toast></app-toast>
    <app-loader></app-loader>
  `,
  styles: [`
    main {
      min-height: calc(100vh - 64px);
      background: #f5f7fa;
      transition: margin-left 0.3s ease;
      padding: 24px;
    }
    main.with-sidebar {
      margin-left: 250px;
    }
    @media (max-width: 768px) {
      main.with-sidebar {
        margin-left: 0;
        padding: 16px;
      }
    }
  `]
})
export class AppComponent {
  get isAuthenticated(): boolean {
    return !!localStorage.getItem('accessToken');
  }
}
"@
$appComponent | Out-File -FilePath "$frontendPath\src\app\app.component.ts" -Encoding UTF8

# ============================================
# 22. FRONTEND - Core Guards & Interceptors
# ============================================
$authGuard = @"
import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private authService: AuthService, private router: Router) {}
  canActivate(): boolean {
    if (this.authService.isLoggedIn()) return true;
    this.router.navigate(['/login']);
    return false;
  }
}
"@
$authGuard | Out-File -FilePath "$frontendPath\src\app\core\guards\auth.guard.ts" -Encoding UTF8

$adminGuard = @"
import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({ providedIn: 'root' })
export class AdminGuard implements CanActivate {
  constructor(private authService: AuthService, private router: Router) {}
  canActivate(): boolean {
    const user = this.authService.getCurrentUser();
    if (user && user.role === 'admin') return true;
    this.router.navigate(['/unauthorized']);
    return false;
  }
}
"@
$adminGuard | Out-File -FilePath "$frontendPath\src\app\core\guards\admin.guard.ts" -Encoding UTF8

$authInterceptor = @"
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from '../services/auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.authService.getAccessToken();
    if (token) {
      request = request.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
    }
    return next.handle(request);
  }
}
"@
$authInterceptor | Out-File -FilePath "$frontendPath\src\app\core\interceptors\auth.interceptor.ts" -Encoding UTF8

$errorInterceptor = @"
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Router } from '@angular/router';
import { ToastService } from '../services/toast.service';

@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  constructor(private router: Router, private toastService: ToastService) {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        let errorMessage = 'An error occurred';
        if (error.error?.error) errorMessage = error.error.error;
        else if (error.status === 401) {
          errorMessage = 'Session expired. Please login again.';
          localStorage.clear();
          this.router.navigate(['/login']);
        } else if (error.status === 403) errorMessage = 'You do not have permission.';
        else if (error.status === 404) errorMessage = 'Resource not found.';
        else if (error.status === 500) errorMessage = 'Server error. Please try again.';
        this.toastService.showError(errorMessage);
        return throwError(() => error);
      })
    );
  }
}
"@
$errorInterceptor | Out-File -FilePath "$frontendPath\src\app\core\interceptors\error.interceptor.ts" -Encoding UTF8

$loadingInterceptor = @"
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';
import { finalize } from 'rxjs/operators';
import { LoadingService } from '../services/loading.service';

@Injectable()
export class LoadingInterceptor implements HttpInterceptor {
  private activeRequests = 0;
  constructor(private loadingService: LoadingService) {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    if (this.activeRequests === 0) this.loadingService.show();
    this.activeRequests++;
    return next.handle(request).pipe(
      finalize(() => {
        this.activeRequests--;
        if (this.activeRequests === 0) this.loadingService.hide();
      })
    );
  }
}
"@
$loadingInterceptor | Out-File -FilePath "$frontendPath\src\app\core\interceptors\loading.interceptor.ts" -Encoding UTF8

# ============================================
# 23. FRONTEND - Core Services
# ============================================
$authService = @"
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';
import { tap } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface User {
  id: string; userId: string; username: string; email: string;
  fullName: string; role: 'user' | 'admin'; createdAt: string; isActive: boolean;
}

export interface AuthResponse {
  accessToken: string; refreshToken: string; user: User;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    const user = localStorage.getItem('user');
    if (user) this.currentUserSubject.next(JSON.parse(user));
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${environment.apiUrl}/auth/login`, { email, password })
      .pipe(tap(response => {
        localStorage.setItem('accessToken', response.accessToken);
        localStorage.setItem('refreshToken', response.refreshToken);
        localStorage.setItem('user', JSON.stringify(response.user));
        this.currentUserSubject.next(response.user);
      }));
  }

  register(username: string, email: string, password: string, fullName: string): Observable<any> {
    return this.http.post(`${environment.apiUrl}/auth/register`, { username, email, password, fullName });
  }

  logout(): void { localStorage.clear(); this.currentUserSubject.next(null); }
  refreshToken(): Observable<any> {
    return this.http.post(`${environment.apiUrl}/auth/refresh`, { refreshToken: localStorage.getItem('refreshToken') });
  }
  isLoggedIn(): boolean { return !!localStorage.getItem('accessToken'); }
  getCurrentUser(): User | null { return this.currentUserSubject.value; }
  getAccessToken(): string | null { return localStorage.getItem('accessToken'); }
}
"@
$authService | Out-File -FilePath "$frontendPath\src\app\core\services\auth.service.ts" -Encoding UTF8

$ticketService = @"
import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Ticket {
  id: string; ticketId: string; title: string; description: string;
  reporterUserId: string; category: string; orderOfImpact: number;
  isNewRequirement: boolean; status: string; statusHistory: any[];
  assignedTo?: string; resolutionNotes?: string; createdAt: string;
  updatedAt: string; resolvedAt?: string; isRecalled: boolean;
  recalledAt?: string; recallReason?: string;
}

export interface CreateTicketRequest {
  title: string; description: string; category: string;
  orderOfImpact: number; isNewRequirement: boolean;
}

export interface TicketFilter {
  status?: string[]; category?: string[]; reporter?: string;
  sort?: string; page?: number; limit?: number;
}

@Injectable({ providedIn: 'root' })
export class TicketService {
  constructor(private http: HttpClient) {}

  createTicket(data: CreateTicketRequest): Observable<Ticket> {
    return this.http.post<Ticket>(`${environment.apiUrl}/tickets`, data);
  }

  getTickets(filter?: TicketFilter): Observable<any> {
    let params = new HttpParams();
    if (filter) {
      if (filter.status) filter.status.forEach(s => params = params.append('status', s));
      if (filter.category) filter.category.forEach(c => params = params.append('category', c));
      if (filter.reporter) params = params.set('reporter', filter.reporter);
      if (filter.sort) params = params.set('sort', filter.sort);
      if (filter.page) params = params.set('page', filter.page.toString());
      if (filter.limit) params = params.set('limit', filter.limit.toString());
    }
    return this.http.get(`${environment.apiUrl}/tickets`, { params });
  }

  getTicket(id: string): Observable<Ticket> {
    return this.http.get<Ticket>(`${environment.apiUrl}/tickets/${id}`);
  }

  updateTicket(id: string, data: any): Observable<Ticket> {
    return this.http.put<Ticket>(`${environment.apiUrl}/tickets/${id}`, data);
  }

  deleteTicket(id: string): Observable<any> {
    return this.http.delete(`${environment.apiUrl}/tickets/${id}`);
  }

  recallTicket(id: string, reason: string): Observable<any> {
    return this.http.post(`${environment.apiUrl}/tickets/${id}/recall`, { reason });
  }

  getDashboardStats(): Observable<any> {
    return this.http.get(`${environment.apiUrl}/admin/dashboard`);
  }
}
"@
$ticketService | Out-File -FilePath "$frontendPath\src\app\core\services\ticket.service.ts" -Encoding UTF8

$userService = @"
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { User } from './auth.service';

@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private http: HttpClient) {}
  getCurrentUser(): Observable<User> {
    return this.http.get<User>(`${environment.apiUrl}/users/me`);
  }
  updateProfile(data: { fullName?: string; username?: string }): Observable<any> {
    return this.http.put(`${environment.apiUrl}/users/me`, data);
  }
  getAllUsers(): Observable<User[]> {
    return this.http.get<User[]>(`${environment.apiUrl}/admin/users`);
  }
}
"@
$userService | Out-File -FilePath "$frontendPath\src\app\core\services\user.service.ts" -Encoding UTF8

$toastService = @"
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface ToastMessage {
  type: 'success' | 'error' | 'warning' | 'info';
  message: string; duration?: number;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
  private toastsSubject = new BehaviorSubject<ToastMessage[]>([]);
  toasts$ = this.toastsSubject.asObservable();
  private toasts: ToastMessage[] = [];

  show(message: string, type: 'success' | 'error' | 'warning' | 'info' = 'info', duration: number = 5000): void {
    const toast: ToastMessage = { message, type, duration };
    this.toasts.push(toast);
    this.toastsSubject.next(this.toasts);
    setTimeout(() => this.remove(toast), duration);
  }

  showSuccess(message: string, duration?: number): void { this.show(message, 'success', duration); }
  showError(message: string, duration?: number): void { this.show(message, 'error', duration); }
  showWarning(message: string, duration?: number): void { this.show(message, 'warning', duration); }
  showInfo(message: string, duration?: number): void { this.show(message, 'info', duration); }

  remove(toast: ToastMessage): void {
    this.toasts = this.toasts.filter(t => t !== toast);
    this.toastsSubject.next(this.toasts);
  }
  clear(): void { this.toasts = []; this.toastsSubject.next(this.toasts); }
}
"@
$toastService | Out-File -FilePath "$frontendPath\src\app\core\services\toast.service.ts" -Encoding UTF8

$loadingService = @"
import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class LoadingService {
  private loadingSubject = new BehaviorSubject<boolean>(false);
  loading$ = this.loadingSubject.asObservable();
  show(): void { this.loadingSubject.next(true); }
  hide(): void { this.loadingSubject.next(false); }
}
"@
$loadingService | Out-File -FilePath "$frontendPath\src\app\core\services\loading.service.ts" -Encoding UTF8

# ============================================
# 24. FRONTEND - Core Models
# ============================================
$userModel = @"
export interface User {
  id: string; userId: string; username: string; email: string;
  fullName: string; role: 'user' | 'admin'; createdAt: string;
  updatedAt: string; isActive: boolean;
}
"@
$userModel | Out-File -FilePath "$frontendPath\src\app\core\models\user.model.ts" -Encoding UTF8

$ticketModel = @"
export type TicketStatus = 'pending' | 'in-progress' | 'resolved';
export type TicketCategory = 'system-issue' | 'data-integrity' | 'performance' | 'ui-ux' | 'integration' | 'other';

export interface StatusHistory {
  status: TicketStatus; timestamp: string; updatedBy: string; note?: string;
}

export interface Ticket {
  id: string; ticketId: string; title: string; description: string;
  reporterUserId: string; category: TicketCategory; orderOfImpact: number;
  isNewRequirement: boolean; status: TicketStatus; statusHistory: StatusHistory[];
  assignedTo?: string; resolutionNotes?: string; createdAt: string;
  updatedAt: string; resolvedAt?: string; isRecalled: boolean;
  recalledAt?: string; recallReason?: string;
}

export const StatusColors = { 'pending': 'danger', 'in-progress': 'warning', 'resolved': 'success' } as const;
export const StatusLabels = { 'pending': 'Pending', 'in-progress': 'In Progress', 'resolved': 'Resolved' } as const;
export const CategoryLabels = {
  'system-issue': 'System Issue', 'data-integrity': 'Data Integrity',
  'performance': 'Performance', 'ui-ux': 'UI/UX',
  'integration': 'Integration', 'other': 'Other'
} as const;
"@
$ticketModel | Out-File -FilePath "$frontendPath\src\app\core\models\ticket.model.ts" -Encoding UTF8

# ============================================
# 25. FRONTEND - Shared Components (Navbar, Status Badge, Ticket Card, Stats Card)
# ============================================
$navbarTs = @"
import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-navbar',
  template: \`
    <nav class="navbar">
      <div class="navbar-container">
        <div class="navbar-brand">
          <a routerLink="/dashboard"><span class="brand-icon">🏥</span><span class="brand-text">EMR Logger</span></a>
        </div>
        <button class="navbar-toggle" (click)="toggleMenu()"><span></span><span></span><span></span></button>
        <div class="navbar-menu" [class.active]="isMenuOpen">
          <a routerLink="/dashboard" routerLinkActive="active">Dashboard</a>
          <a routerLink="/tickets" routerLinkActive="active">My Tickets</a>
          <a routerLink="/tickets/create" routerLinkActive="active">New Ticket</a>
          <a *ngIf="isAdmin" routerLink="/admin/dashboard" routerLinkActive="active">Admin</a>
        </div>
        <div class="navbar-end">
          <div class="user-info" *ngIf="user">
            <span class="user-avatar">{{ user.fullName?.charAt(0) || user.username?.charAt(0) }}</span>
            <span class="user-name">{{ user.fullName || user.username }}</span>
          </div>
          <button class="logout-btn" (click)="logout()">🚪 Logout</button>
        </div>
      </div>
    </nav>
  \`,
  styles: [\`
    .navbar { background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.08); position: sticky; top: 0; z-index: 1000; }
    .navbar-container { display: flex; align-items: center; justify-content: space-between; padding: 0 24px; height: 64px; }
    .navbar-brand a { display: flex; align-items: center; gap: 10px; text-decoration: none; font-size: 20px; font-weight: 700; color: #333; }
    .brand-icon { font-size: 24px; }
    .brand-text { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .navbar-toggle { display: none; flex-direction: column; gap: 5px; background: none; border: none; cursor: pointer; padding: 5px; }
    .navbar-toggle span { display: block; width: 25px; height: 3px; background: #333; border-radius: 3px; }
    .navbar-menu { display: flex; gap: 5px; }
    .navbar-menu a { color: #555; text-decoration: none; padding: 8px 16px; border-radius: 8px; transition: all 0.3s; font-weight: 500; font-size: 14px; }
    .navbar-menu a:hover { background: #f0f0f0; color: #333; }
    .navbar-menu a.active { color: #667eea; background: #f0f0ff; }
    .navbar-end { display: flex; align-items: center; gap: 15px; }
    .user-info { display: flex; align-items: center; gap: 10px; }
    .user-avatar { width: 32px; height: 32px; border-radius: 50%; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px; }
    .user-name { font-size: 14px; font-weight: 500; color: #333; }
    .logout-btn { display: flex; align-items: center; gap: 6px; background: none; border: 1px solid #dc3545; color: #dc3545; padding: 6px 16px; border-radius: 8px; cursor: pointer; font-size: 14px; font-weight: 500; transition: all 0.3s; }
    .logout-btn:hover { background: #dc3545; color: white; }
    @media (max-width: 768px) {
      .navbar-toggle { display: flex; }
      .navbar-menu { display: none; position: absolute; top: 64px; left: 0; right: 0; background: white; flex-direction: column; padding: 16px 24px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
      .navbar-menu.active { display: flex; }
      .navbar-menu a { padding: 12px 16px; }
      .user-name { display: none; }
      .logout-btn { padding: 8px 12px; }
    }
  \`]
})
export class NavbarComponent implements OnInit {
  user: any; isAdmin = false; isMenuOpen = false;
  constructor(private authService: AuthService, private router: Router) {}
  ngOnInit(): void {
    this.user = this.authService.getCurrentUser();
    this.isAdmin = this.user?.role === 'admin';
  }
  logout(): void { this.authService.logout(); this.router.navigate(['/login']); }
  toggleMenu(): void { this.isMenuOpen = !this.isMenuOpen; }
}
"@
$navbarTs | Out-File -FilePath "$frontendPath\src\app\shared\components\navbar\navbar.component.ts" -Encoding UTF8

# Status Badge
$statusBadge = @"
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-status-badge',
  template: \`<span class="badge" [ngClass]="statusClass">{{ displayStatus }}</span>\`,
  styles: [\`
    .badge { display: inline-block; padding: 4px 14px; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
    .badge-pending { background: #ffe5e5; color: #dc3545; }
    .badge-in-progress { background: #fff3cd; color: #856404; }
    .badge-resolved { background: #d4edda; color: #155724; }
    .badge-recalled { background: #f8d7da; color: #721c24; }
  \`]
})
export class StatusBadgeComponent {
  @Input() status: string = '';
  @Input() isRecalled: boolean = false;
  get displayStatus(): string { return this.isRecalled ? 'Recalled' : this.status.replace('-', ' '); }
  get statusClass(): string { return this.isRecalled ? 'badge-recalled' : `badge-${this.status}`; }
}
"@
$statusBadge | Out-File -FilePath "$frontendPath\src\app\shared\components\status-badge\status-badge.component.ts" -Encoding UTF8

# Ticket Card
$ticketCard = @"
import { Component, Input } from '@angular/core';
import { Ticket } from '../../../core/models/ticket.model';

@Component({
  selector: 'app-ticket-card',
  template: \`
    <div class="ticket-card" [routerLink]="['/tickets', ticket.ticketId]">
      <div class="ticket-header">
        <div class="ticket-id">{{ ticket.ticketId }}</div>
        <app-status-badge [status]="ticket.status" [isRecalled]="ticket.isRecalled"></app-status-badge>
      </div>
      <h3 class="ticket-title">{{ ticket.title }}</h3>
      <p class="ticket-description">{{ ticket.description | slice:0:150 }}{{ ticket.description.length > 150 ? '...' : '' }}</p>
      <div class="ticket-footer">
        <span class="ticket-category">{{ ticket.category | replace:'-':' ' }}</span>
        <span class="ticket-date">{{ ticket.createdAt | date:'MMM d, yyyy' }}</span>
      </div>
    </div>
  \`,
  styles: [\`
    .ticket-card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); cursor: pointer; transition: all 0.3s; border: 1px solid transparent; }
    .ticket-card:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0,0,0,0.1); border-color: #667eea; }
    .ticket-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
    .ticket-id { font-size: 13px; font-weight: 600; color: #667eea; }
    .ticket-title { margin: 0 0 8px 0; font-size: 16px; color: #333; }
    .ticket-description { color: #666; font-size: 14px; line-height: 1.5; margin: 0 0 12px 0; }
    .ticket-footer { display: flex; justify-content: space-between; align-items: center; font-size: 13px; color: #888; padding-top: 12px; border-top: 1px solid #f0f0f0; }
    .ticket-category { text-transform: capitalize; }
  \`]
})
export class TicketCardComponent {
  @Input() ticket!: Ticket;
}
"@
$ticketCard | Out-File -FilePath "$frontendPath\src\app\shared\components\ticket-card\ticket-card.component.ts" -Encoding UTF8

# Statistics Card
$statsCard = @"
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-statistics-card',
  template: \`
    <div class="stats-card" [ngClass]="'stats-' + color">
      <div class="stats-icon">{{ icon }}</div>
      <div class="stats-content">
        <div class="stats-count">{{ count }}</div>
        <div class="stats-title">{{ title }}</div>
      </div>
    </div>
  \`,
  styles: [\`
    .stats-card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); display: flex; align-items: center; gap: 16px; transition: all 0.3s; border-left: 4px solid #667eea; }
    .stats-card:hover { transform: translateY(-3px); box-shadow: 0 8px 25px rgba(0,0,0,0.1); }
    .stats-primary { border-left-color: #667eea; }
    .stats-danger { border-left-color: #dc3545; }
    .stats-warning { border-left-color: #ffc107; }
    .stats-success { border-left-color: #28a745; }
    .stats-icon { font-size: 32px; width: 50px; height: 50px; display: flex; align-items: center; justify-content: center; background: #f8f9fa; border-radius: 10px; }
    .stats-content { flex: 1; }
    .stats-count { font-size: 28px; font-weight: 700; color: #333; line-height: 1; }
    .stats-title { font-size: 14px; color: #888; margin-top: 4px; }
  \`]
})
export class StatisticsCardComponent {
  @Input() title: string = '';
  @Input() count: number = 0;
  @Input() color: 'primary' | 'danger' | 'warning' | 'success' = 'primary';
  @Input() icon: string = '📊';
}
"@
$statsCard | Out-File -FilePath "$frontendPath\src\app\shared\components\statistics-card\statistics-card.component.ts" -Encoding UTF8

# ============================================
# 26. FRONTEND - Simple Components (Loader, Pagination, Search, Toast, Confirmation Dialog)
# ============================================
$loaderTs = @"
import { Component } from '@angular/core';
import { LoadingService } from '../../../core/services/loading.service';

@Component({
  selector: 'app-loader',
  template: \`
    <div class="loader-overlay" *ngIf="loading$ | async">
      <div class="loader-container">
        <div class="loader-spinner"></div>
        <p class="loader-text">Loading...</p>
      </div>
    </div>
  \`,
  styles: [\`
    .loader-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(255,255,255,0.85); display: flex; align-items: center; justify-content: center; z-index: 9999; }
    .loader-spinner { width: 50px; height: 50px; border: 4px solid #f0f0f0; border-top: 4px solid #667eea; border-radius: 50%; animation: spin 0.8s linear infinite; margin: 0 auto 16px; }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    .loader-text { color: #666; font-size: 16px; font-weight: 500; }
  \`]
})
export class LoaderComponent {
  loading$ = this.loadingService.loading$;
  constructor(private loadingService: LoadingService) {}
}
"@
$loaderTs | Out-File -FilePath "$frontendPath\src\app\shared\components\loader\loader.component.ts" -Encoding UTF8

# Pagination
$paginationTs = @"
import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';

@Component({
  selector: 'app-pagination',
  template: \`
    <div class="pagination-container" *ngIf="totalPages > 1">
      <div class="pagination-info">Page {{ currentPage }} of {{ totalPages }} ({{ totalItems }} items)</div>
      <div class="pagination-controls">
        <button class="pagination-btn" (click)="goToPrevious()" [disabled]="currentPage === 1">←</button>
        <button *ngFor="let page of visiblePages" class="pagination-btn" [class.active]="page === currentPage" (click)="goToPage(page)">{{ page }}</button>
        <button class="pagination-btn" (click)="goToNext()" [disabled]="currentPage === totalPages">→</button>
      </div>
    </div>
  \`,
  styles: [\`
    .pagination-container { display: flex; justify-content: space-between; align-items: center; padding: 16px 0; flex-wrap: wrap; gap: 12px; }
    .pagination-info { color: #666; font-size: 14px; }
    .pagination-controls { display: flex; gap: 4px; flex-wrap: wrap; }
    .pagination-btn { min-width: 36px; height: 36px; padding: 0 10px; border: 1px solid #e0e0e0; background: white; border-radius: 8px; color: #555; font-size: 14px; cursor: pointer; transition: all 0.3s; }
    .pagination-btn:hover:not(:disabled):not(.active) { background: #f0f0ff; border-color: #667eea; color: #667eea; }
    .pagination-btn.active { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-color: #667eea; color: white; }
    .pagination-btn:disabled { opacity: 0.4; cursor: not-allowed; }
  \`]
})
export class PaginationComponent implements OnInit {
  @Input() currentPage: number = 1;
  @Input() totalPages: number = 1;
  @Input() totalItems: number = 0;
  @Output() pageChange = new EventEmitter<number>();
  visiblePages: number[] = [];

  ngOnInit(): void { this.updateVisiblePages(); }
  ngOnChanges(): void { this.updateVisiblePages(); }

  updateVisiblePages(): void {
    const maxVisible = 5;
    const pages = Array.from({ length: this.totalPages }, (_, i) => i + 1);
    if (this.totalPages <= maxVisible) { this.visiblePages = pages; return; }
    const start = Math.max(1, this.currentPage - 2);
    const end = Math.min(this.totalPages, start + maxVisible - 1);
    this.visiblePages = Array.from({ length: end - start + 1 }, (_, i) => start + i);
  }

  goToPage(page: number): void {
    if (page >= 1 && page <= this.totalPages && page !== this.currentPage) {
      this.pageChange.emit(page);
    }
  }
  goToPrevious(): void { if (this.currentPage > 1) this.goToPage(this.currentPage - 1); }
  goToNext(): void { if (this.currentPage < this.totalPages) this.goToPage(this.currentPage + 1); }
}
"@
$paginationTs | Out-File -FilePath "$frontendPath\src\app\shared\components\pagination\pagination.component.ts" -Encoding UTF8

# Search
$searchTs = @"
import { Component, Input, Output, EventEmitter } from '@angular/core';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'app-search',
  template: \`
    <div class="search-container">
      <div class="search-box">
        <span class="search-icon">🔍</span>
        <input type="text" class="search-input" [placeholder]="placeholder" (input)="onSearch($any($event.target).value)" #searchInput>
        <button *ngIf="searchInput.value" class="clear-btn" (click)="searchInput.value=''; onSearch('')">✕</button>
      </div>
    </div>
  \`,
  styles: [\`
    .search-container { width: 100%; max-width: 400px; }
    .search-box { display: flex; align-items: center; background: white; border: 2px solid #e0e0e0; border-radius: 10px; padding: 0 14px; transition: all 0.3s; }
    .search-box:focus-within { border-color: #667eea; box-shadow: 0 0 0 3px rgba(102,126,234,0.1); }
    .search-icon { color: #999; font-size: 16px; margin-right: 10px; }
    .search-input { flex: 1; border: none; outline: none; padding: 10px 0; font-size: 14px; color: #333; background: transparent; }
    .search-input::placeholder { color: #aaa; }
    .clear-btn { background: none; border: none; color: #999; cursor: pointer; padding: 4px 8px; font-size: 14px; border-radius: 50%; transition: all 0.3s; }
    .clear-btn:hover { background: #f0f0f0; color: #333; }
  \`]
})
export class SearchComponent {
  @Input() placeholder: string = 'Search...';
  @Input() debounceTime: number = 300;
  @Output() search = new EventEmitter<string>();
  private searchSubject = new Subject<string>();

  constructor() {
    this.searchSubject.pipe(debounceTime(this.debounceTime), distinctUntilChanged())
      .subscribe(term => this.search.emit(term));
  }

  onSearch(term: string): void { this.searchSubject.next(term); }
}
"@
$searchTs | Out-File -FilePath "$frontendPath\src\app\shared\components\search\search.component.ts" -Encoding UTF8

# Confirmation Dialog
$confirmTs = @"
import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-confirmation-dialog',
  template: \`
    <div class="dialog-overlay" *ngIf="isOpen" (click)="onCancel()">
      <div class="dialog-content" (click)="$event.stopPropagation()">
        <div class="dialog-header"><h3>{{ title }}</h3><button class="close-btn" (click)="onCancel()">✕</button></div>
        <div class="dialog-body"><p>{{ message }}</p></div>
        <div class="dialog-footer">
          <button class="btn btn-secondary" (click)="onCancel()">{{ cancelText }}</button>
          <button class="btn" [ngClass]="confirmButtonClass" (click)="onConfirm()">{{ confirmText }}</button>
        </div>
      </div>
    </div>
  \`,
  styles: [\`
    .dialog-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 9998; }
    .dialog-content { background: white; border-radius: 16px; max-width: 500px; width: 90%; padding: 30px; animation: slideUp 0.3s ease; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
    @keyframes slideUp { from { transform: translateY(30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
    .dialog-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
    .dialog-header h3 { margin: 0; color: #333; font-size: 20px; }
    .close-btn { background: none; border: none; font-size: 20px; color: #999; cursor: pointer; padding: 4px 8px; border-radius: 8px; }
    .close-btn:hover { background: #f0f0f0; color: #333; }
    .dialog-body { margin-bottom: 24px; }
    .dialog-body p { color: #555; font-size: 15px; line-height: 1.6; margin: 0; }
    .dialog-footer { display: flex; justify-content: flex-end; gap: 10px; }
    .btn { padding: 10px 24px; border: none; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.3s; }
    .btn-secondary { background: #f0f0f0; color: #555; }
    .btn-secondary:hover { background: #e0e0e0; }
    .btn-danger { background: #dc3545; color: white; }
    .btn-danger:hover { background: #c82333; }
    .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
    .btn-primary:hover { transform: translateY(-1px); }
  \`]
})
export class ConfirmationDialogComponent {
  @Input() title: string = 'Confirm Action';
  @Input() message: string = 'Are you sure?';
  @Input() confirmText: string = 'Confirm';
  @Input() cancelText: string = 'Cancel';
  @Input() confirmButtonClass: string = 'btn-danger';
  @Input() isOpen: boolean = false;
  @Output() confirm = new EventEmitter<void>();
  @Output() cancel = new EventEmitter<void>();
  onConfirm(): void { this.confirm.emit(); }
  onCancel(): void { this.cancel.emit(); }
}
"@
$confirmTs | Out-File -FilePath "$frontendPath\src\app\shared\components\confirmation-dialog\confirmation-dialog.component.ts" -Encoding UTF8

# Toast
$toastTs = @"
import { Component } from '@angular/core';
import { ToastService, ToastMessage } from '../../../core/services/toast.service';

@Component({
  selector: 'app-toast',
  template: \`
    <div class="toast-container">
      <div *ngFor="let toast of toasts$ | async" class="toast" [ngClass]="'toast-' + toast.type" (click)="removeToast(toast)">
        <span class="toast-icon">{{ getIcon(toast.type) }}</span>
        <span class="toast-message">{{ toast.message }}</span>
        <button class="toast-close">✕</button>
      </div>
    </div>
  \`,
  styles: [\`
    .toast-container { position: fixed; top: 80px; right: 20px; z-index: 9999; display: flex; flex-direction: column; gap: 10px; max-width: 400px; width: 100%; }
    .toast { display: flex; align-items: center; gap: 12px; padding: 14px 18px; border-radius: 12px; background: white; box-shadow: 0 8px 30px rgba(0,0,0,0.15); cursor: pointer; transition: all 0.3s; border-left: 4px solid #667eea; }
    .toast:hover { transform: translateX(-4px); }
    .toast-success { border-left-color: #28a745; }
    .toast-error { border-left-color: #dc3545; }
    .toast-warning { border-left-color: #ffc107; }
    .toast-info { border-left-color: #667eea; }
    .toast-icon { font-size: 20px; flex-shrink: 0; }
    .toast-message { flex: 1; color: #333; font-size: 14px; font-weight: 500; }
    .toast-close { background: none; border: none; color: #999; cursor: pointer; font-size: 16px; padding: 0 4px; }
    .toast-close:hover { color: #333; }
  \`]
})
export class ToastComponent {
  toasts$ = this.toastService.toasts$;
  constructor(private toastService: ToastService) {}
  getIcon(type: string): string {
    switch(type) {
      case 'success': return '✅';
      case 'error': return '❌';
      case 'warning': return '⚠️';
      default: return 'ℹ️';
    }
  }
  removeToast(toast: ToastMessage): void { this.toastService.remove(toast); }
}
"@
$toastTs | Out-File -FilePath "$frontendPath\src\app\shared\components\toast\toast.component.ts" -Encoding UTF8

# ============================================
# 27. FRONTEND - Directives & Pipes
# ============================================
$autoFocus = @"
import { Directive, ElementRef, Input, OnInit } from '@angular/core';

@Directive({ selector: '[appAutoFocus]' })
export class AutoFocusDirective implements OnInit {
  @Input() appAutoFocus: boolean = true;
  constructor(private el: ElementRef) {}
  ngOnInit(): void {
    if (this.appAutoFocus) {
      setTimeout(() => this.el.nativeElement.focus(), 100);
    }
  }
}
"@
$autoFocus | Out-File -FilePath "$frontendPath\src\app\shared\directives\auto-focus.directive.ts" -Encoding UTF8

$clickOutside = @"
import { Directive, ElementRef, Output, EventEmitter, HostListener } from '@angular/core';

@Directive({ selector: '[appClickOutside]' })
export class ClickOutsideDirective {
  @Output() appClickOutside = new EventEmitter<void>();
  constructor(private el: ElementRef) {}
  @HostListener('document:click', ['$event'])
  onClick(event: Event): void {
    if (!this.el.nativeElement.contains(event.target)) {
      this.appClickOutside.emit();
    }
  }
}
"@
$clickOutside | Out-File -FilePath "$frontendPath\src\app\shared\directives\click-outside.directive.ts" -Encoding UTF8

$replacePipe = @"
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'replace' })
export class ReplacePipe implements PipeTransform {
  transform(value: string, search: string, replace: string): string {
    if (!value || !search) return value;
    return value.split(search).join(replace);
  }
}
"@
$replacePipe | Out-File -FilePath "$frontendPath\src\app\shared\pipes\replace.pipe.ts" -Encoding UTF8

$truncatePipe = @"
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'truncate' })
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit: number = 100, completeWords: boolean = false): string {
    if (!value || value.length <= limit) return value;
    let truncated = value.substring(0, limit);
    if (completeWords) {
      const lastSpace = truncated.lastIndexOf(' ');
      if (lastSpace > 0) truncated = truncated.substring(0, lastSpace);
    }
    return truncated + '...';
  }
}
"@
$truncatePipe | Out-File -FilePath "$frontendPath\src\app\shared\pipes\truncate.pipe.ts" -Encoding UTF8

# ============================================
# 28. FRONTEND - Environment & Main Files
# ============================================
$envDev = @"
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api/v1'
};
"@
$envDev | Out-File -FilePath "$frontendPath\src\environments\environment.ts" -Encoding UTF8

$envProd = @"
export const environment = {
  production: true,
  apiUrl: '/api/v1'
};
"@
$envProd | Out-File -FilePath "$frontendPath\src\environments\environment.prod.ts" -Encoding UTF8

$mainTs = @"
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule)
  .catch(err => console.error(err));
"@
$mainTs | Out-File -FilePath "$frontendPath\src\main.ts" -Encoding UTF8

$indexHtml = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>EMR Issue Logger</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
"@
$indexHtml | Out-File -FilePath "$frontendPath\src\index.html" -Encoding UTF8

$stylesCss = @"
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; background: #f5f7fa; color: #333; }
::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 10px; }
::-webkit-scrollbar-thumb { background: #667eea; border-radius: 10px; }
::-webkit-scrollbar-thumb:hover { background: #5a67d8; }
.text-center { text-align: center; }
.text-muted { color: #6c757d; }
.mt-1 { margin-top: 10px; }
.mt-2 { margin-top: 20px; }
.mb-1 { margin-bottom: 10px; }
.mb-2 { margin-bottom: 20px; }
"@
$stylesCss | Out-File -FilePath "$frontendPath\src\styles.css" -Encoding UTF8

# ============================================
# 29. FRONTEND - Configuration Files
# ============================================
$packageJson = @"
{
  "name": "emr-issue-logger-frontend",
  "version": "1.0.0",
  "scripts": {
    "ng": "ng",
    "start": "ng serve",
    "build": "ng build",
    "watch": "ng build --watch --configuration development",
    "test": "ng test"
  },
  "private": true,
  "dependencies": {
    "@angular/animations": "^17.0.0",
    "@angular/common": "^17.0.0",
    "@angular/compiler": "^17.0.0",
    "@angular/core": "^17.0.0",
    "@angular/forms": "^17.0.0",
    "@angular/platform-browser": "^17.0.0",
    "@angular/platform-browser-dynamic": "^17.0.0",
    "@angular/router": "^17.0.0",
    "rxjs": "~7.8.0",
    "tslib": "^2.3.0",
    "zone.js": "~0.14.0"
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "^17.0.0",
    "@angular/cli": "^17.0.0",
    "@angular/compiler-cli": "^17.0.0",
    "@types/jasmine": "~5.1.0",
    "jasmine-core": "~5.1.0",
    "karma": "~6.4.0",
    "karma-chrome-launcher": "~3.2.0",
    "karma-coverage": "~2.2.0",
    "karma-jasmine": "~5.1.0",
    "karma-jasmine-html-reporter": "~2.1.0",
    "typescript": "~5.2.2"
  }
}
"@
$packageJson | Out-File -FilePath "$frontendPath\package.json" -Encoding UTF8

$angularJson = @"
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "newProjectRoot": "projects",
  "projects": {
    "frontend": {
      "projectType": "application",
      "schematics": {
        "@schematics/angular:component": { "style": "css" },
        "@schematics/angular:application": { "strict": true }
      },
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:application",
          "options": {
            "outputPath": { "base": "dist/frontend" },
            "index": "src/index.html",
            "browser": "src/main.ts",
            "polyfills": ["zone.js"],
            "tsConfig": "tsconfig.app.json",
            "assets": ["src/favicon.ico", "src/assets"],
            "styles": ["src/styles.css"],
            "scripts": []
          },
          "configurations": {
            "production": {
              "budgets": [
                { "type": "initial", "maximumWarning": "500kb", "maximumError": "1mb" },
                { "type": "anyComponentStyle", "maximumWarning": "2kb", "maximumError": "4kb" }
              ],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular-devkit/build-angular:dev-server",
          "configurations": {
            "production": { "buildTarget": "frontend:build:production" },
            "development": { "buildTarget": "frontend:build:development" }
          },
          "defaultConfiguration": "development"
        },
        "extract-i18n": {
          "builder": "@angular-devkit/build-angular:extract-i18n",
          "options": { "buildTarget": "frontend:build" }
        },
        "test": {
          "builder": "@angular-devkit/build-angular:karma",
          "options": {
            "polyfills": ["zone.js", "zone.js/testing"],
            "tsConfig": "tsconfig.spec.json",
            "assets": ["src/favicon.ico", "src/assets"],
            "styles": ["src/styles.css"],
            "scripts": []
          }
        }
      }
    }
  }
}
"@
$angularJson | Out-File -FilePath "$frontendPath\angular.json" -Encoding UTF8

$tsconfig = @"
{
  "compileOnSave": false,
  "compilerOptions": {
    "outDir": "./dist/out-tsc",
    "strict": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "sourceMap": true,
    "declaration": false,
    "experimentalDecorators": true,
    "moduleResolution": "node",
    "importHelpers": true,
    "target": "ES2022",
    "module": "ES2022",
    "useDefineForClassFields": false,
    "lib": ["ES2022", "dom"]
  },
  "angularCompilerOptions": {
    "enableI18nLegacyMessageIdFormat": false,
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true
  }
}
"@
$tsconfig | Out-File -FilePath "$frontendPath\tsconfig.json" -Encoding UTF8

# ============================================
# 30. FRONTEND - Docker & Nginx
# ============================================
$frontendDockerfile = @"
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build -- --configuration=production

FROM nginx:alpine
COPY --from=builder /app/dist/frontend/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
"@
$frontendDockerfile | Out-File -FilePath "$frontendPath\Dockerfile" -Encoding UTF8

$nginxConf = @"
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        location / {
            try_files $uri $uri/ /index.html;
        }
        location /api/ {
            proxy_pass http://backend:8080/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
"@
$nginxConf | Out-File -FilePath "$frontendPath\nginx.conf" -Encoding UTF8

Write-Host "✅ Frontend files created" -ForegroundColor Green

# ============================================
# 31. DOCKER-COMPOSE
# ============================================
Write-Host "📄 Creating docker-compose.yml..." -ForegroundColor Yellow

$dockerCompose = @"
version: '3.8'

services:
  mongodb:
    image: mongo:6.0
    container_name: emr-mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
      MONGO_INITDB_DATABASE: emr_issue_logger
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: emr-backend
    restart: unless-stopped
    environment:
      PORT: 8080
      MONGODB_URI: mongodb://admin:password123@mongodb:27017
      MONGODB_DATABASE: emr_issue_logger
      JWT_SECRET: production-secret-change-this
      JWT_ACCESS_EXPIRY: 15m
      JWT_REFRESH_EXPIRY: 7d
      BCRYPT_COST: 12
      CORS_ALLOWED_ORIGINS: http://localhost:4200,http://localhost
      ENVIRONMENT: production
    ports:
      - "8080:8080"
    depends_on:
      - mongodb
    volumes:
      - ./backend:/app
      - /app/vendor

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: emr-frontend
    restart: unless-stopped
    ports:
      - "80:80"
      - "4200:4200"
    depends_on:
      - backend
    environment:
      API_URL: http://backend:8080/api/v1

volumes:
  mongodb_data:
    driver: local
"@
$dockerCompose | Out-File -FilePath "$rootPath\docker-compose.yml" -Encoding UTF8
Write-Host "✅ docker-compose.yml created" -ForegroundColor Green

# ============================================
# 32. GITHUB ACTIONS CI/CD
# ============================================
Write-Host "📄 Creating GitHub Actions workflow..." -ForegroundColor Yellow

$githubWorkflow = @"
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - name: Run Backend Tests
        working-directory: ./backend
        run: |
          go test -v ./...
          go test -v -race ./...
  
  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install Dependencies
        working-directory: ./frontend
        run: npm ci
      - name: Run Frontend Tests
        working-directory: ./frontend
        run: npm run test -- --no-watch --no-progress --browsers=ChromeHeadless
  
  build-and-deploy:
    needs: [test-backend, test-frontend]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - name: Build and Push Backend
        working-directory: ./backend
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/emr-backend:latest .
          docker push ${{ secrets.DOCKER_USERNAME }}/emr-backend:latest
      - name: Build and Push Frontend
        working-directory: ./frontend
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/emr-frontend:latest .
          docker push ${{ secrets.DOCKER_USERNAME }}/emr-frontend:latest
      - name: Deploy to Production
        run: |
          echo "Deploying to production server..."
"@

$githubPath = "$rootPath\.github\workflows"
New-Item -Path $githubPath -ItemType Directory -Force | Out-Null
$githubWorkflow | Out-File -FilePath "$githubPath\ci.yml" -Encoding UTF8
Write-Host "✅ GitHub Actions workflow created" -ForegroundColor Green

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ COMPLETE PROJECT GENERATED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Summary:" -ForegroundColor Yellow
Write-Host "  - Backend files: 18" -ForegroundColor White
Write-Host "  - Frontend files: 32" -ForegroundColor White
Write-Host "  - Config files: 4" -ForegroundColor White
Write-Host "  - Total: 54+ files" -ForegroundColor White
Write-Host "  - Location: $rootPath" -ForegroundColor White

Write-Host ""
Write-Host "🚀 Quick Start:" -ForegroundColor Cyan
Write-Host "  1. Backend:" -ForegroundColor White
Write-Host "     cd C:\ECEWS_emr_issue_log\backend" -ForegroundColor Gray
Write-Host "     go mod tidy" -ForegroundColor Gray
Write-Host "     go run cmd/server/main.go" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Frontend:" -ForegroundColor White
Write-Host "     cd C:\ECEWS_emr_issue_log\frontend" -ForegroundColor Gray
Write-Host "     npm install" -ForegroundColor Gray
Write-Host "     ng serve" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Docker (Optional):" -ForegroundColor White
Write-Host "     cd C:\ECEWS_emr_issue_log" -ForegroundColor Gray
Write-Host "     docker-compose up -d" -ForegroundColor Gray

Write-Host ""
Write-Host "📝 Default Admin Login:" -ForegroundColor Yellow
Write-Host "  Email: admin@emr.com" -ForegroundColor White
Write-Host "  Password: Admin@123" -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan