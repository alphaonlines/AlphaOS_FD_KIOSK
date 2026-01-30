# Dev 2 TODO

## Done
- Broker mTLS config (`server/broker/mosquitto.conf`).
- Broker ACL template (`server/broker/acl.conf`).
- CA + cert generation guide (`server/broker/certs/README.md`).
- Controller command validation + publish failure handling.
- Agent handles missing update runner path gracefully.

## Next
- Confirm broker paths/ports in deploy environment.
- Validate controller mTLS connectivity against broker.
- End-to-end command + reply smoke test with a kiosk cert.
- Decide controller HTTP auth (shared token vs mTLS vs none).
- Decide kiosk_id validation rules (prefix, length, allowed chars).
