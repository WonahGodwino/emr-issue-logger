package controllers

import (
    "encoding/csv"
    "fmt"
    "net/http"
    "strings"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/WonahGodwino/emr-issue-logger/backend/database"
    "github.com/WonahGodwino/emr-issue-logger/backend/models"
)

type StateFacilityController struct {
    DB *database.CouchbaseDB
}

func NewStateFacilityController(db *database.CouchbaseDB) *StateFacilityController {
    return &StateFacilityController{DB: db}
}

// ───────────────────────── STATES ─────────────────────────

type CreateStateRequest struct {
    Name string `json:"name" binding:"required"`
    Code string `json:"code" binding:"required"`
}

func (sfc *StateFacilityController) CreateState(c *gin.Context) {
    var req CreateStateRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    stateID := fmt.Sprintf("ST-%d", time.Now().UnixMilli())
    state := models.State{
        DocType:   "state",
        ID:        "state::" + stateID,
        StateID:   stateID,
        Name:      req.Name,
        Code:      req.Code,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
    }

    col := sfc.DB.Bucket.DefaultCollection()
    if _, err := col.Insert(state.ID, state, nil); err != nil {
        c.JSON(http.StatusConflict, gin.H{"error": "State with this code may already exist: " + err.Error()})
        return
    }

    c.JSON(http.StatusCreated, state)
}

func (sfc *StateFacilityController) GetStates(c *gin.Context) {
    query := "SELECT s.* FROM `" + sfc.DB.Config.CouchbaseBucket + "` AS s WHERE s.docType = 'state' ORDER BY s.name ASC"
    result, err := sfc.DB.ExecuteQuery(query, nil)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch states"})
        return
    }

    states := []models.State{}
    for result.Next() {
        var state models.State
        if err := result.Row(&state); err == nil {
            states = append(states, state)
        }
    }
    if states == nil {
        states = []models.State{}
    }
    c.JSON(http.StatusOK, states)
}

func (sfc *StateFacilityController) UpdateState(c *gin.Context) {
    stateID := c.Param("stateId")

    var req CreateStateRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    col := sfc.DB.Bucket.DefaultCollection()
    getResult, err := col.Get("state::"+stateID, nil)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "State not found"})
        return
    }

    var state models.State
    if err := getResult.Content(&state); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read state"})
        return
    }

    state.Name = req.Name
    state.Code = req.Code
    state.UpdatedAt = time.Now()

    if _, err := col.Replace(state.ID, state, nil); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update state"})
        return
    }

    c.JSON(http.StatusOK, state)
}

func (sfc *StateFacilityController) DeleteState(c *gin.Context) {
    stateID := c.Param("stateId")
    docID := "state::" + stateID

    col := sfc.DB.Bucket.DefaultCollection()

    // Delete all facilities under this state
    facQuery := "SELECT f.id FROM `" + sfc.DB.Config.CouchbaseBucket + "` AS f WHERE f.docType = 'facility' AND f.stateId = $stateID"
    facResult, _ := sfc.DB.ExecuteQuery(facQuery, map[string]interface{}{"stateID": stateID})
    if facResult != nil {
        for facResult.Next() {
            var row map[string]interface{}
            if err := facResult.Row(&row); err == nil {
                if id, ok := row["id"].(string); ok {
                    col.Remove(id, nil)
                }
            }
        }
    }

    if _, err := col.Remove(docID, nil); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "State not found"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "State and all associated facilities deleted"})
}

// ─────────────────────── FACILITIES ───────────────────────

type CreateFacilityRequest struct {
    Name string `json:"name" binding:"required"`
    Code string `json:"code" binding:"required"`
    Type string `json:"type" binding:"required"`
    LGA  string `json:"lga"`
}

