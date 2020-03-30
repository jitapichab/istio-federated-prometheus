K8S_BIN ?= $(shell which kubectl 2>/dev/null || which oc 2>/dev/null)
KIALI_PATCH = $(shell cat kiali-patch.yaml)

.ensure-yq:
	@command -v yq >/dev/null 2>&1 || { echo >&2 "yq is required. Grab it on https://github.com/mikefarah/yq"; exit 1; }

istio-prod-ready:
	${K8S_BIN} apply -f ./istio-prometheus-cm.yaml -n istio-system ; \
	${K8S_BIN} apply -f ./istio-prometheus.yaml -n istio-system ; \
	${K8S_BIN} apply -f ./master-cm.yaml -n istio-system ; \
	${K8S_BIN} apply -f ./master.yaml -n istio-system ; \
	${K8S_BIN} delete pod -l app=prometheus -n istio-system ; \
	${K8S_BIN} delete pod -l app=master-prometheus -n istio-system

watch:
	${K8S_BIN} get pods -n istio-system -w

expose:
	@echo "Master Prometheus: http://localhost:9091/"
	${K8S_BIN} port-forward svc/master-prometheus 9091:9090 -n istio-system

patch-kiali: .ensure-yq
	${K8S_BIN} get kiali kiali -n kiali-operator -o yaml \
		| yq w - spec.external_services.prometheus.url http://master-prometheus.istio-system:9090 \
		| ${K8S_BIN} apply -f -
