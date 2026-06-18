package controllers

import (
    "fmt"
    "io"
    "net/http"
    "os"
    "path/filepath"
    "strings"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/helpers"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
    "github.com/google/uuid"
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
    Issue            string                `json:"issue" binding:"required"`
    Module           models.TicketModule   `json:"module" binding:"required"`
    FacilityID       string                `json:"facilityId" binding:"required"`
    Category         models.TicketCategory `json:"category" binding:"required"`
    OrderOfImpact    int                   `json:"orderOfImpact" binding:"required,min=1,max=5"`
    IsNewRequirement bool                  `json:"isNewRequirement"`
}

type UpdateTicketRequest struct {
    Title           string                `json:"title,omitempty"`
    Description     string                `json:"description,omitempty"`
    Issue           string                `json:"issue,omitempty"`
    Module          models.TicketModule   `json:"module,omitempty"`
    Category        models.TicketCategory `json:"category,omitempty"`
    OrderOfImpact   int                   `json:"orderOfImpact,omitempty"`
    Status          models.TicketStatus   `json:"status,omitempty"`
    ResolutionNotes string                `json:"resolutionNotes,omitempty"`
}

type UpdateStatusRequest struct {
    Status            models.TicketStatus `json:"status" binding:"required"`
    ResolutionNotes   string              `json:"resolutionNotes"`
    EscalationComment string              `json:"escalationComment"`
}

