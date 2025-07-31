# Envoy 代理教程


istio 的学习曲线时陡峭的, 在学习istio的过程中, 我们应该分成两个东西来学, 一个是envoy,  一个是istio控制面数据面, 但不巧的是, envoy的学习曲线也是陡峭的.


来看看gpt 对比envoy和 nginx 怎么说
```
核心优势概述：

云原生和微服务适配：Envoy为云原生设计，与Kubernetes等容器编排平台深度集成，适合微服务场景下的服务治理和动态流量控制[Nginx更通用，Envoy专注于云原生]。

动态配置和自动化管理：Envoy原生支持动态配置（如通过xDS API），可以实时在线调整路由、策略等，无需重启进程，这对于敏捷开发和持续部署场景极为重要；Nginx的配置主要是静态且层级复杂，灵活性较低。

可扩展性与插件机制：Envoy架构高度模块化，支持自定义过滤器和插件，并暴露了丰富的API，方便与Istio等服务网格控制平面集成；其插件多为动态加载，而Nginx插件需静态编译，扩展点较为有限。

可观测性与治理：Envoy内置全面的监控、日志和分布式追踪功能，指标体系更丰富，有利于问题定位及与AIOps等体系集成；Nginx原生可观测性较弱，仅提供基础日志和指标，需依赖第三方扩展增强。

负载均衡与健康检查：Envoy支持多种复杂负载均衡算法，能够基于服务健康状态动态调整流量分配，灵活性高于Nginx。
```

envoy的功能是丰富且复杂的, 是动态且灵活的, 所以一开始我们先抛开他作为云原生serviceMesh balabala的概念, 我们使用静态配置,用一个最简单常见的例子: 高可用反向代理 来开始第一步envoy之旅

最开始会演示如何使用 Envoy 代理来负载均衡多个 Kubernetes API 服务器的访问。

## 📋 项目概述

本项目提供了完整的 Envoy 代理解决方案教程，包含以下章节：

- **静态配置代理**: 通过静态配置文件实现 K8s API 代理
- **动态配置代理**: 通过 XDS 控制平面实现动态配置管理



## 📚 教程章节

### 1. [静态配置代理](./stand-alone/envoy_as_k8s_api_service/)

基于静态配置文件的 Envoy 代理实现，适合简单场景和快速部署。

**学习要点**:
- 静态配置文件结构
- 监听器、集群、端点配置
- 负载均衡和健康检查
- 服务管理和监控


### 2. [动态配置代理](./stand-alone/envoy_xds_control/)

基于 XDS (xDS) 控制平面的动态配置管理，适合复杂场景和生产环境。

**学习要点**:
- XDS 协议理解
- 控制平面开发
- 动态配置更新
- 服务发现集成



## 🔗 相关资源

- [Envoy 官方文档](https://www.envoyproxy.io/docs/)
- [Envoy 配置参考](https://www.envoyproxy.io/docs/envoy/latest/configuration/configuration)
- [Kubernetes API 文档](https://kubernetes.io/docs/reference/kubernetes-api/)
- [xDS 协议文档](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol)

