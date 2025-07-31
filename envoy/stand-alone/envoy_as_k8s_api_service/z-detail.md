
调用 http://192.168.6.159:9901/clusters 后可观测
最开始我只有  192.168.6.149:6443
可以看到 health_flags 
192.168.6.150
192.168.6.151
都为failed_active_hc, 但envoy还是会转发请求到 failed_active_hc的后端 

```
k8s_cluster_01_api_service::observability_name::k8s_cluster_01_api_service
k8s_cluster_01_api_service::outlier::success_rate_average::-1
k8s_cluster_01_api_service::outlier::success_rate_ejection_threshold::-1
k8s_cluster_01_api_service::outlier::local_origin_success_rate_average::-1
k8s_cluster_01_api_service::outlier::local_origin_success_rate_ejection_threshold::-1
k8s_cluster_01_api_service::default_priority::max_connections::1024
k8s_cluster_01_api_service::default_priority::max_pending_requests::1024
k8s_cluster_01_api_service::default_priority::max_requests::1024
k8s_cluster_01_api_service::default_priority::max_retries::3
k8s_cluster_01_api_service::high_priority::max_connections::1024
k8s_cluster_01_api_service::high_priority::max_pending_requests::1024
k8s_cluster_01_api_service::high_priority::max_requests::1024
k8s_cluster_01_api_service::high_priority::max_retries::3
k8s_cluster_01_api_service::added_via_api::false
k8s_cluster_01_api_service::192.168.6.149:6443::cx_active::2
k8s_cluster_01_api_service::192.168.6.149:6443::cx_connect_fail::0
k8s_cluster_01_api_service::192.168.6.149:6443::cx_total::15
k8s_cluster_01_api_service::192.168.6.149:6443::rq_active::2
k8s_cluster_01_api_service::192.168.6.149:6443::rq_error::0
k8s_cluster_01_api_service::192.168.6.149:6443::rq_success::0
k8s_cluster_01_api_service::192.168.6.149:6443::rq_timeout::0
k8s_cluster_01_api_service::192.168.6.149:6443::rq_total::15
k8s_cluster_01_api_service::192.168.6.149:6443::hostname::
k8s_cluster_01_api_service::192.168.6.149:6443::health_flags::healthy
k8s_cluster_01_api_service::192.168.6.149:6443::weight::1
k8s_cluster_01_api_service::192.168.6.149:6443::region::
k8s_cluster_01_api_service::192.168.6.149:6443::zone::
k8s_cluster_01_api_service::192.168.6.149:6443::sub_zone::
k8s_cluster_01_api_service::192.168.6.149:6443::canary::false
k8s_cluster_01_api_service::192.168.6.149:6443::priority::0
k8s_cluster_01_api_service::192.168.6.149:6443::success_rate::-1
k8s_cluster_01_api_service::192.168.6.149:6443::local_origin_success_rate::-1
k8s_cluster_01_api_service::192.168.6.150:6443::cx_active::0
k8s_cluster_01_api_service::192.168.6.150:6443::cx_connect_fail::14
k8s_cluster_01_api_service::192.168.6.150:6443::cx_total::14
k8s_cluster_01_api_service::192.168.6.150:6443::rq_active::0
k8s_cluster_01_api_service::192.168.6.150:6443::rq_error::0
k8s_cluster_01_api_service::192.168.6.150:6443::rq_success::0
k8s_cluster_01_api_service::192.168.6.150:6443::rq_timeout::0
k8s_cluster_01_api_service::192.168.6.150:6443::rq_total::0
k8s_cluster_01_api_service::192.168.6.150:6443::hostname::
k8s_cluster_01_api_service::192.168.6.150:6443::health_flags::/failed_active_hc
k8s_cluster_01_api_service::192.168.6.150:6443::weight::1
k8s_cluster_01_api_service::192.168.6.150:6443::region::
k8s_cluster_01_api_service::192.168.6.150:6443::zone::
k8s_cluster_01_api_service::192.168.6.150:6443::sub_zone::
k8s_cluster_01_api_service::192.168.6.150:6443::canary::false
k8s_cluster_01_api_service::192.168.6.150:6443::priority::0
k8s_cluster_01_api_service::192.168.6.150:6443::success_rate::-1
k8s_cluster_01_api_service::192.168.6.150:6443::local_origin_success_rate::-1
k8s_cluster_01_api_service::192.168.6.151:6443::cx_active::0
k8s_cluster_01_api_service::192.168.6.151:6443::cx_connect_fail::13
k8s_cluster_01_api_service::192.168.6.151:6443::cx_total::13
k8s_cluster_01_api_service::192.168.6.151:6443::rq_active::0
k8s_cluster_01_api_service::192.168.6.151:6443::rq_error::0
k8s_cluster_01_api_service::192.168.6.151:6443::rq_success::0
k8s_cluster_01_api_service::192.168.6.151:6443::rq_timeout::0
k8s_cluster_01_api_service::192.168.6.151:6443::rq_total::0
k8s_cluster_01_api_service::192.168.6.151:6443::hostname::
k8s_cluster_01_api_service::192.168.6.151:6443::health_flags::/failed_active_hc
k8s_cluster_01_api_service::192.168.6.151:6443::weight::1
k8s_cluster_01_api_service::192.168.6.151:6443::region::
k8s_cluster_01_api_service::192.168.6.151:6443::zone::
k8s_cluster_01_api_service::192.168.6.151:6443::sub_zone::
k8s_cluster_01_api_service::192.168.6.151:6443::canary::false
k8s_cluster_01_api_service::192.168.6.151:6443::priority::0
k8s_cluster_01_api_service::192.168.6.151:6443::success_rate::-1
k8s_cluster_01_api_service::192.168.6.151:6443::local_origin_success_rate::-1
```

