#
# Returns ExecStart string for k8s kubelet service on worker node in k8s cluster
#

module Puppet::Parser::Functions
  newfunction(:create_k8s_kubelet_exec_start, :type => :rvalue, :doc => <<-EOS
    Returns ExecStart string for k8s kubeproxy
    EOS
  ) do |arguments|
    k8s_kubelet_binarypath = arguments[0]
    k8s_kubelet_config_hash = arguments[1]
    k8s_path_to_kubelet_kubeconfig = arguments[2]
    k8s_node_ip = arguments[3]

    exec_start_string = "ExecStart=" + k8s_kubelet_binarypath + " \\" + "\n"
    k8s_kubelet_config_hash["common"].each do |k, v|
      exec_start_string = exec_start_string + " --" + k + "=" + v.to_s + " \\" + "\n" 
    end
    
    exec_start_string = exec_start_string + " --kubeconfig=" + k8s_path_to_kubelet_kubeconfig.to_s + " \\" + "\n"
    exec_start_string = exec_start_string + " --node-ip=" + k8s_node_ip.to_s + "\n"

    return exec_start_string
  
  end
end

# vim: set ts=2 sw=2 et :
