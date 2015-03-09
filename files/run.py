#!/usr/bin/env python

import random, os, socket, time
from subprocess import call

from unipath import Path

def service_exists(host, port):
    """Return True if a connection can be established to the given port on the
    given hostname"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        sock.connect((host, port))
        sock.close()
        return True
    except:
        return False

def execute_pg_cmd(cmd):
    """Execute a command on the postgress database server"""
    call_cmd = ['psql', '-h', 'db', '-d', 'ssp_canvassing', '-U', 'ssp_canvassing', '-w', '-c']
    call(call_cmd + [cmd])

def prep():
    # For now, just concatenate these.  We'll uglify later.
    with open('js/production.js', 'w') as outfile:
        print('Concatenating Javascript:')
        for jsfile in [
                'bower_components/jquery/dist/jquery.js',
                'bower_components/jquery-placeholder/jquery.placeholder.js',
                'bower_components/jquery.cookie/jquery.cookie.js',
                'bower_components/fastclick/lib/fastclick.js',
                'bower_components/modernizr/modernizr.js',
                'bower_components/foundation/js/foundation.js',
                'bower_components/leaflet/dist/leaflet-src.js',
                'js/accordion_mods.js',
            ]:
            print(jsfile)
            with open(jsfile) as infile:
                outfile.write(infile.read())
    print('Uglifying Javascript')
    call(['uglifyjs', '-o', 'js/production.min.js', 'js/production.js'])

    # Again, copy for now.  We'll do something nicer later.
    images_build = Path('./images/build')
    if not images_build.exists():
        images_build.mkdir(parents=True)
    print('Copying images:')
    for path in Path('.').walk(filter=lambda x: x.ext in ['.png', '.jpg', '.gif'] and x.parent != images_build):
        print(path)
        path.copy(Path(images_build, path.name))

    # Compile stylesheet with sass
    print('Compiling stylesheet')
    with open('css/main.css', 'w') as outfile:
        with open('scss/main.scss') as infile:
            call(['node-sass', '--output-style', 'compressed', '--include-path', 'bower_components/foundation/scss:scss'], stdin=infile, stdout=outfile)
            #outfile.write(sass.compile_string(infile.read(), include_paths='bower_components/foundation/scss:scss'))

while not service_exists('db', 5432):
    time.sleep(3)
    print('Waiting for database to start')

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

npm_verbose = 'NPM_VERBOSE' in os.environ

execute_pg_cmd('CREATE EXTENSION IF NOT EXISTS postgis;')
execute_pg_cmd('CREATE EXTENSION IF NOT EXISTS postgis_topology;')

# Don't do npm install for now.  It's bad for the blood pressure.
#npm_cmd = ['npm', 'install']
#if npm_verbose:
#    npm_cmd += ['--verbose']
#call(npm_cmd)

call(['bower', 'install'])

# Don't even go there.
#call(['grunt'])

prep()

Path('./static').mkdir()
call(['python', './manage.py', 'collectstatic', '--clear', '--noinput'])

call(['/usr/local/bin/uwsgi', '--socket', '0.0.0.0:8080', '--module', 'ssp_canvassing.wsgi'])
