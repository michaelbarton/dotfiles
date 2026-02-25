import subprocess


def get_keychain_pass(account):
    command = ["/usr/bin/security", "find-generic-password", "-w", "-a", account]
    process = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    process.wait()
    if process.returncode != 0:
        raise RuntimeError("Error running command: {}".format(process.stderr.read().decode()))

    password_block = process.stdout.read().decode().strip()
    if password_block:
        return password_block
    raise RuntimeError(
        "No password found with `{}`:\n {}".format(" ".join(command), password_block)
    )


def get_keyring_pass(key, value):
    command = ["secret-tool", "lookup", key, value]
    return subprocess.check_output(command).decode().strip()
