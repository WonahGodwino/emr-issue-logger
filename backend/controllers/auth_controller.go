package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "github.com/WonahGodwino/emr-issue-logger/backend/config"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/helpers"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
)

type AuthController struct {
    DB     *database.CouchbaseDB
    Config *config.Config
}

func NewAuthController(db *database.CouchbaseDB, cfg *config.Config) *AuthController {
    return &AuthController{DB: db, Config: cfg}
}

type RegisterRequest struct {
    Username string `json:"username" binding:"required,min=3,max=50"`
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required,min=8"`
    FullName string `json:"fullName" binding:"required"`
}

type LoginRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
    AccessToken  string              `json:"accessToken"`
    RefreshToken string              `json:"refreshToken"`
    User         models.UserResponse `json:"user"`
}

func (ac *AuthController) Register(c *gin.Context) {
    var req RegisterRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    bucket := ac.DB.Bucket

    // Check email uniqueness
    query := "SELECT COUNT(*) AS cnt FROM `" + ac.DB.Config.CouchbaseBucket + "` WHERE docType = 'user' AND email = $email"
    result, err := ac.DB.ExecuteQuery(query, map[string]interface{}{"email": req.Email})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
        return
    }

    emailExists := false
    for result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if cnt := helpers.GetIntFromMap(row, "cnt"); cnt > 0 {
                emailExists = true
            }
        }
    }

    if emailExists {
        c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
        return
    }

    // Check username uniqueness
    query = "SELECT COUNT(*) AS cnt FROM `" + ac.DB.Config.CouchbaseBucket + "` WHERE docType = 'user' AND username = $username"
    result, err = ac.DB.ExecuteQuery(query, map[string]interface{}{"username": req.Username})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
        return
    }

    usernameExists := false
    for result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if cnt := helpers.GetIntFromMap(row, "cnt"); cnt > 0 {
                usernameExists = true
            }
        }
    }

    if usernameExists {
        c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
        return
    }

    hashedPassword, err := helpers.HashPassword(req.Password)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
        return
    }

    userID := "USR-" + uuid.New().String()[:8]
    docID := "user::" + userID
    user := models.User{
        DocType:   "user",
        ID:        docID,
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

    _, err = bucket.DefaultCollection().Upsert(docID, user, nil)
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

    query := "SELECT * FROM `" + ac.DB.Config.CouchbaseBucket + "` WHERE docType = 'user' AND email = $email"
    result, err := ac.DB.ExecuteQuery(query, map[string]interface{}{"email": req.Email})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find user"})
        return
    }

    var user models.User
    found := false
    for result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if userData, ok := row[ac.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                user = helpers.MapToUser(userData)
                found = true
            }
        }
    }

    if !found {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
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
        AccessToken:  accessToken,
        RefreshToken: refreshToken,
        User:         user.ToResponse(),
    })
}

func (ac *AuthController) RefreshToken(c *gin.Context) {
    var req struct {
        RefreshToken string `json:"refreshToken" binding:"required"`
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