func (sfc *StateFacilityController) CreateFacility(c *gin.Context) {
    stateID := c.Param("stateId")

    col := sfc.DB.Bucket.DefaultCollection()
    if _, err := col.Get("state::"+stateID, nil); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "State not found"})
        return
    }

    var req CreateFacilityRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    facilityID := fmt.Sprintf("FC-%d", time.Now().UnixMilli())
    facility := models.Facility{
        DocType:    "facility",
        ID:         "facility::" + facilityID,
        FacilityID: facilityID,
        StateID:    stateID,
        Name:       req.Name,
        Code:       req.Code,
        Type:       req.Type,
        LGA:        req.LGA,
        CreatedAt:  time.Now(),
        UpdatedAt:  time.Now(),
    }

    if _, err := col.Insert(facility.ID, facility, nil); err != nil {
        c.JSON(http.StatusConflict, gin.H{"error": "Failed to create facility: " + err.Error()})
        return
    }

    c.JSON(http.StatusCreated, facility)
}

func (sfc *StateFacilityController) GetFacilities(c *gin.Context) {
    stateID := c.Param("stateId")

    query := "SELECT f.* FROM `" + sfc.DB.Config.CouchbaseBucket + "` AS f WHERE f.docType = 'facility' AND f.stateId = $stateID ORDER BY f.name ASC"
    result, err := sfc.DB.ExecuteQuery(query, map[string]interface{}{"stateID": stateID})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch facilities"})
        return
    }

    facilities := []models.Facility{}
    for result.Next() {
        var facility models.Facility
        if err := result.Row(&facility); err == nil {
            facilities = append(facilities, facility)
        }
    }
    if facilities == nil {
        facilities = []models.Facility{}
    }
    c.JSON(http.StatusOK, facilities)
}

func (sfc *StateFacilityController) UpdateFacility(c *gin.Context) {
    facilityID := c.Param("facilityId")

    var req CreateFacilityRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    col := sfc.DB.Bucket.DefaultCollection()
    getResult, err := col.Get("facility::"+facilityID, nil)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Facility not found"})
        return
    }

    var facility models.Facility
    if err := getResult.Content(&facility); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read facility"})
        return
    }

    facility.Name = req.Name
    facility.Code = req.Code
    facility.Type = req.Type
    facility.LGA = req.LGA
    facility.UpdatedAt = time.Now()

    if _, err := col.Replace(facility.ID, facility, nil); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update facility"})
        return
    }

    c.JSON(http.StatusOK, facility)
}

func (sfc *StateFacilityController) DeleteFacility(c *gin.Context) {
    facilityID := c.Param("facilityId")
    col := sfc.DB.Bucket.DefaultCollection()

    if _, err := col.Remove("facility::"+facilityID, nil); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Facility not found"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Facility deleted"})
}

// ─────────────────────── BULK JSON UPLOAD ───────────────────────

type BulkFacilityEntry struct {
    Name string `json:"name" binding:"required"`
    Code string `json:"code" binding:"required"`
    Type string `json:"type" binding:"required"`
    LGA  string `json:"lga"`
}

type BulkUploadRequest struct {
    Facilities []BulkFacilityEntry `json:"facilities" binding:"required"`
}

func (sfc *StateFacilityController) BulkUploadFacilities(c *gin.Context) {
    stateID := c.Param("stateId")

    col := sfc.DB.Bucket.DefaultCollection()
    if _, err := col.Get("state::"+stateID, nil); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "State not found"})
        return
    }

    var req BulkUploadRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    created := []models.Facility{}
    failed := []gin.H{}

    for i, entry := range req.Facilities {
        facilityID := fmt.Sprintf("FC-%d-%d", time.Now().UnixMilli(), i)
        facility := models.Facility{
            DocType:    "facility",
            ID:         "facility::" + facilityID,
            FacilityID: facilityID,
            StateID:    stateID,
            Name:       entry.Name,
            Code:       entry.Code,
            Type:       entry.Type,
            LGA:        entry.LGA,
            CreatedAt:  time.Now(),
            UpdatedAt:  time.Now(),
        }

        if _, err := col.Insert(facility.ID, facility, nil); err != nil {
            failed = append(failed, gin.H{"name": entry.Name, "error": err.Error()})
        } else {
            created = append(created, facility)
        }
    }

    c.JSON(http.StatusOK, gin.H{
        "created": len(created),
        "failed":  len(failed),
        "details": gin.H{
            "createdList": created,
            "failedList":  failed,
        },
    })
}

