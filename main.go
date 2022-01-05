package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"time"

	"github.com/jackc/pgx/v4"
)

func main() {
	ctxParent, cancelMain := context.WithCancel(context.Background())
	// Interrupt Ctrl+C
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	go func() {
		for sig := range c {
			// sig is a ^C, handle it
			_ = sig
			fmt.Println("[Main] Receive Ctrl+C! Canceled main context!")
			cancelMain()
			break
		}
	}()
	// urlExample := ""
	connInfo := "postgres://user:123qwe@172.17.0.2:5432/iot_jobs"
	iotDB, err := pgx.Connect(ctxParent, connInfo)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer iotDB.Close(ctxParent)

	ctxSubscriber, cancel := context.WithCancel(ctxParent)
	defer cancel()

	connPq := "host=172.17.0.2 port=5432 user=user password=123qwe dbname=iot_jobs sslmode=disable"
	subscriber := NewSubscriber(ctxSubscriber, connPq)
	chGetRequest, err := subscriber.Listen("req_jobs_status_channel")
	if err != nil {
		cancelMain()
		os.Exit(1)
	}

	fmt.Println(time.Now().String() + " Start monitoring requests from PostgreSQL...")

	for req := range chGetRequest {
		fmt.Printf("[%s] Receive request id:%v", time.Now().String(), req.(string))
		query := fmt.Sprintf(`UPDATE req_jobs SET status='processing'
			WHERE id = %s AND status='new' RETURNING *;`, req.(string))
		var (
			request_id         int
			request_time       time.Time
			request_data       string
			status             string
			status_update_time time.Time
		)
		errRow := iotDB.QueryRow(ctxParent, query).Scan(
			&request_id,
			&request_time,
			&request_data,
			&status,
			&status_update_time,
		)
		if errRow != nil {
			fmt.Printf("[%s] Error when update status! Err:%v Query: %s \n",
				time.Now().String(), errRow, query)
		} else {
			fmt.Printf("[%s] Update status! Request_id: %v \n",
				time.Now().String(), request_id)
		}
	}
	os.Exit(0)
}
