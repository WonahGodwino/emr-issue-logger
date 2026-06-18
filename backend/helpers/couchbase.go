package helpers

import (
    "time"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
)

func GetIntFromMap(m map[string]interface{}, key string) int {
    if val, ok := m[key]; ok {
        switch v := val.(type) {
        case float64:
            return int(v)
        case int64:
            return int(v)
        case int:
            return v
        }
    }
    return 0
}

func GetStringFromMap(m map[string]interface{}, key string) string {
    return getString(m, key)
}

func MapToUser(m map[string]interface{}) models.User {
    stateIDs := []string{}
    if raw, ok := m["stateIds"].([]interface{}); ok {
        for _, s := range raw {
            if str, ok2 := s.(string); ok2 {
                stateIDs = append(stateIDs, str)
            }
        }
    }
    return models.User{
        DocType:    getString(m, "docType"),
        ID:         getString(m, "id"),
        UserID:     getString(m, "userId"),
        Username:   getString(m, "username"),
        Email:      getString(m, "email"),
        Password:   getString(m, "password"),
        FullName:   getString(m, "fullName"),
        Role:       models.UserRole(getString(m, "role")),
        StateIDs:   stateIDs,
        FacilityID: getString(m, "facilityId"),
        CreatedAt:  getTime(m, "createdAt"),
        UpdatedAt:  getTime(m, "updatedAt"),
        IsActive:   getBool(m, "isActive"),
    }
}

func MapToTicket(m map[string]interface{}) models.Ticket {
    statusHistory := []models.StatusHistory{}
    if sh, ok := m["statusHistory"].([]interface{}); ok {
        for _, item := range sh {
            if shMap, ok2 := item.(map[string]interface{}); ok2 {
                statusHistory = append(statusHistory, models.StatusHistory{
                    Status:    models.TicketStatus(getString(shMap, "status")),
                    Timestamp: getTime(shMap, "timestamp"),
                    UpdatedBy: getString(shMap, "updatedBy"),
                    Note:      getString(shMap, "note"),
                })
            }
        }
    }

    screenshots := []string{}
    if raw, ok := m["screenshots"].([]interface{}); ok {
        for _, s := range raw {
            if str, ok2 := s.(string); ok2 {
                screenshots = append(screenshots, str)
            }
        }
    }

    return models.Ticket{
        DocType:           getString(m, "docType"),
        ID:                getString(m, "id"),
        TicketID:          getString(m, "ticketId"),
        Title:             getString(m, "title"),
        Description:       getString(m, "description"),
        Issue:             getString(m, "issue"),
        Module:            models.TicketModule(getString(m, "module")),
        ReporterUserID:    getString(m, "reporterUserId"),
        FacilityID:        getString(m, "facilityId"),
        StateID:           getString(m, "stateId"),
        Category:          models.TicketCategory(getString(m, "category")),
        OrderOfImpact:     GetIntFromMap(m, "orderOfImpact"),
        IsNewRequirement:  getBool(m, "isNewRequirement"),
        Status:            models.TicketStatus(getString(m, "status")),
        StatusHistory:     statusHistory,
        AssignedTo:        getString(m, "assignedTo"),
        ResolutionNotes:   getString(m, "resolutionNotes"),
        EscalationComment: getString(m, "escalationComment"),
        Screenshots:       screenshots,
        CreatedAt:         getTime(m, "createdAt"),
        CreatedBy:         getString(m, "createdBy"),
        UpdatedAt:         getTime(m, "updatedAt"),
        UpdatedBy:         getString(m, "updatedBy"),
        AdminUpdatedAt:    getTimePtr(m, "adminUpdatedAt"),
        UpdatedByAdmin:    getString(m, "updatedByAdmin"),
        ResolvedAt:        getTimePtr(m, "resolvedAt"),
        IsRecalled:        getBool(m, "isRecalled"),
        RecalledAt:        getTimePtr(m, "recalledAt"),
        RecallReason:      getString(m, "recallReason"),
    }
}

func getString(m map[string]interface{}, key string) string {
    if val, ok := m[key]; ok {
        if s, ok2 := val.(string); ok2 {
            return s
        }
    }
    return ""
}

func getBool(m map[string]interface{}, key string) bool {
    if val, ok := m[key]; ok {
        if b, ok2 := val.(bool); ok2 {
            return b
        }
    }
    return false
}

func getTime(m map[string]interface{}, key string) time.Time {
    if val, ok := m[key]; ok {
        if t, ok2 := val.(time.Time); ok2 {
            return t
        }
        if s, ok2 := val.(string); ok2 {
           	t, err := time.Parse(time.RFC3339, s)
            if err == nil {
                return t
            }
        }
    }
    return time.Time{}
}

func getTimePtr(m map[string]interface{}, key string) *time.Time {
    if val, ok := m[key]; ok {
        if t, ok2 := val.(time.Time); ok2 {
            return &t
        }
        if s, ok2 := val.(string); ok2 {
            t, err := time.Parse(time.RFC3339, s)
            if err == nil {
                return &t
            }
        }
    }
    return nil
}