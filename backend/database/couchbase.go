package database

import (
    "context"
    "log"
    "time"

    "github.com/couchbase/gocb/v2"
    "github.com/WonahGodwino/emr-issue-logger/backend/config"
)

type CouchbaseDB struct {
    Cluster *gocb.Cluster
    Bucket  *gocb.Bucket
    Config  *config.Config
}

func NewCouchbaseDB(cfg *config.Config) *CouchbaseDB {
    clusterOpts := gocb.ClusterOptions{
        Authenticator: gocb.PasswordAuthenticator{
            Username: cfg.CouchbaseUsername,
            Password: cfg.CouchbasePassword,
        },
    }

    cluster, err := gocb.Connect(cfg.CouchbaseEndpoint, clusterOpts)
    if err != nil {
        log.Fatalf("Failed to connect to Couchbase: %v", err)
    }

    bucket := cluster.Bucket(cfg.CouchbaseBucket)
    err = bucket.WaitUntilReady(30*time.Second, nil)
    if err != nil {
        log.Fatalf("Failed to connect to bucket: %v", err)
    }

    log.Println("Connected to Couchbase successfully")

    return &CouchbaseDB{
        Cluster: cluster,
        Bucket:  bucket,
        Config:  cfg,
    }
}

func (cb *CouchbaseDB) Close() {
    if cb.Cluster != nil {
        cb.Cluster.Close(nil)
    }
}

func (cb *CouchbaseDB) ExecuteQuery(query string, params map[string]interface{}) (*gocb.QueryResult, error) {
    opts := &gocb.QueryOptions{
        Adhoc:                true,
        NamedParameters:      params,
        ScanConsistency:      gocb.QueryScanConsistencyRequestPlus,
    }
    return cb.Cluster.Query(query, opts)
}

func (cb *CouchbaseDB) EnsurePrimaryIndexes(ctx context.Context) error {
    queries := []string{
        "CREATE PRIMARY INDEX IF NOT EXISTS ON `" + cb.Config.CouchbaseBucket + "`",
    }

    for _, q := range queries {
        _, err := cb.Cluster.Query(q, &gocb.QueryOptions{
            Adhoc: true,
        })
        if err != nil {
            log.Printf("Warning: Failed to create primary index: %v", err)
        }
    }

    log.Println("Primary indexes ensured")
    return nil
}

func (cb *CouchbaseDB) CreateIndexes(ctx context.Context) error {
    indexes := []string{
        "CREATE INDEX IF NOT EXISTS idx_users_email ON `" + cb.Config.CouchbaseBucket + "`(email) WHERE docType = 'user'",
        "CREATE INDEX IF NOT EXISTS idx_users_username ON `" + cb.Config.CouchbaseBucket + "`(username) WHERE docType = 'user'",
        "CREATE INDEX IF NOT EXISTS idx_users_userid ON `" + cb.Config.CouchbaseBucket + "`(userId) WHERE docType = 'user'",
        "CREATE INDEX IF NOT EXISTS idx_users_role ON `" + cb.Config.CouchbaseBucket + "`(`role`) WHERE docType = 'user'",
        "CREATE INDEX IF NOT EXISTS idx_tickets_ticketid ON `" + cb.Config.CouchbaseBucket + "`(ticketId) WHERE docType = 'ticket'",
        "CREATE INDEX IF NOT EXISTS idx_tickets_reporter ON `" + cb.Config.CouchbaseBucket + "`(reporterUserId) WHERE docType = 'ticket'",
        "CREATE INDEX IF NOT EXISTS idx_tickets_status ON `" + cb.Config.CouchbaseBucket + "`(status) WHERE docType = 'ticket'",
        "CREATE INDEX IF NOT EXISTS idx_tickets_category ON `" + cb.Config.CouchbaseBucket + "`(category) WHERE docType = 'ticket'",
        "CREATE INDEX IF NOT EXISTS idx_tickets_created ON `" + cb.Config.CouchbaseBucket + "`(createdAt DESC) WHERE docType = 'ticket'",
        "CREATE INDEX IF NOT EXISTS idx_states_stateid ON `" + cb.Config.CouchbaseBucket + "`(stateId) WHERE docType = 'state'",
        "CREATE INDEX IF NOT EXISTS idx_states_code ON `" + cb.Config.CouchbaseBucket + "`(code) WHERE docType = 'state'",
        "CREATE INDEX IF NOT EXISTS idx_facilities_facilityid ON `" + cb.Config.CouchbaseBucket + "`(facilityId) WHERE docType = 'facility'",
        "CREATE INDEX IF NOT EXISTS idx_facilities_stateid ON `" + cb.Config.CouchbaseBucket + "`(stateId) WHERE docType = 'facility'",
    }

    for _, idx := range indexes {
        _, err := cb.Cluster.Query(idx, &gocb.QueryOptions{
            Adhoc: true,
        })
        if err != nil {
            log.Printf("Warning: Failed to create index: %v", err)
        }
    }

    log.Println("Secondary indexes ensured")
    return nil
}