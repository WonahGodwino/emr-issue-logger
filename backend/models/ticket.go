package models

import (
    "time"
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
    Status    TicketStatus `json:"status"`
    Timestamp time.Time    `json:"timestamp"`
    UpdatedBy string       `json:"updatedBy"`
    Note      string       `json:"note,omitempty"`
}

type Ticket struct {
    DocType          string          `json:"docType"`
    ID               string          `json:"id"`
    TicketID         string          `json:"ticketId"`
    Title            string          `json:"title"`
    Description      string          `json:"description"`
    ReporterUserID   string          `json:"reporterUserId"`
    Category         TicketCategory  `json:"category"`
    OrderOfImpact    int             `json:"orderOfImpact"`
    IsNewRequirement bool            `json:"isNewRequirement"`
    Status           TicketStatus    `json:"status"`
    StatusHistory    []StatusHistory `json:"statusHistory"`
    AssignedTo       string          `json:"assignedTo,omitempty"`
    ResolutionNotes  string          `json:"resolutionNotes,omitempty"`
    CreatedAt        time.Time       `json:"createdAt"`
    UpdatedAt        time.Time       `json:"updatedAt"`
    ResolvedAt       *time.Time      `json:"resolvedAt,omitempty"`
    IsRecalled       bool            `json:"isRecalled"`
    RecalledAt       *time.Time      `json:"recalledAt,omitempty"`
    RecallReason     string          `json:"recallReason,omitempty"`
}

type TicketResponse struct {
    ID               string          `json:"id"`
    TicketID         string          `json:"ticketId"`
    Title            string          `json:"title"`
    Description      string          `json:"description"`
    ReporterUserID   string          `json:"reporterUserId"`
    Category         TicketCategory  `json:"category"`
    OrderOfImpact    int             `json:"orderOfImpact"`
    IsNewRequirement bool            `json:"isNewRequirement"`
    Status           TicketStatus    `json:"status"`
    StatusHistory    []StatusHistory `json:"statusHistory"`
    AssignedTo       string          `json:"assignedTo,omitempty"`
    ResolutionNotes  string          `json:"resolutionNotes,omitempty"`
    CreatedAt        time.Time       `json:"createdAt"`
    UpdatedAt        time.Time       `json:"updatedAt"`
    ResolvedAt       *time.Time      `json:"resolvedAt,omitempty"`
    IsRecalled       bool            `json:"isRecalled"`
    RecalledAt       *time.Time      `json:"recalledAt,omitempty"`
    RecallReason     string          `json:"recallReason,omitempty"`
}

func (t *Ticket) ToResponse() TicketResponse {
    return TicketResponse{
        ID:               t.ID,
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