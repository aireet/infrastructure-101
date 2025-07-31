
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