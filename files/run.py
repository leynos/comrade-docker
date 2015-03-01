#!/usr/bin/env python3

import random, os
from subprocess import call

def execute_pg_cmd(cmd):
    """Execute a command on the postgress database server"""
    call_cmd = ['psql', '-h', 'db', '-d', 'ssp_canvassing', '-U', 'ssp_canvassing', '-w', '-c']
    call(call_cmd + [cmd])

pgpass_file = '/var/opt/comrade/.pgpass'
secrets_file = '/opt/comrade/ssp_canvassing/settings/secrets.py'
allowed_chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
secret_key = os.environ.get('SECRET_KEY',
        ''.join([random.SystemRandom().choice(allowed_chars) for i in range(50)]))
db_password = os.environ.get('DB_PASSWORD', 'ssp_canvassing')

with open(pgpass_file, 'w') as handle:
    handle.write('db:*:ssp_canvassing:ssp_canvassing:{0}\n'.format(db_password))

os.chmod(pgpass_file, 0o600)

with open(secrets_file, 'w') as handle:
    handle.write('SECRET_KEY = \'{0}\'\n'.format(secret_key))
    handle.write("""\
DATABASES = {{
    'default': {{
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'HOST': 'db',
        'NAME': 'ssp_canvassing',
        'USER': 'ssp_canvassing',
        'PASSWORD': '{0}',
    }}
}}
""".format(db_password))

execute_pg_cmd('CREATE EXTENSION postgis;')
execute_pg_cmd('CREATE EXTENSION postgis_topology;')
call(['/usr/local/bin/uwsgi', '--socket', '0.0.0.0:8080', '--module', 'ssp_canvassing.wsgi'])