func (tc *TicketController) CreateTicket(c *gin.Context) {
    var req CreateTicketRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    userID, _ := c.Get("user_id")
    email, _ := c.Get("email")

    // Get user to find their facility
    query := "SELECT u.* FROM `" + tc.DB.Config.CouchbaseBucket + "` AS u WHERE u.docType = 'user' AND u.userId = $userID"
    result, _ := tc.DB.ExecuteQuery(query, map[string]interface{}{"userID": userID.(string)})

    var reporterFacilityID string
    if result != nil && result.Next() {
        var row map[string]interface{}
        if err := result.Row(&row); err == nil {
            if userData, ok := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{}); ok {
                reporterFacilityID = helpers.GetStringFromMap(userData, "facilityId")
            }
        }
    }

    // Use provided facilityId or fallback to user's facility
    facilityID := req.FacilityID
    if facilityID == "" {
        facilityID = reporterFacilityID
    }

    // Get state for this facility
    var stateID string
    if facilityID != "" {
        facQuery := "SELECT f.stateId FROM `" + tc.DB.Config.CouchbaseBucket + "` AS f WHERE f.docType = 'facility' AND f.facilityId = $facID"
        facResult, _ := tc.DB.ExecuteQuery(facQuery, map[string]interface{}{"facID": facilityID})
        if facResult != nil && facResult.Next() {
            var row map[string]interface{}
            if err := facResult.Row(&row); err == nil {
                stateID = helpers.GetStringFromMap(row, "stateId")
            }
        }
    }

    col := tc.DB.Bucket.DefaultCollection()

    ticketID := helpers.GenerateTicketID()
    docID := "ticket::" + ticketID

    for {
        _, err := col.Get(docID, nil)
        if err != nil {
            break
        }
        ticketID = helpers.GenerateTicketID()
        docID = "ticket::" + ticketID
    }

    now := time.Now()
    userIdStr := userID.(string)
    ticket := models.Ticket{
        DocType:          "ticket",
        ID:               docID,
        TicketID:         ticketID,
        Title:            req.Title,
        Description:      req.Description,
        Issue:            req.Issue,
        Module:           req.Module,
        ReporterUserID:   userIdStr,
        FacilityID:       facilityID,
        StateID:          stateID,
        Category:         req.Category,
        OrderOfImpact:    req.OrderOfImpact,
        IsNewRequirement: req.IsNewRequirement,
        Status:           models.StatusPending,
        Screenshots:      []string{},
        StatusHistory: []models.StatusHistory{
            {Status: models.StatusPending, Timestamp: now, UpdatedBy: userIdStr, Note: "Ticket created"},
        },
        CreatedAt:  now,
        CreatedBy:  email.(string),
        UpdatedAt:  now,
        UpdatedBy:  email.(string),
        IsRecalled: false,
    }

    if _, err := col.Upsert(docID, ticket, nil); err != nil {
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
    conditions := []string{"docType = 'ticket'"}

    if role == "user" {
        conditions = append(conditions, "reporterUserId = $userID")
        params = map[string]interface{}{"userID": userID.(string)}
    } else if role == "admin" {
        // Get admin's assigned state IDs
        adminQuery := "SELECT u.stateIds FROM `" + tc.DB.Config.CouchbaseBucket + "` AS u WHERE u.docType = 'user' AND u.userId = $userID"
        adminResult, _ := tc.DB.ExecuteQuery(adminQuery, map[string]interface{}{"userID": userID.(string)})
        var adminStateIDs []string
        if adminResult != nil && adminResult.Next() {
            var row map[string]interface{}
            if err := adminResult.Row(&row); err == nil {
                if raw, ok := row["stateIds"].([]interface{}); ok {
                    for _, s := range raw {
                        if str, ok2 := s.(string); ok2 {
                            adminStateIDs = append(adminStateIDs, str)
                        }
                    }
                }
            }
        }
        if len(adminStateIDs) > 0 {
            placeholders := []string{}
            params = map[string]interface{}{}
            for i, sid := range adminStateIDs {
                key := fmt.Sprintf("stateID%d", i)
                placeholders = append(placeholders, "$"+key)
                params[key] = sid
            }
            conditions = append(conditions, "stateId IN ["+strings.Join(placeholders, ", ")+"]")
        } else {
            // No states assigned — return empty
            c.JSON(http.StatusOK, gin.H{"tickets": []models.TicketResponse{}, "count": 0})
            return
        }
    }

    // Date filters
    if dateFrom := c.Query("dateFrom"); dateFrom != "" {
        conditions = append(conditions, "createdAt >= $dateFrom")
        if params == nil { params = map[string]interface{}{} }
        params["dateFrom"] = dateFrom
    }
    if dateTo := c.Query("dateTo"); dateTo != "" {
        conditions = append(conditions, "createdAt <= $dateTo")
        if params == nil { params = map[string]interface{}{} }
        params["dateTo"] = dateTo
    }
    if statusFilter := c.Query("status"); statusFilter != "" {
        conditions = append(conditions, "status = $statusFilter")
        if params == nil { params = map[string]interface{}{} }
        params["statusFilter"] = statusFilter
    }
    if stateFilter := c.Query("stateId"); stateFilter != "" {
        conditions = append(conditions, "stateId = $stateFilter")
        if params == nil { params = map[string]interface{}{} }
        params["stateFilter"] = stateFilter
    }
    if facilityFilter := c.Query("facilityId"); facilityFilter != "" {
        conditions = append(conditions, "facilityId = $facilityFilter")
        if params == nil { params = map[string]interface{}{} }
        params["facilityFilter"] = facilityFilter
    }

    query = "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE " + strings.Join(conditions, " AND ") + " ORDER BY createdAt DESC"

    if params == nil { params = map[string]interface{}{} }

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
    result, _ := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    var row map[string]interface{}
    result.Row(&row)
    ticketData, _ := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    ticket := helpers.MapToTicket(ticketData)

    userID, _ := c.Get("user_id")
    role, _ := c.Get("role")
    email, _ := c.Get("email")

    if role != "admin" && ticket.ReporterUserID != userID.(string) {
        c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
        return
    }

    if req.Title != "" { ticket.Title = req.Title }
    if req.Description != "" { ticket.Description = req.Description }
    if req.Issue != "" { ticket.Issue = req.Issue }
    if req.Module != "" { ticket.Module = req.Module }
    if req.Category != "" { ticket.Category = req.Category }
    if req.OrderOfImpact > 0 { ticket.OrderOfImpact = req.OrderOfImpact }

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

    ticket.UpdatedAt = time.Now()
    ticket.UpdatedBy = email.(string)

    col := tc.DB.Bucket.DefaultCollection()
    if _, err := col.Upsert(ticket.ID, ticket, nil); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ticket"})
        return
    }
    c.JSON(http.StatusOK, ticket.ToResponse())
}

