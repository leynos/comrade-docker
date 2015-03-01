#!/usr/bin/env python3

import random, os
from subprocess import call

secrets_file = '/opt/comrade/ssp_canvassing/settings/secrets.py'
allowed_chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
secret_key = ''.join([random.SystemRandom().choice(allowed_chars) for i in range(50)])

with open(secrets_file, 'w') as handle:
    handle.write('SECRET_KEY = \'{0}\'\n'.format(
            os.environ.get('SECRET_KEY', secret_key)))
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
""".format(os.environ.get('DB_PASSWORD', 'ssp_canvassing')))

call(['/usr/local/bin/uwsgi', '--socket', '0.0.0.0:8080', '--module', 'ssp_canvassing.wsgi'])