// ─────────────────────── CSV TEMPLATE DOWNLOAD ───────────────────────

func (sfc *StateFacilityController) DownloadCSVTemplate(c *gin.Context) {
    c.Header("Content-Type", "text/csv")
    c.Header("Content-Disposition", "attachment; filename=facilities_template.csv")

    writer := csv.NewWriter(c.Writer)
    writer.Write([]string{"name", "code", "type", "lga"})
    writer.Write([]string{"General Hospital Ikeja", "GHI-001", "hospital", "Ikeja"})
    writer.Write([]string{"Lagos Clinic Apapa", "LCA-002", "clinic", "Apapa"})
    writer.Flush()
}

// ─────────────────────── CSV BULK UPLOAD ───────────────────────

func (sfc *StateFacilityController) BulkUploadCSV(c *gin.Context) {
    stateID := c.Param("stateId")

    col := sfc.DB.Bucket.DefaultCollection()
    if _, err := col.Get("state::"+stateID, nil); err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "State not found"})
        return
    }

    file, _, err := c.Request.FormFile("file")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "CSV file is required. Use field name 'file'."})
        return
    }
    defer file.Close()

    reader := csv.NewReader(file)
    reader.TrimLeadingSpace = true

    records, err := reader.ReadAll()
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse CSV: " + err.Error()})
        return
    }

    if len(records) < 2 {
        c.JSON(http.StatusBadRequest, gin.H{"error": "CSV must have a header row and at least one data row"})
        return
    }

    // Parse header to find column indexes
    header := records[0]
    colIdx := map[string]int{}
    for i, h := range header {
        colIdx[strings.ToLower(strings.TrimSpace(h))] = i
    }

    nameIdx, ok1 := colIdx["name"]
    codeIdx, ok2 := colIdx["code"]
    typeIdx, ok3 := colIdx["type"]
    if !ok1 || !ok2 || !ok3 {
        c.JSON(http.StatusBadRequest, gin.H{"error": "CSV must have 'name', 'code', and 'type' columns"})
        return
    }
    lgaIdx, hasLga := colIdx["lga"]

    created := []models.Facility{}
    failed := []gin.H{}

    for i, row := range records[1:] {
        if len(row) <= nameIdx || len(row) <= codeIdx || len(row) <= typeIdx {
            failed = append(failed, gin.H{"row": i + 2, "error": "incomplete row"})
            continue
        }

        name := strings.TrimSpace(row[nameIdx])
        code := strings.TrimSpace(row[codeIdx])
        facType := strings.TrimSpace(row[typeIdx])
        lga := ""
        if hasLga && len(row) > lgaIdx {
            lga = strings.TrimSpace(row[lgaIdx])
        }

        if name == "" || code == "" || facType == "" {
            failed = append(failed, gin.H{"row": i + 2, "name": name, "error": "name, code, and type are required"})
            continue
        }

        facilityID := fmt.Sprintf("FC-%d-%d", time.Now().UnixMilli(), i)
        facility := models.Facility{
            DocType:    "facility",
            ID:         "facility::" + facilityID,
            FacilityID: facilityID,
            StateID:    stateID,
            Name:       name,
            Code:       code,
            Type:       facType,
            LGA:        lga,
            CreatedAt:  time.Now(),
            UpdatedAt:  time.Now(),
        }

        if _, err := col.Insert(facility.ID, facility, nil); err != nil {
            failed = append(failed, gin.H{"row": i + 2, "name": name, "error": err.Error()})
        } else {
            created = append(created, facility)
        }
    }

    c.JSON(http.StatusOK, gin.H{
        "total":   len(records) - 1,
        "created": len(created),
        "failed":  len(failed),
        "details": gin.H{
            "createdList": created,
            "failedList":  failed,
        },
    })
}