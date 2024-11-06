# **Wazuh Agent Management with Ansible**

## **Objective**

This Ansible project aims to streamline the management of Wazuh agents across a distributed infrastructure. By automating the installation, maintenance, and removal of Wazuh agents, this project ensures secure and uniform host monitoring within the network.

## **Prerequisites**

- **Ansible 2.9+** installed on the control machine.
- **SSH enabled** on all target hosts.
- Target hosts must be running **Linux with apt** (e.g., Debian, Ubuntu).
- The **variables file** **`vars/vars.yml`** must be correctly configured with your environment's details.

## **Configuration of `vars/vars.yml` File**

Before running the playbooks, ensure the following variables are configured in the **`vars/vars.yml`** file:

```yaml
yamlCopy code
wazuh_manager_ip: "MANAGER_IP_ADDRESS" # The IP address of your Wazuh manager
wazuh_agent_package: "wazuh-agent_4.7.3-1_amd64.deb" # The Wazuh agent package to install
wazuh_agent_repo: "https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/" # URL of the repository containing the agent package
wazuh_agent_group: "default" # The Wazuh agent group to add the agent to
wazuh_manager_port: "55000" # The port on which the Wazuh manager is listening
wazuh_username: "USERNAME" # Username for authentication with the Wazuh manager
wazuh_password: "PASSWORD" # Password for authentication with the Wazuh manager
validate_certs: no # Whether or not to validate SSL certificates when connecting to the Wazuh manager

```

Replace **`MANAGER_IP_ADDRESS`**, **`USERNAME`**, and **`PASSWORD`** with your actual information.

## **Usage**

To use the provided playbooks, follow these steps:

1. **Installing Wazuh Agents:**
    
    ```bash
    ansible-playbook -i your_inventory install_wazuh_agent.yml
    ```
    
2. **Removing 'Disconnected' and 'Never Connected' Wazuh Agents:**
    
    ```bash
    ansible-playbook -i your_inventory remove_disconnected_agents.yml
    ```
    
3. **Uninstalling Wazuh Agents:**
    
    ```bash
    ansible-playbook -i your_inventory uninstall_wazuh_agent.yml
    ```
    

## **Playbooks**

### **1. `install_wazuh_agent.yml`**

Installs the Wazuh agent on target hosts, configures the IP address and group of the Wazuh manager, and then starts the agent service.

### **2. `uninstall_wazuh_agent.yml`**

Stops the Wazuh agent service, uninstalls the agent, and removes its directory, preparing the host for a clean reinstallation or to be removed from the monitored network.

### **3. `remove_disconnected_agents.yml`**

Removes Wazuh agents that are in a 'Disconnected' or 'Never Connected' state on the Wazuh manager, keeping the agent list clean.

## **Contribution**

Your contributions to improving this project are welcome. To do so, you can send pull requests or create issues for any suggestions, corrections, or enhancements.