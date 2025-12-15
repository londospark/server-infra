# Proxmox Bootstrap with Ansible

This playbook automates the post-installation bootstrap of Proxmox VE for use with Terraform. It creates a dedicated user, role, and API token with the necessary permissions.

## Prerequisites

Before running this playbook, ensure:

1. **Proxmox VE is installed and running** on your target machine
   - The machine has booted successfully from the custom ISO
   - The network is configured and reachable from your current machine

2. **Ansible is installed** on your development machine:
   ```bash
   # macOS
   brew install ansible
   
   # Ubuntu/Debian
   sudo apt-get install ansible
   
   # Fedora
   sudo dnf install ansible
   ```

3. **SSH keys have been generated** on your development machine:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   ```
   This is required because the playbook will install your public key on the Proxmox host.

4. **Environment variables are set up**:
   - Run `direnv allow` in the repository root
   - Verify `PROXMOX_HOST` and `PROXMOX_PASS` are loaded:
     ```bash
     echo $PROXMOX_HOST
     echo $PROXMOX_PASS
     ```

## What This Playbook Does

The `bootstrap_proxmox.yml` playbook performs the following steps:

1. **Installs your SSH public key** to the Proxmox root user (uses initial password authentication)
2. **Creates a Terraform Role** with the minimum required privileges for infrastructure provisioning
3. **Creates a Terraform User** (`terraform-prov@pve`) with a placeholder password
4. **Binds the user to the role** with global permissions
5. **Generates an API token** for the Terraform user
6. **Appends the API token to `.envrc`** in the repository root

## Running the Playbook

### From the Repository Root

```bash
cd 01-post-boot-ansible/
ansible-playbook -i inventory bootstrap_proxmox.yml
```

### What to Expect

The playbook will connect to your Proxmox host using the `PROXMOX_HOST` and `PROXMOX_PASS` variables from your `.envrc` file. Progress will be displayed as each task completes.

Once successful, you should see a message similar to:

```
TASK [Suggest direnv reload] ***
ok: [192.168.1.100] => {
    "msg": "Run 'direnv allow' in the root folder to load the new Terraform token!"
}
```

### Load the Terraform Token

After the playbook completes successfully, reload direnv to load the new Terraform token:

```bash
cd ..
direnv allow
```

Verify the token is loaded:

```bash
echo $TF_VAR_proxmox_api_token
```

## Troubleshooting

### "PROXMOX_HOST environment variable is missing"

**Solution**: Run `direnv allow` in the repository root before running the playbook.

### "Permission denied (publickey,password)"

**Possible causes**:
- `PROXMOX_PASS` is incorrect
- `PROXMOX_HOST` is unreachable
- SSH keys haven't been generated yet

**Solution**: 
- Verify your Proxmox root password matches the one in `.envrc`
- Check network connectivity: `ping $PROXMOX_HOST`
- Generate SSH keys: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""`

### "Failed to locate authorized_keys file"

**Possible cause**: The SSH directory doesn't exist on the Proxmox host

**Solution**: This typically shouldn't happen on Proxmox, but if it does, you can manually create the directory on the host:
```bash
ssh root@$PROXMOX_HOST "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
```

### Ansible command not found

**Solution**: Install Ansible (see Prerequisites section above)

## Manual Token Generation (If Needed)

If the playbook fails to generate the token, you can manually create it on the Proxmox host:

```bash
ssh root@$PROXMOX_HOST
pveum user token add terraform-prov@pve tf-token --privsep 0 --output-format json
```

Then manually add the token to your `.envrc` file:

```bash
export TF_VAR_proxmox_api_token="terraform-prov@pve!tf-token=<token-value>"
```

And reload direnv:

```bash
direnv allow
```

## Next Steps

Once the Terraform token is loaded in your `.envrc`, you can proceed with Terraform provisioning. The `TF_VAR_proxmox_api_endpoint` and `TF_VAR_proxmox_api_token` variables are now ready for use.
