# Broker Certificates (mTLS)

This folder documents the suggested certificate layout and a minimal OpenSSL flow.
All paths in `server/broker/mosquitto.conf` are relative to `server/broker/`.

## Layout
```
certs/
  ca/
    ca.key
    ca.crt
  server/
    server.key
    server.csr
    server.crt
  controller/
    controller.key
    controller.csr
    controller.crt
  kiosks/
    kiosk-<id>.key
    kiosk-<id>.csr
    kiosk-<id>.crt
```

## 1) Create CA
```
mkdir -p ca server controller kiosks
openssl genrsa -out ca/ca.key 4096
openssl req -x509 -new -nodes -key ca/ca.key -sha256 -days 3650 \
  -subj "/C=US/O=Kiosk/OU=Platform/CN=kiosk-ca" \
  -out ca/ca.crt
```

## 2) Server cert (broker)
Set CN to the broker hostname or IP. Include SAN for hostnames/IPs used by kiosks.
```
openssl genrsa -out server/server.key 4096
openssl req -new -key server/server.key \
  -subj "/C=US/O=Kiosk/OU=Broker/CN=broker.local" \
  -out server/server.csr
openssl x509 -req -in server/server.csr -CA ca/ca.crt -CAkey ca/ca.key \
  -CAcreateserial -out server/server.crt -days 825 -sha256 \
  -extfile <(printf "subjectAltName=DNS:broker.local,IP:127.0.0.1")
```

## 3) Controller cert
CN must be `controller` to match the ACL entry.
```
openssl genrsa -out controller/controller.key 4096
openssl req -new -key controller/controller.key \
  -subj "/C=US/O=Kiosk/OU=Controller/CN=controller" \
  -out controller/controller.csr
openssl x509 -req -in controller/controller.csr -CA ca/ca.crt -CAkey ca/ca.key \
  -CAcreateserial -out controller/controller.crt -days 825 -sha256
```

## 4) Kiosk certs
CN must be the kiosk ID (matches `kiosk/<id>/...` topic ACL pattern).
```
KIOSK_ID="kiosk-nyc-01"
openssl genrsa -out "kiosks/${KIOSK_ID}.key" 4096
openssl req -new -key "kiosks/${KIOSK_ID}.key" \
  -subj "/C=US/O=Kiosk/OU=Kiosk/CN=${KIOSK_ID}" \
  -out "kiosks/${KIOSK_ID}.csr"
openssl x509 -req -in "kiosks/${KIOSK_ID}.csr" -CA ca/ca.crt -CAkey ca/ca.key \
  -CAcreateserial -out "kiosks/${KIOSK_ID}.crt" -days 825 -sha256
```

## 5) Wire paths
- Broker: update `server/broker/mosquitto.conf` if you move files.
- Controller: set `mqtt.ca_cert`, `mqtt.client_cert`, `mqtt.client_key`.
- Kiosk agent: install certs under `/etc/kiosk-agent/certs/` (see agent docs).