看一下剔除节点的配置
```
    outlier_detection:
      # 如果某个后端节点连续出现 5 次网关类故障（如连接被拒绝、连接超时、目标不可达等 TCP 层面异常），则该节点会被临时从负载均衡池中剔除
      consecutive_gateway_failure: 5 
      # 该检测规则的“执行权重”，取值为 0~100，100 表示该规则100%生效（如果设置为 50，表示规则生效概率为50%）
      enforcing_consecutive_gateway_failure: 100 
      # Envoy 每隔 10 秒进行一次异常检测以及恢复检测（也就是多长时间检查一次所有节点的健康和剔除状态）
      interval: 10s 
      # 当节点被剔除后，最短被移出集群的时间为 30 秒（剔除时长）。如果该节点多次反复被剔除，剔除时长会递增（类似指数退避），否则 30 秒后可以被重新加入
      base_ejection_time: 30s 
      # 一次最多能剔除的节点比例为 50%（即集群中最多有一半的节点可以被outlier_detection机制剔除），防止所有节点因误判全部下线导致无法服务。
      max_ejection_percent: 50 
```

原来是被 max_ejection_percent: 50  


在 Envoy 的 outlier_detection（异常实例检测）机制中，以下配置项分别代表不同的检测类型和执行策略，各自有特定含义和差异：

1. consecutive_5xx
表示：连续多少次上游主机返回 5xx 响应（例如 HTTP 500、501、502、503、504、505 等），则会判定该主机为异常，从负载均衡池中逐出。

适用场景：检测服务端应用本身出现的问题或故障。

配合 enforcing_consecutive_5xx 控制实际逐出的概率。

默认相关参数：consecutive_5xx 默认 5 次，enforcing_consecutive_5xx 默认 100%。

2. enforcing_consecutive_5xx
表示：当 consecutive_5xx 检测触发时，实际执行逐出操作的概率百分比（0-100），可以慢慢加大逐出力度用于灰度或者调试。

举例：设置为 100 即每次触发都逐出，设置为 50 即 50% 概率逐出。

3. consecutive_gateway_failure
表示：连续多少次发生“网关失败”时判为异常，典型的 gateway failure 包括 HTTP 502、503、504 这三个状态码（Bad Gateway、Service Unavailable、Gateway Timeout）。

适用场景：通常用于发现上游主机由于网络、负载均衡、服务间通信等导致的不可用问题，而不是应用本身返回 5xx。

默认值一般是 5 次。

4. enforcing_consecutive_gateway_failure
表示：当 consecutive_gateway_failure 触发时，实际执行逐出的概率。和 enforcing_consecutive_5xx 类似，便于灵活控制。

注意：该参数默认为 0，意味着即使触发也不会真正执行逐出操作，需手动调整。

5. consecutive_local_origin_failure
表示：连续多少次本地 envoy 代理发生自发性（local origin）故障，比如：上游连接超时、TCP 重置、ICMP 错误等（不是对端应用返回的错误，而是本地检测出的网络/下层故障）。

只有当 split_external_local_origin_errors 设置为 true 时才生效。

适用场景：用于检测“自身无法和上游通信”的问题，反映更底层的连接异常。

6. enforcing_consecutive_local_origin_failure
表示：当 consecutive_local_origin_failure 触发时，实际执行逐出的概率。

控制方式与上面两个 enforcing_* 保持一致，默认 100%，可灰度调整。

主要区别
consecutive_5xx 检测所有 5xx，偏重于应用端问题；

consecutive_gateway_failure 只检测 502、503、504，专注于传输层/网关相关故障；

consecutive_local_origin_failure 只检测本地 envoy 检测到的“非外部响应类”故障（如网络断开、连接超时）。

三类都配有 enforcing_* 控制实际执行概率，实现平滑、灵活的异常实例剔除。