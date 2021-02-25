class k8s_workernode::service ( Boolean $k8s_kube_proxy_service_enable, Boolean $k8s_kubelet_service_enable  ) {
    service { "k8s-kubeproxy" :
        ensure => $k8s_api_service_enable,
        enable => $k8s_api_service_enable,
        require => Class[ "k8s_workernode::install" ],
    }

    service { "k8s-kubelet" :
        ensure => $k8s_control_manager_service_enable,
        enable => $k8s_control_manager_service_enable,
        require => Class[ "k8s_workernode::install" ],
    }

}

