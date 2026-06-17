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
