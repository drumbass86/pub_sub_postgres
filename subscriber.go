package main

import (
	"context"
	"fmt"
	"time"

	"github.com/lib/pq"
)

type DataFromPSQL interface{}

type Subscriber struct {
	ListenerPSQL *pq.Listener
	ChanData     chan DataFromPSQL
	ctx          context.Context
}

func reportErrInListener(event pq.ListenerEventType, err error) {
	if err != nil {
		fmt.Printf("[%s] In event:%v error:%v \n", time.Now().String(), event, err.Error())
	}
}

func NewSubscriber(pctx context.Context, connectInfo string) *Subscriber {
	return &Subscriber{
		ListenerPSQL: pq.NewListener(connectInfo, 10*time.Second, time.Minute,
			reportErrInListener),
		ChanData: nil,
		ctx:      pctx,
	}
}

func (s *Subscriber) onErrorInListener() func(pq.ListenerEventType, error) {
	return func(event pq.ListenerEventType, err error) {
		if err != nil {
			fmt.Printf("[%s] In event:%v error:%v \n", time.Now().String(), event, err.Error())
		}
	}
}

func (s *Subscriber) Listen(psqlchname string) (chan DataFromPSQL, error) {
	err := s.ListenerPSQL.Listen(psqlchname)
	if err != nil {
		return nil, err
	}

	s.ChanData = make(chan DataFromPSQL)

	go func() {
		for req := range s.ListenerPSQL.Notify {
			fmt.Println(time.Now().String(), " Received data from channel [", req.Channel, "] :", req.Extra)
			select {
			case s.ChanData <- req.Extra:
			case <-s.ctx.Done():
				fmt.Println("Receive context.Done")
				return
			}
		}
		close(s.ChanData)
	}()

	return s.ChanData, nil
}
