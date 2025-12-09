
## istio 是如何执行inject的
安装完 istio控制面后,  能看到 istio 创建了一个名为istio-sidecar-injector-1-21-0的准入控制器

当namespace 有 istio.io/rev = 1-21-0的 label, 并且对象资源为pod 创建的时候, 会去调用 istiod-1-21-0 service 的 /inject 方法

```yaml
    namespaceSelector:
      matchExpressions:
        - key: istio.io/rev
          operator: In
          values:
            - 1-21-0
        - key: istio-injection
          operator: DoesNotExist
    service:
        name: istiod-1-21-0
        namespace: istio-system
        path: /inject
        port: 443
    rules:
      - apiGroups:
          - ''
        apiVersions:
          - v1
        operations:
          - CREATE
        resources:
          - pods
```

```yaml


apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  creationTimestamp: '2025-08-18T16:37:43Z'
  generation: 2
  labels:
    app: sidecar-injector
    install.operator.istio.io/owning-resource: installed-state-example-1-21-0
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio.io/rev: 1-21-0
    operator.istio.io/component: Pilot
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: 1.20.0
    release: istio
      manager: istio-operator
      operation: Apply
      time: '2025-08-18T16:37:43Z'
    - apiVersion: admissionregistration.k8s.io/v1
      fieldsType: FieldsV1
      fieldsV1:
        f:webhooks:
          k:{"name":"rev.namespace.sidecar-injector.istio.io"}:
            f:clientConfig:
              f:caBundle: {}
          k:{"name":"rev.object.sidecar-injector.istio.io"}:
            f:clientConfig:
              f:caBundle: {}
      manager: pilot-discovery
      operation: Update
      time: '2025-08-18T16:41:06Z'
  name: istio-sidecar-injector-1-21-0
  resourceVersion: '4580297'
  uid: 4b664988-8493-4c96-abde-07f9de224318
webhooks:
  - admissionReviewVersions:
      - v1beta1
      - v1
    clientConfig:
      caBundle: >-
        LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvVENDQWVXZ0F3SUJBZ0lSQVBqdnJXeUhZcFVEcEQybEV0OUpBL0F3RFFZSktvWklodmNOQVFFTEJRQXcKR0RFV01CUUdBMVVFQ2hNTlkyeDFjM1JsY2k1c2IyTmhiREFlRncweU5UQTRNVGd4TmpReE1EVmFGdzB6TlRBNApNVFl4TmpReE1EVmFNQmd4RmpBVUJnTlZCQW9URFdOc2RYTjBaWEl1Ykc5allXd3dnZ0VpTUEwR0NTcUdTSWIzCkRRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRG1uckJxN3VoSFVINXhkTEhTUEkrS3NYRVg4eXBQMGVvcG1hMnIKNDZjRFNJOHFWY1ZPVjhOdUV5dm1oVTk1NGdkSlFvMFpVUC9GUDJyclRYQ09YM0RHN2Mwd2s5YzlmZGVzQmpYdApxZDZEcmhra21zZ1RKNm1QVFlnSHFsMXlHTVJLdnpCWXdOb1VIcmNqZHVDVmEzcXp6R1djaHgyS0k3Z2pOb3dXCmpkL1dmaHBYQVU4TE1raFRYYTMybmg1bnREVE80dHQyQ2hUWHJKN2RnZjZPaDlLQ21YUHRIZitUWWF1YmVJbXUKVXhmWHo2ZUhLMk1BQ0VUZ2hjUlpkakFLNzVBWDdtUzcxbmdzbnAvOS9TRFFIL0E5TWFRYW1pTkg4ZFpkaWQ3QwpYeTdHWEZJVXJZTlVrRmw5a1h2N3NPY1V4bHcvR1VFVkJyb2VQVGR5MUpvQ3IyeG5BZ01CQUFHalFqQkFNQTRHCkExVWREd0VCL3dRRUF3SUNCREFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlM2Si9zSTUzQ08KblZCUE5mMWg4ZmY3Q2ovZUh6QU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFOMEFhNTFwYmc5Njh6cmxsQWpEKwo3S3JYQzdxRGMvblp5NUlnMUMrTUl5SkFmZWFOMXNhM1M1M25LTFBKMkV3UWd4STRvRjFVMU5mbmVNQzJ0WGpBCnBWdU44VmVhUGFCMHdHR09iODlFeUNBaW5IQ1lBbVduMVBDanFibVVKRHhxb015NHljZ0t0MGhHRlZXSlBpOVMKSkJYSmM2Vll1TGVTdUQyckJZYk81elRDQmo2d3ZCYW1GSVkyT2pyc201bnJ4WkM3cmJ3VjVtdTIyNjZ6Zk51Vgp6UnVKZTN5aGlqOWNRUWR4YVByOWk3SG1Idk9PNFRhbjZQTE1tUTVnOFQ5bi9FYW9IVHRsWVliNXQzQUtCR3lTCklkNnZRTXNLemMxZ2lTUVkwVHRkdXdpaXhJTWFQQmtuUUJKM2RZU0FPY2Y1bVFVVXFxZ1Q4bS9qcngyalRxTk8KNVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
      service:
        name: istiod-1-21-0
        namespace: istio-system
        path: /inject
        port: 443
    failurePolicy: Fail
    matchPolicy: Equivalent
    name: rev.namespace.sidecar-injector.istio.io
    namespaceSelector:
      matchExpressions:
        - key: istio.io/rev
          operator: In
          values:
            - 1-21-0
        - key: istio-injection
          operator: DoesNotExist
    objectSelector:
      matchExpressions:
        - key: sidecar.istio.io/inject
          operator: NotIn
          values:
            - 'false'
    reinvocationPolicy: Never
    rules:
      - apiGroups:
          - ''
        apiVersions:
          - v1
        operations:
          - CREATE
        resources:
          - pods
        scope: '*'
    sideEffects: None
    timeoutSeconds: 10
  - admissionReviewVersions:
      - v1beta1
      - v1
    clientConfig:
      caBundle: >-
        LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvVENDQWVXZ0F3SUJBZ0lSQVBqdnJXeUhZcFVEcEQybEV0OUpBL0F3RFFZSktvWklodmNOQVFFTEJRQXcKR0RFV01CUUdBMVVFQ2hNTlkyeDFjM1JsY2k1c2IyTmhiREFlRncweU5UQTRNVGd4TmpReE1EVmFGdzB6TlRBNApNVFl4TmpReE1EVmFNQmd4RmpBVUJnTlZCQW9URFdOc2RYTjBaWEl1Ykc5allXd3dnZ0VpTUEwR0NTcUdTSWIzCkRRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRG1uckJxN3VoSFVINXhkTEhTUEkrS3NYRVg4eXBQMGVvcG1hMnIKNDZjRFNJOHFWY1ZPVjhOdUV5dm1oVTk1NGdkSlFvMFpVUC9GUDJyclRYQ09YM0RHN2Mwd2s5YzlmZGVzQmpYdApxZDZEcmhra21zZ1RKNm1QVFlnSHFsMXlHTVJLdnpCWXdOb1VIcmNqZHVDVmEzcXp6R1djaHgyS0k3Z2pOb3dXCmpkL1dmaHBYQVU4TE1raFRYYTMybmg1bnREVE80dHQyQ2hUWHJKN2RnZjZPaDlLQ21YUHRIZitUWWF1YmVJbXUKVXhmWHo2ZUhLMk1BQ0VUZ2hjUlpkakFLNzVBWDdtUzcxbmdzbnAvOS9TRFFIL0E5TWFRYW1pTkg4ZFpkaWQ3QwpYeTdHWEZJVXJZTlVrRmw5a1h2N3NPY1V4bHcvR1VFVkJyb2VQVGR5MUpvQ3IyeG5BZ01CQUFHalFqQkFNQTRHCkExVWREd0VCL3dRRUF3SUNCREFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlM2Si9zSTUzQ08KblZCUE5mMWg4ZmY3Q2ovZUh6QU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFOMEFhNTFwYmc5Njh6cmxsQWpEKwo3S3JYQzdxRGMvblp5NUlnMUMrTUl5SkFmZWFOMXNhM1M1M25LTFBKMkV3UWd4STRvRjFVMU5mbmVNQzJ0WGpBCnBWdU44VmVhUGFCMHdHR09iODlFeUNBaW5IQ1lBbVduMVBDanFibVVKRHhxb015NHljZ0t0MGhHRlZXSlBpOVMKSkJYSmM2Vll1TGVTdUQyckJZYk81elRDQmo2d3ZCYW1GSVkyT2pyc201bnJ4WkM3cmJ3VjVtdTIyNjZ6Zk51Vgp6UnVKZTN5aGlqOWNRUWR4YVByOWk3SG1Idk9PNFRhbjZQTE1tUTVnOFQ5bi9FYW9IVHRsWVliNXQzQUtCR3lTCklkNnZRTXNLemMxZ2lTUVkwVHRkdXdpaXhJTWFQQmtuUUJKM2RZU0FPY2Y1bVFVVXFxZ1Q4bS9qcngyalRxTk8KNVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
      service:
        name: istiod-1-21-0
        namespace: istio-system
        path: /inject
        port: 443
    failurePolicy: Fail
    matchPolicy: Equivalent
    name: rev.object.sidecar-injector.istio.io
    namespaceSelector:
      matchExpressions:
        - key: istio.io/rev
          operator: DoesNotExist
        - key: istio-injection
          operator: DoesNotExist
    objectSelector:
      matchExpressions:
        - key: sidecar.istio.io/inject
          operator: NotIn
          values:
            - 'false'
        - key: istio.io/rev
          operator: In
          values:
            - 1-21-0
    reinvocationPolicy: Never
    rules:
      - apiGroups:
          - ''
        apiVersions:
          - v1
        operations:
          - CREATE
        resources:
          - pods
        scope: '*'
    sideEffects: None
    timeoutSeconds: 10


```