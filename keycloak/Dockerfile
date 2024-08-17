# syntax=docker.io/docker/dockerfile:1.9

# see https://quay.io/repository/keycloak/keycloak
# see https://www.keycloak.org/docs/latest/release_notes/index.html
# see https://www.keycloak.org/server/containers
# see https://github.com/keycloak/keycloak/blob/main/quarkus/container/Dockerfile
# see https://github.com/keycloak/keycloak/releases

# see https://www.keycloak.org/server/containers#_installing_additional_rpm_packages
FROM registry.access.redhat.com/ubi9 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN <<EOF
#!/bin/bash
set -euxo pipefail
dnf install \
    --installroot /mnt/rootfs \
    --releasever 9 \
    --setopt install_weak_deps=false \
    --nodocs -y \
    p11-kit \
    util-linux
dnf --installroot /mnt/rootfs clean all
rpm --root /mnt/rootfs -e --nodeps setup
EOF

FROM quay.io/keycloak/keycloak:25.0.2
COPY --from=ubi-micro-build /mnt/rootfs /
COPY --chmod=0755 entrypoint.sh /
USER 0
ENTRYPOINT ["/entrypoint.sh"]
