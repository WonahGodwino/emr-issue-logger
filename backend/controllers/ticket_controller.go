package controllers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/helpers"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
)

type TicketController struct {
    DB *database.CouchbaseDB
}

func NewTicketController(db *database.CouchbaseDB) *TicketController {
    return &TicketController{DB: db}
}

type CreateTicketRequest struct {
    Title            string                `json:"title" binding:"required,min=5,max=200"`
    Description      string                `json:"description" binding:"required,min=10"`
    Category         models.TicketCategory `json:"category" binding:"required"`
    OrderOfImpact    int                   `json:"orderOfImpact" binding:"required,min=1,max=5"`
    IsNewRequirement bool                  `json:"isNewRequirement"`
}

type UpdateTicketRequest struct {
    Title           string                `json:"title,omitempty"`
    Description     string                `json:"description,omitempty"`
    Category        models.TicketCategory `json:"category,omitempty"`
    OrderOfImpact   int                   `json:"orderOfImpact,omitempty"`
    Status          models.TicketStatus   `json:"status,omitempty"`
    ResolutionNotes string                `json:"resolutionNotes,omitempty"`
}

func (tc *TicketController) CreateTicket(c *gin.Context) {
    var req CreateTicketRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, _ := c.Get("user_id")
    col := tc.DB.Bucket.DefaultCollection()

    ticketID := helpers.GenerateTicketID()
    docID := "ticket::" + ticketID

    // Ensure unique ticket ID
    for {
        _, err := col.Get(docID, nil)
        if err != nil {
            break
        }
        ticketID = helpers.GenerateTicketID()
        docID = "ticket::" + ticketID
    }

    ticket := models.Ticket{
        DocType:          "ticket",
        ID:               docID,
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
        CreatedAt:  time.Now(),
        UpdatedAt:  time.Now(),
        IsRecalled: false,
    }

    _, err := col.Upsert(docID, ticket, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create ticket"})
        return
    }

    c.JSON(http.StatusCreated, ticket.ToResponse())
}

func (tc *TicketController) GetTickets(c *gin.Context) {
    userID, _ := c.Get("user_id")
    role, _ := c.Get("role")

    var query string
    var params map[string]interface{}

    if role != "admin" {
        query = "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND reporterUserId = $userID ORDER BY createdAt DESC"
        params = map[string]interface{}{"userID": userID.(string)}
    } else {
        query = "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' ORDER BY createdAt DESC"
        params = map[string]interface{}{}
    }

    result, err := tc.DB.ExecuteQuery(query, params)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tickets"})
        return
    }

    var responses []models.TicketResponse
    for result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if ticketData, ok := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                ticket := helpers.MapToTicket(ticketData)
                responses = append(responses, ticket.ToResponse())
            }
        }
    }

    if responses == nil {
        responses = []models.TicketResponse{}
    }

    c.JSON(http.StatusOK, gin.H{"tickets": responses, "count": len(responses)})
}

func (tc *TicketController) GetTicket(c *gin.Context) {
    ticketID := c.Param("id")
    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, err := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch ticket"})
        return
    }

    if result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if ticketData, ok := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                ticket := helpers.MapToTicket(ticketData)
                c.JSON(http.StatusOK, ticket.ToResponse())
                return
            }
        }
    }

    c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
}

func (tc *TicketController) UpdateTicket(c *gin.Context) {
    ticketID := c.Param("id")
    var req UpdateTicketRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, err := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
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

    ticketData, ok := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    if !ok {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    ticket := helpers.MapToTicket(ticketData)

    userID, _ := c.Get("user_id")
    role, _ := c.Get("role")

    if role != "admin" && ticket.ReporterUserID != userID.(string) {
        c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
        return
    }

    if req.Status != "" && req.Status != ticket.Status {
        ticket.StatusHistory = append(ticket.StatusHistory, models.StatusHistory{
            Status:    req.Status,
            Timestamp: time.Now(),
            UpdatedBy: userID.(string),
            Note:      req.ResolutionNotes,
        })
        ticket.Status = req.Status
        if req.Status == models.StatusResolved {
            now := time.Now()
            ticket.ResolvedAt = &now
        }
    }

    if req.Title != "" {
        ticket.Title = req.Title
    }
    if req.Description != "" {
        ticket.Description = req.Description
    }
    if req.Category != "" {
        ticket.Category = req.Category
    }
    if req.OrderOfImpact > 0 {
        ticket.OrderOfImpact = req.OrderOfImpact
    }
    ticket.UpdatedAt = time.Now()

    col := tc.DB.Bucket.DefaultCollection()
    _, err = col.Upsert(ticket.ID, ticket, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ticket"})
        return
    }

    c.JSON(http.StatusOK, ticket.ToResponse())
}

func (tc *TicketController) DeleteTicket(c *gin.Context) {
    ticketID := c.Param("id")

    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, err := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
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

    ticketData, ok := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    if !ok {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    ticket := helpers.MapToTicket(ticketData)

    if ticket.Status != models.StatusPending {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Only pending tickets can be deleted"})
        return
    }

    col := tc.DB.Bucket.DefaultCollection()
    _, err = col.Remove(ticket.ID, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket deleted successfully"})
}

func (tc *TicketController) RecallTicket(c *gin.Context) {
    ticketID := c.Param("id")
    var req struct {
        Reason string `json:"reason" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, err := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
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

    ticketData, ok := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    if !ok {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    ticket := helpers.MapToTicket(ticketData)

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
        Status:    models.StatusPending,
        Timestamp: now,
        UpdatedBy: userID.(string),
        Note:      "Ticket recalled: " + req.Reason,
    })

    col := tc.DB.Bucket.DefaultCollection()
    _, err = col.Upsert(ticket.ID, ticket, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to recall ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket recalled successfully", "ticket": ticket.ToResponse()})
}