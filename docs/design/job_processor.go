// Background Job Processor
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/go-redis/redis/v8"
)

var ctx = context.Background()

func main() {
	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "redis:6379"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	go processJobs(rdb)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, Job Processor!")
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok"}`))
	})

	fmt.Println("Starting server on port 8000")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		panic(err)
	}
}

func processJobs(rdb *redis.Client) {
	log.Println("Starting job processor")
	for {
		result, err := rdb.BLPop(ctx, 0, "job-queue").Result()
		if err != nil {
			log.Printf("Error receiving job: %v", err)
			continue
		}

		jobData := result[1]
		log.Printf("Received job: %s", jobData)
		// Simulate processing the job
		log.Printf("Processed job: %s", jobData)
	}
}
