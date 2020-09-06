import commands
import re

def get_keychain_pass(account=None):
    params = {
        'security': '/usr/bin/security',
        'command':  'find-generic-password',
        'account':  account
    }

    command = "%(security)s %(command)s -g -a %(account)s".format(params)
    outtext = commands.getoutput(command)
    return re.match(r'password: "(.*)"', outtext).group(1)

def get_lastpass_pass(pass_id):
    command = "lpass show --password {}".format(pass_id)
    return commands.getoutput(command).strip()
