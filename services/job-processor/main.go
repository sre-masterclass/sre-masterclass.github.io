package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

var (
	jobsProcessed = promauto.NewCounter(prometheus.CounterOpts{
		Name: "job_processor_jobs_processed_total",
		Help: "The total number of processed jobs",
	})
	jobsThroughput = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "job_processor_throughput_jobs_per_second",
		Help: "Number of jobs processed per second.",
	})
)

var (
	entropyState = struct {
		sync.RWMutex
		latency    time.Duration
		errorRate  float64
	}{
		latency:   0,
		errorRate: 0,
	}
	ctx = context.Background()
)

type LatencyPayload struct {
	Latency float64 `json:"latency"`
}

type ErrorRatePayload struct {
	ErrorRate float64 `json:"error_rate"`
}

func entropyMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		entropyState.RLock()
		latency := entropyState.latency
		errorRate := entropyState.errorRate
		entropyState.RUnlock()

		// Introduce latency
		if latency > 0 {
			time.Sleep(latency)
		}

		// Introduce errors
		if rand.Float64() < errorRate {
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})

	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "redis:6379"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	go processJobs(rdb)

	http.Handle("/", entropyMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, Job Processor!")
	})))
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	})

	http.Handle("/metrics", promhttp.Handler())

	http.HandleFunc("/entropy/latency", func(w http.ResponseWriter, r *http.Request) {
		var payload LatencyPayload
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		entropyState.Lock()
		entropyState.latency = time.Duration(payload.Latency * float64(time.Second))
		entropyState.Unlock()
		fmt.Fprintf(w, "Latency set to %v", entropyState.latency)
	})

	http.HandleFunc("/entropy/errors", func(w http.ResponseWriter, r *http.Request) {
		var payload ErrorRatePayload
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		entropyState.Lock()
		entropyState.errorRate = payload.ErrorRate
		entropyState.Unlock()
		fmt.Fprintf(w, "Error rate set to %v", entropyState.errorRate)
	})

	fmt.Println("Starting server on port 8000")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		panic(err)
	}
}

func processJobs(rdb *redis.Client) {
	log.Info().Msg("Starting job processor")
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	var processedInSecond float64

	go func() {
		for range ticker.C {
			jobsThroughput.Set(processedInSecond)
			processedInSecond = 0
		}
	}()

	for {
		// Wait for the first job
		result, err := rdb.BLPop(ctx, 0, "job-queue").Result()
		if err != nil {
			log.Error().Err(err).Msg("Error receiving job")
			continue
		}

		// Process the first job
		processJob(rdb, result[1])
		processedInSecond++

		// Try to process more jobs in a batch
		for i := 0; i < 9; i++ { // Process up to 10 jobs in a batch
			jobData, err := rdb.LPop(ctx, "job-queue").Result()
			if err == redis.Nil {
				break // No more jobs in the queue
			} else if err != nil {
				log.Error().Err(err).Msg("Error receiving job")
				break
			}
			processJob(rdb, jobData)
			processedInSecond++
		}
	}
}

func processJob(rdb *redis.Client, jobData string) {
	start := time.Now()
	log.Info().Str("job_data", jobData).Msg("Received job")
	// Simulate processing the job
	time.Sleep(100 * time.Millisecond)
	duration := time.Since(start)
	log.Info().Str("job_data", jobData).Float64("duration_ms", float64(duration.Milliseconds())).Msg("Processed job")
	jobsProcessed.Inc()

	// Push to processed queue for test verification
	err := rdb.LPush(ctx, "processed-jobs", jobData).Err()
	if err != nil {
		log.Error().Err(err).Msg("Error pushing to processed queue")
	}
}
