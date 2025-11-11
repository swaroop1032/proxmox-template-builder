// Jenkinsfile

// --- Configuration Variables ---
// ISO DETAILS (must be updated if you change the Ubuntu version)
def ISO_FILENAME = "ubuntu-22.04.4-live-server-amd64.iso"
def ISO_URL      = "https://releases.ubuntu.com/22.04.4/${ISO_FILENAME}"

pipeline {
    agent any // Run on any available Jenkins agent

    // 1. TOOL FIX: Explicitly define Git to ensure the correct environment PATH for 'ssh-agent'
    // This resolves the StringIndexOutOfBoundsException error on Windows agents.
    tools {
        // Use the name defined in Jenkins Global Tool Configuration -> Git section
        git 'Git-Bash-Tool' 
    }

    environment {
        // --- PROXMOX API CREDENTIALS (Loaded from Jenkins Credentials) ---
        // Ensure these IDs are configured as Secret Text credentials in Jenkins
        TF_VAR_pm_api_token_id     = credentials('PROXMOX_API_TOKEN_ID')
        TF_VAR_pm_api_token_secret = credentials('PROXMOX_API_TOKEN_SECRET')
        
        // --- PROXMOX HOST DETAILS (MUST BE UPDATED) ---
        PROXMOX_NODE = "pve"            // Your Proxmox node name (e.g., 'pve', 'node1')
        PROXMOX_HOST = "192.168.31.180"  // IP address of your Proxmox server for SSH/API access
        PROXMOX_USER = "root"           // User for SSH access (must have key installed)
        STORAGE_ID   = "local"          // Proxmox storage pool ID for ISOs (e.g., 'local', 'iso-storage')

        // --- TERRAFORM VARIABLES ---
        # Update as necessary, or ensure they are defined in a 'terraform.tfvars' file.
        TF_VAR_proxmox_node  = "${PROXMOX_NODE}"
        TF_VAR_iso_file_name = "${STORAGE_ID}:iso/${ISO_FILENAME}"
        
        // NOTE: The preseed URL must be reachable by the VM during installation.
        TF_VAR_preseed_url   = "http://192.168.31.200/preseed.cfg" 
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        // 2. ISO MANAGEMENT STAGE
        stage('Upload ISO to Proxmox') {
            steps {
                // Ensure the PROXMOX_SSH_KEY credential is an "SSH Username with private key" type.
                sshagent(['PROXMOX_SSH_KEY']) { 
                    
                    echo "Downloading ISO file: ${ISO_FILENAME}..."
                    // Use --no-check-certificate if your Jenkins machine has TLS issues
                    sh "wget -O ${ISO_FILENAME} ${ISO_URL}"

                    echo "Initiating SSH-based upload to Proxmox host ${PROXMOX_HOST}..."
                    
                    // Uses 'ssh' to execute 'pvesh' on the Proxmox host, piping the local file content
                    sh """
                    # '-o StrictHostKeyChecking=no' is used here to avoid the 'known_hosts' warning from failing the pipeline.
                    # This is generally NOT recommended for production, but necessary for quick CI setup.
                    ssh -o StrictHostKeyChecking=no ${PROXMOX_USER}@${PROXMOX_HOST} "pvesh create /nodes/${PROXMOX_NODE}/storage/${STORAGE_ID}/upload \\
                        --content iso \\
                        --filename ${ISO_FILENAME}" < ${ISO_FILENAME}
                    """
                    echo "ISO transfer complete. File: ${STORAGE_ID}:iso/${ISO_FILENAME}"
                }
            }
        }
        
        stage('Template Build: Terraform Init & Plan') {
            steps {
                sh 'terraform init -upgrade'
                // This plan will reference the ISO uploaded in the previous stage
                sh 'terraform plan -out=tfplan' 
            }
        }
        
        stage('Apply Template Build (25 Min Timeout)') {
            steps {
                // Set a long timeout for the unattended OS installation process
                timeout(time: 25, unit: 'MINUTES') { 
                    echo "Starting Terraform Apply. This will wait 20+ minutes for OS installation and template conversion."
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }
}
