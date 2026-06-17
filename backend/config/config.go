package config

import (
    "bytes"
    "log"
    "os"
    "path/filepath"
    "strconv"
    "time"

    "github.com/joho/godotenv"
)

type Config struct {
    Port                  string
    CouchbaseEndpoint     string
    CouchbaseUsername     string
    CouchbasePassword     string
    CouchbaseBucket       string
    JWTSecret             string
    JWTAccessExpiry       time.Duration
    JWTRefreshExpiry      time.Duration
    BcryptCost            int
    CORSAllowedOrigins    []string
    Environment           string
}

func findProjectRoot() string {
    // Start from the executable path (handles go run temp builds)
    if exe, err := os.Executable(); err == nil {
        for dir := filepath.Dir(exe); len(dir) > 3; dir = filepath.Dir(dir) {
            if _, err := os.Stat(filepath.Join(dir, "backend", "go.mod")); err == nil {
                return dir
            }
        }
    }
    // Fallback: start from CWD and walk up
    if cwd, err := os.Getwd(); err == nil {
        for dir := cwd; len(dir) > 3; dir = filepath.Dir(dir) {
            if _, err := os.Stat(filepath.Join(dir, "backend", "go.mod")); err == nil {
                return dir
            }
        }
    }
    return "."
}

func findEnvFile() string {
    root := findProjectRoot()

    candidates := []string{
        // backend/.env relative to project root
        filepath.Join(root, "backend", ".env"),
        // .env at project root
        filepath.Join(root, ".env"),
        // Fallback: current directory
        ".env",
        filepath.Join("backend", ".env"),
    }

    for _, p := range candidates {
        if _, err := os.Stat(p); err == nil {
            log.Printf("Found .env at: %s", p)
            return p
        }
    }

    log.Printf("Searched for .env in: %v", candidates)
    return ".env"
}

func loadEnvFile(path string) error {
    data, err := os.ReadFile(path)
    if err != nil {
        return err
    }
    // Strip UTF-8 BOM if present
    data = bytes.TrimPrefix(data, []byte{0xEF, 0xBB, 0xBF})

    m, err := godotenv.UnmarshalBytes(data)
    if err != nil {
        return err
    }

    for k, v := range m {
        if os.Getenv(k) == "" {
            os.Setenv(k, v)
        }
    }
    return nil
}

func LoadConfig() *Config {
    envFile := findEnvFile()
    if err := loadEnvFile(envFile); err != nil {
        log.Printf("Failed to load .env from %s: %v. Using environment variables.", envFile, err)
    } else {
        log.Printf("Successfully loaded config from %s", envFile)
    }

    accessExpiry, _ := time.ParseDuration(getEnv("JWT_ACCESS_EXPIRY", "15m"))
    refreshExpiry, _ := time.ParseDuration(getEnv("JWT_REFRESH_EXPIRY", "7d"))
    bcryptCost, _ := strconv.Atoi(getEnv("BCRYPT_COST", "12"))

    return &Config{
        Port:               getEnv("PORT", "8080"),
        CouchbaseEndpoint:  getEnv("COUCHBASE_ENDPOINT", "couchbases://your-cluster.cloud.couchbase.com"),
        CouchbaseUsername:  getEnv("COUCHBASE_USERNAME", "your-username"),
        CouchbasePassword:  getEnv("COUCHBASE_PASSWORD", "your-password"),
        CouchbaseBucket:    getEnv("COUCHBASE_BUCKET", "your-bucket"),
        JWTSecret:          getEnv("JWT_SECRET", "default-secret-change-me"),
        JWTAccessExpiry:    accessExpiry,
        JWTRefreshExpiry:   refreshExpiry,
        BcryptCost:         bcryptCost,
        CORSAllowedOrigins: []string{getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:4200")},
        Environment:        getEnv("ENVIRONMENT", "development"),
    }
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}