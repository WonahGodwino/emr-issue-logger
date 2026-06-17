package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/helpers"
)

type UserController struct {
    DB *database.CouchbaseDB
}

func NewUserController(db *database.CouchbaseDB) *UserController {
    return &UserController{DB: db}
}

type UpdateProfileRequest struct {
    FullName string `json:"fullName,omitempty"`
    Username string `json:"username,omitempty"`
}

func (uc *UserController) GetCurrentUser(c *gin.Context) {
    userID, _ := c.Get("user_id")

    query := "SELECT * FROM `" + uc.DB.Config.CouchbaseBucket + "` WHERE docType = 'user' AND userId = $userID"
    result, err := uc.DB.ExecuteQuery(query, map[string]interface{}{"userID": userID})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find user"})
        return
    }

    if result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if userData, ok := row[uc.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                user := helpers.MapToUser(userData)
                c.JSON(http.StatusOK, user.ToResponse())
                return
            }
        }
    }

    c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
}

func (uc *UserController) UpdateProfile(c *gin.Context) {
    var req UpdateProfileRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, _ := c.Get("user_id")

    query := "SELECT * FROM `" + uc.DB.Config.CouchbaseBucket + "` WHERE docType = 'user' AND userId = $userID"
    result, err := uc.DB.ExecuteQuery(query, map[string]interface{}{"userID": userID})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find user"})
        return
    }

    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
        return
    }

    var row map[string]interface{}
    if err := result.Row(&row); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
        return
    }

    userData, ok := row[uc.DB.Config.CouchbaseBucket].(map[string]interface{})
    if !ok {
        c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
        return
    }

    user := helpers.MapToUser(userData)

    if req.FullName != "" {
        user.FullName = req.FullName
    }
    if req.Username != "" {
        user.Username = req.Username
    }
    user.UpdatedAt = time.Now()

    col := uc.DB.Bucket.DefaultCollection()
    _, err = col.Upsert(user.ID, user, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Profile updated successfully", "user": user.ToResponse()})
}