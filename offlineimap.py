import re, commands
def get_keychain_pass(account=None):
    params = {
        'security': '/usr/bin/security',
        'command':  'find-generic-password',
        'account':  account
    }

    command = "%(security)s %(command)s -g -a %(account)s" % params
    outtext = commands.getoutput(command)
    return re.match(r'password: "(.*)"', outtext).group(1)
