// Jenkinsfile (Add this stage before any 'terraform init' or 'packer build')

// Define the name of the ISO we want to use. 
// Must match the ISO you want to download.
def ISO_FILENAME = "ubuntu-22.04.4-live-server-amd64.iso"
def ISO_URL = "https://releases.ubuntu.com/22.04.4/${ISO_FILENAME}"

pipeline {
    agent { label 'your-jenkins-agent-label' } // Specify agent if necessary
    
    // Assumes PROXMOX_NODE is set in your environment block (e.g., 'pve')
    // and PROXMOX_HOST is the IP (e.g., '192.168.1.180')
    environment {
        // ... other environment variables ...
        PROXMOX_HOST = "192.168.31.180" 
        PROXMOX_USER = "root"
        STORAGE_ID   = "local" // Storage pool ID for ISOs (e.g., local, iso-storage)
    }
    
    stages {
        // ... (Checkout Stage) ...

        stage('Upload ISO to Proxmox') {
            steps {
                // IMPORTANT: Change 'your-ssh-credential-id' to your actual Jenkins SSH Credential ID
                sshagent(['ssh-credential-id']) { 
                    
                    // 1. Download the ISO to the Jenkins workspace (for local transfer)
                    echo "Downloading ISO file: ${ISO_FILENAME}..."
                    sh "wget --no-check-certificate -O ${ISO_FILENAME} ${ISO_URL}"

                    // 2. Securely execute pvesh via SSH to upload the file
                    echo "Initiating SSH-based upload to Proxmox node ${env.PROXMOX_NODE}..."
                    
                    // The core upload command: 
                    // This command uses Bash redirection (<) over SSH to pipe the local ISO 
                    // content into the pvesh upload API endpoint on the Proxmox host.
                    sh """
                    ssh ${env.PROXMOX_USER}@${env.PROXMOX_HOST} "pvesh create /nodes/${env.PROXMOX_NODE}/storage/${env.STORAGE_ID}/upload \\
                        --content iso \\
                        --filename ${ISO_FILENAME}" < ${ISO_FILENAME}
                    """
                    
                    echo "ISO transfer complete. The file is now on Proxmox at ${env.STORAGE_ID}:iso/${ISO_FILENAME}"
                }
            }
        }
        
        // ... (Template Build Stage - using the ISO file: ${env.STORAGE_ID}:iso/${ISO_FILENAME}) ...
    }
}
