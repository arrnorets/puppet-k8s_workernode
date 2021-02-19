# Table of contents
1. [Common purpose](#1-common-purpose)
2. [Compatibility](#2-compatibility)
3. [Installation](#3-installation)
4. [Config example in Hiera and result files](#4-config-example-in-hiera-and-result-files)


# 1. Common purpose
This is a module that installs and configures kubelet and kube-proxy - Kubernetes components that are required for worker node in a cluster. In the end you will receive a server that is a part of Kubernetes cluster and ready for the further network configuration. See https://github.com/kelseyhightower/kubernetes-the-hard-way chapter 09 for detailed explanation.

Inspired by https://github.com/kelseyhightower/kubernetes-the-hard-way .

# 2. Compatibility
This module was tested on CentOS 7.

# 3. Installation
```yaml
mod 'k8s_workernode',
    :git => 'https://github.com/arrnorets/puppet-k8s_workernode.git',
    :ref => 'main'
```

# 4. Config example in Hiera and result files
This module follows the concept of so called "XaaH in Puppet". The principles are described [here](https://asgardahost.ru/library/syseng-guide/00-rules-and-conventions-while-working-with-software-and-tools/puppet-modules-organization/) and [here](https://asgardahost.ru/library/syseng-guide/00-rules-and-conventions-while-working-with-software-and-tools/3-hashes-in-hiera/).


Here is the example of config in Hiera:
```yaml

# First of all you have to generate at least CA and Kubernetes key-cert pairs in order to configure authentication against API server. 
# Kubernetes key-cert pair will be used as K8s API TLS credentials. See more deatils on https://github.com/kelseyhightower/kubernetes-the-hard-way, chapters 04, 05 and 06.

---
k8s_tls_certs:
  entities:
    ca:
      key: |
        <Insert your CA key here!>
      cert: |
        <Insert your CA certificate here!>

k8s_workernode:
  # Create root directories for configs and kubeconfigs on a workernode
  rootdirs:
    - '/etc/k8s'
    - '/etc/k8s/conf'
    - '/etc/k8s/kubeconfig'

  # Backend description. We are using containerd.
  container_backend:
    name: 'containerd'
    pkg_name: 'containerd.io'
    pkg_version: '1.4.3-3.1.el7'

  # Install basic set of CNI plugins
  cni:
    pkg_version: '0.8.2-1.el7'

  # Crictl for containers handling and debugging on workernodes.
  crictl:
    pkg_name: 'kubernetes-crictl'
    pkg_version: '1.18.14-1.el7'

  # /* Common kube-proxy and kubelet settings */
  kube-proxy:
    pkg_name: 'kubernetes-kube-proxy'
    pkg_version: '1.18.14-1.el7'
    enable: true

    parameters:
      binarypath: '/opt/k8s/kube-proxy'
      common:
        config: '/etc/k8s/conf/kube-proxy.yaml'
      conf:
        '/etc/k8s/conf/kube-proxy.yaml':
          kind: KubeProxyConfiguration
          apiVersion: kubeproxy.config.k8s.io/v1alpha1
          clientConnection:
            kubeconfig: "/etc/k8s/kubeconfig/kube-proxy.kubeconfig"
          mode: "iptables"
          clusterCIDR: "10.200.0.0/16"

  kubelet:
    pkg_name: 'kubernetes-kubelet'
    pkg_version: '1.18.14-1.el7'
    enable: true

    parameters:
      # /* Settings for systemd unit file */
      binarypath: '/opt/k8s/kubelet'
      common:
        config: '/etc/k8s/conf/kubelet-config.yaml'
        container-runtime: 'remote'
        container-runtime-endpoint: 'unix:///var/run/containerd/containerd.sock'
        image-pull-progress-deadline: '2m'
        network-plugin: 'cni'
        register-node: true
        v: 2
      # /* END BLOCK */
      
      # /* Kubelet configuration files */
      conf:
        '/etc/k8s/conf/kubelet-config.yaml':
          kind: KubeletConfiguration
          apiVersion: kubelet.config.k8s.io/v1beta1
          authentication:
            anonymous:
              enabled: false
            webhook:
              enabled: true
            x509:
              clientCAFile: "/var/lib/kubelet/own_ca.crt"
          authorization:
            mode: Webhook
          clusterDomain: "cluster.local"
          clusterDNS:
            - "10.32.0.10"
          podCIDR: "10.240.0.0/16"
          runtimeRequestTimeout: "15m"
      # /* END BLOCK */

  # /* END BLOCK */

# /* Kube-proxy kubeconfig is a commmon one for all workernodes. */

k8s_kubeconfigs:
  '/etc/k8s/kubeconfig/kube-proxy.kubeconfig':
  <Your YAML-formatted kubeconfig for kube-proxy starts here!>

  # /* END BLOCK */
```

Additionally, we have to configure Hiera for each worker node in the cluster with the following content.
```yaml
per_node_kubelet_conf:
  # IP address of worker node
  node-ip: '<worker node ip>'

  # Root directory for kubelet var files and certs
  vardir: "/var/lib/kubelet"
  tlsCertFile:
    name: "/var/lib/kubelet/k8s-node1.asgardahost.ru-kubelet.crt"
    value: |
      <Insert your node's private cert for kubelet here!>
  tlsPrivateKeyFile:
    name: "/var/lib/kubelet/k8s-node1.asgardahost.ru-kubelet.key"
    value: |
      <Insert your node's private key for kubelet here!>

  # Kubelet kubeconfig description.
  kubeconfig:
    '/etc/k8s/kubeconfig/k8s-node1.asgardahost.ru.kubeconfig':
      <Your YAML-formatted kubeconfig for kubelet on node k8s-node1 starts here!>
```

It will install kubelet and kube-proxy packages, put keys, certs, confiigs and kubeconfigs  under specified directories and generate a systemd unit file for kube-proxy and kubelet. Here is a list of generated files:
```bash
/etc/k8s
/etc/k8s/conf
/etc/k8s/conf/kubelet-config.yaml
/etc/k8s/conf/kube-proxy.yaml
/etc/k8s/kubeconfig
/etc/k8s/kubeconfig/kube-proxy.kubeconfig
/etc/k8s/kubeconfig/k8s-node1.asgardahost.ru.kubeconfig
/etc/systemd/system/k8s-kubelet.service
/etc/systemd/system/k8s-kubeproxy.service
/var/lib/kubelet
/var/lib/kubelet/own_ca.crt
/var/lib/kubelet/k8s-node1.asgardahost.ru-kubelet.key
/var/lib/kubelet/k8s-node1.asgardahost.ru-kubelet.crt
```