func (tc *TicketController) UpdateTicketStatus(c *gin.Context) {
    ticketID := c.Param("id")
    var req UpdateStatusRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Validate status transition (admin only)
    role, _ := c.Get("role")
    if role != "admin" && role != "super_admin" {
        c.JSON(http.StatusForbidden, gin.H{"error": "Only admins can update ticket status"})
        return
    }

    validStatuses := map[models.TicketStatus]bool{
        models.StatusUnderReview: true,
        models.StatusInProgress:  true,
        models.StatusResolved:    true,
        models.StatusEscalated:   true,
    }
    if !validStatuses[req.Status] {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Status must be under-review, in-progress, resolved, or escalated"})
        return
    }

    if req.Status == models.StatusEscalated && req.EscalationComment == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Escalation requires a comment"})
        return
    }

    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, _ := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    var row map[string]interface{}
    result.Row(&row)
    ticketData, _ := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    ticket := helpers.MapToTicket(ticketData)

    userID, _ := c.Get("user_id")
    now := time.Now()

    ticket.Status = req.Status
    ticket.UpdatedAt = now
    ticket.UpdatedByAdmin = userID.(string)
    ticket.AdminUpdatedAt = &now

    note := "Status updated to " + string(req.Status)
    if req.ResolutionNotes != "" {
        note = req.ResolutionNotes
        ticket.ResolutionNotes = req.ResolutionNotes
    }
    if req.Status == models.StatusEscalated {
        ticket.EscalationComment = req.EscalationComment
        note = "Escalated: " + req.EscalationComment
    }
    if req.Status == models.StatusResolved {
        ticket.ResolvedAt = &now
    }

    ticket.StatusHistory = append(ticket.StatusHistory, models.StatusHistory{
        Status:    req.Status,
        Timestamp: now,
        UpdatedBy: userID.(string),
        Note:      note,
    })

    col := tc.DB.Bucket.DefaultCollection()
    if _, err := col.Upsert(ticket.ID, ticket, nil); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ticket status"})
        return
    }

    c.JSON(http.StatusOK, ticket.ToResponse())
}

func (tc *TicketController) UploadScreenshot(c *gin.Context) {
    ticketID := c.Param("id")

    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, _ := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    var row map[string]interface{}
    result.Row(&row)
    ticketData, _ := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    ticket := helpers.MapToTicket(ticketData)

    file, header, err := c.Request.FormFile("screenshot")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Screenshot file is required. Use field name 'screenshot'."})
        return
    }
    defer file.Close()

    // Create uploads directory
    uploadDir := "uploads/screenshots"
    os.MkdirAll(uploadDir, 0755)

    ext := filepath.Ext(header.Filename)
    if ext == "" {
        ext = ".png"
    }
    filename := fmt.Sprintf("%s-%s%s", ticketID, uuid.New().String()[:8], ext)
    filePath := filepath.Join(uploadDir, filename)

    f, err := os.Create(filePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save screenshot"})
        return
    }
    defer f.Close()

    if _, err := io.Copy(f, file); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write screenshot"})
        return
    }

    if ticket.Screenshots == nil {
        ticket.Screenshots = []string{}
    }
    screenshotURL := "/uploads/screenshots/" + filename
    ticket.Screenshots = append(ticket.Screenshots, screenshotURL)
    ticket.UpdatedAt = time.Now()

    col := tc.DB.Bucket.DefaultCollection()
    if _, err := col.Upsert(ticket.ID, ticket, nil); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"screenshotUrl": screenshotURL, "ticket": ticket.ToResponse()})
}

func (tc *TicketController) DeleteTicket(c *gin.Context) {
    ticketID := c.Param("id")

    query := "SELECT * FROM `" + tc.DB.Config.CouchbaseBucket + "` WHERE docType = 'ticket' AND ticketId = $ticketID"
    result, _ := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    var row map[string]interface{}
    result.Row(&row)
    ticketData, _ := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    ticket := helpers.MapToTicket(ticketData)

    if ticket.Status != models.StatusPending {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Only pending tickets can be deleted"})
        return
    }

    col := tc.DB.Bucket.DefaultCollection()
    if _, err := col.Remove(ticket.ID, nil); err != nil {
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
    result, _ := tc.DB.ExecuteQuery(query, map[string]interface{}{"ticketID": ticketID})
    if !result.Next() {
        c.JSON(http.StatusNotFound, gin.H{"error": "Ticket not found"})
        return
    }

    var row map[string]interface{}
    result.Row(&row)
    ticketData, _ := row[tc.DB.Config.CouchbaseBucket].(map[string]interface{})
    ticket := helpers.MapToTicket(ticketData)

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
        Status:    ticket.Status,
        Timestamp: now,
        UpdatedBy: userID.(string),
        Note:      "Ticket recalled: " + req.Reason,
    })

    col := tc.DB.Bucket.DefaultCollection()
    if _, err := col.Upsert(ticket.ID, ticket, nil); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to recall ticket"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Ticket recalled successfully", "ticket": ticket.ToResponse()})
}

