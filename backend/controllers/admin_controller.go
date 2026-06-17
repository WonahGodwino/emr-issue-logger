package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/helpers"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
)

type AdminController struct {
    DB *database.CouchbaseDB
}

func NewAdminController(db *database.CouchbaseDB) *AdminController {
    return &AdminController{DB: db}
}

func (ac *AdminController) GetDashboardStats(c *gin.Context) {
    bucket := ac.DB.Config.CouchbaseBucket

    queries := map[string]string{
        "totalTickets":      "SELECT COUNT(*) AS cnt FROM `" + bucket + "` WHERE docType = 'ticket'",
        "pendingTickets":    "SELECT COUNT(*) AS cnt FROM `" + bucket + "` WHERE docType = 'ticket' AND status = 'pending'",
        "inProgressTickets": "SELECT COUNT(*) AS cnt FROM `" + bucket + "` WHERE docType = 'ticket' AND status = 'in-progress'",
        "resolvedTickets":   "SELECT COUNT(*) AS cnt FROM `" + bucket + "` WHERE docType = 'ticket' AND status = 'resolved'",
        "totalUsers":        "SELECT COUNT(*) AS cnt FROM `" + bucket + "` WHERE docType = 'user'",
        "recalledTickets":   "SELECT COUNT(*) AS cnt FROM `" + bucket + "` WHERE docType = 'ticket' AND isRecalled = true",
    }

    stats := gin.H{}
    for key, query := range queries {
        result, err := ac.DB.ExecuteQuery(query, nil)
        if err != nil {
            continue
        }
        if result.Next() {
            var row map[string]interface{}
            if err := result.Row(&row); err == nil {
                stats[key] = helpers.GetIntFromMap(row, "cnt")
            }
        } else {
            stats[key] = 0
        }
    }

    c.JSON(http.StatusOK, stats)
}

func (ac *AdminController) GetAllUsers(c *gin.Context) {
    query := "SELECT * FROM `" + ac.DB.Config.CouchbaseBucket + "` WHERE docType = 'user'"
    result, err := ac.DB.ExecuteQuery(query, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
        return
    }

    var responses []models.UserResponse
    for result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if userData, ok := row[ac.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                user := helpers.MapToUser(userData)
                responses = append(responses, user.ToResponse())
            }
        }
    }

    if responses == nil {
        responses = []models.UserResponse{}
    }

    c.JSON(http.StatusOK, responses)
}

func (ac *AdminController) GetAllTickets(c *gin.Context) {
    query := "SELECT * FROM `" + ac.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' ORDER BY createdAt DESC"
    result, err := ac.DB.ExecuteQuery(query, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tickets"})
        return
    }

    var responses []models.TicketResponse
    for result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if ticketData, ok := row[ac.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                ticket := helpers.MapToTicket(ticketData)
                responses = append(responses, ticket.ToResponse())
            }
        }
    }

    if responses == nil {
        responses = []models.TicketResponse{}
    }

    c.JSON(http.StatusOK, responses)
}

func (ac *AdminController) AssignTicket(c *gin.Context) {
    ticketID := c.Param("id")
    var req struct {
        AssignedTo string `json:"assignedTo" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    query := "SELECT * FROM `" + ac.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, err := ac.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find ticket"})
        return
    }

    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    var row map[string]interface{}
    if err := result.Row(&row); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    ticketData, ok := row[ac.DB.Config.CouchbaseBucket].(map[string]interface{})
    if !ok {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    ticket := helpers.MapToTicket(ticketData)
    ticket.AssignedTo = req.AssignedTo
    ticket.UpdatedAt = time.Now()

    col := ac.DB.Bucket.DefaultCollection()
    _, err = col.Upsert(ticket.ID, ticket, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to assign ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket assigned successfully"})
}