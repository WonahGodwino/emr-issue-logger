package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/config"
    "github.com/WonahGodwino/emr-issue-logger/backend/helpers"
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
        if !exists {
            c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
            c.Abort()
            return
        }
        roleStr := role.(string)
        if roleStr != "admin" && roleStr != "super_admin" {
            c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
            c.Abort()
            return
        }
        c.Next()
    }
}

func SuperAdminMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        role, exists := c.Get("role")
        if !exists || role != "super_admin" {
            c.JSON(http.StatusForbidden, gin.H{"error": "Super admin access required"})
            c.Abort()
            return
        }
        c.Next()
    }
}