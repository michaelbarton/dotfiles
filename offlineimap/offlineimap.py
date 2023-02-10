import subprocess
import re
import sys


def get_keychain_pass(account):
    command = ["/usr/bin/security", "find-generic-password", "-w", "-a", account]
    process = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    process.wait()
    if process.returncode != 0:
        raise RuntimeError("Error running command: \n".format(process.stderr.read().decode()))

    password_block = process.stdout.read().decode().strip()
    if password_block:
        return password_block
    raise RuntimeError(
        "No password found with `{}`:\n {}".format(" ".join(command), password_block)
    )


def get_keyring_pass(key, value):
    command = "secret-tool lookup {} {}".format(key, value)
    return commands.getoutput(command).strip()
