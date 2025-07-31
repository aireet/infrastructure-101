package main

import (
	"context"
	"encoding/json"
	"log"
	"net"
	"net/http"
	"sync"
	"time"

	discovery "github.com/envoyproxy/go-control-plane/envoy/service/discovery/v3"
	"github.com/envoyproxy/go-control-plane/pkg/cache/v3"
	"github.com/envoyproxy/go-control-plane/pkg/server/v3"
	"google.golang.org/grpc"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/reflection"
)

type Endpoint struct {
	Address string `json:"address"`
	Port    uint32 `json:"port"`
}

type EndpointManager struct {
	endpoints map[string]Endpoint
	mu        sync.RWMutex
	cache     cache.SnapshotCache
}

func NewEndpointManager() *EndpointManager {
	return &EndpointManager{
		endpoints: make(map[string]Endpoint),
		cache:     cache.NewSnapshotCache(false, cache.IDHash{}, nil),
	}
}

func (em *EndpointManager) AddEndpoint(id string, endpoint Endpoint) {
	em.mu.Lock()
	defer em.mu.Unlock()
	em.endpoints[id] = endpoint
	em.updateSnapshot()
}

func (em *EndpointManager) RemoveEndpoint(id string) {
	em.mu.Lock()
	defer em.mu.Unlock()
	delete(em.endpoints, id)
	em.updateSnapshot()
}

func (em *EndpointManager) ListEndpoints() map[string]Endpoint {
	em.mu.RLock()
	defer em.mu.RUnlock()
	result := make(map[string]Endpoint)
	for k, v := range em.endpoints {
		result[k] = v
	}
	return result
}

func (em *EndpointManager) updateSnapshot() {
	// 创建 endpoints
	var lbEndpoints []cache.Resource
	for id, endpoint := range em.endpoints {
		lbEndpoint := &discovery.Endpoint{
			Address: &discovery.Address{
				Address: &discovery.Address_SocketAddress{
					SocketAddress: &discovery.SocketAddress{
						Address: endpoint.Address,
						PortSpecifier: &discovery.SocketAddress_PortValue{
							PortValue: endpoint.Port,
						},
					},
				},
			},
		}
		lbEndpoints = append(lbEndpoints, lbEndpoint)
	}

	// 创建 cluster load assignment
	cla := &discovery.ClusterLoadAssignment{
		ClusterName: "k8s_cluster_01_api_service",
		Endpoints: []*discovery.LocalityLbEndpoints{
			{
				LbEndpoints: lbEndpoints,
			},
		},
	}

	// 创建快照
	snapshot := cache.NewSnapshot("1", nil, nil, []cache.Resource{cla}, nil, nil)

	// 更新缓存
	err := em.cache.SetSnapshot(context.Background(), "default", snapshot)
	if err != nil {
		log.Printf("Failed to set snapshot: %v", err)
	}
}

func main() {
	em := NewEndpointManager()

	// 添加默认 endpoint
	em.AddEndpoint("default", Endpoint{
		Address: "192.168.6.149",
		Port:    6443,
	})

	// 启动 gRPC 服务器
	go func() {
		grpcServer := grpc.NewServer(
			grpc.KeepaliveParams(keepalive.ServerParameters{
				MaxConnectionIdle: 5 * time.Minute,
				MaxConnectionAge:  10 * time.Minute,
				Time:              30 * time.Second,
				Timeout:           5 * time.Second,
			}),
		)

		// 注册 xDS 服务
		srv := server.NewServer(context.Background(), em.cache, nil)
		discovery.RegisterAggregatedDiscoveryServiceServer(grpcServer, srv)
		reflection.Register(grpcServer)

		lis, err := net.Listen("tcp", ":18000")
		if err != nil {
			log.Fatalf("Failed to listen: %v", err)
		}

		log.Printf("Starting gRPC server on :18000")
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("Failed to serve: %v", err)
		}
	}()

	// 启动 HTTP API 服务器
	http.HandleFunc("/endpoints", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		switch r.Method {
		case "GET":
			endpoints := em.ListEndpoints()
			json.NewEncoder(w).Encode(endpoints)

		case "POST":
			var endpoint Endpoint
			if err := json.NewDecoder(r.Body).Decode(&endpoint); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}

			id := r.URL.Query().Get("id")
			if id == "" {
				http.Error(w, "id parameter is required", http.StatusBadRequest)
				return
			}

			em.AddEndpoint(id, endpoint)
			w.WriteHeader(http.StatusCreated)

		case "DELETE":
			id := r.URL.Query().Get("id")
			if id == "" {
				http.Error(w, "id parameter is required", http.StatusBadRequest)
				return
			}

			em.RemoveEndpoint(id)
			w.WriteHeader(http.StatusNoContent)
		}
	})

	log.Printf("Starting HTTP server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
