# Copyright © 2015, David McIntosh <dmcintosh@df12.net> 
# 
# Permission to use, copy, modify, and/or distribute this software for any 
# purpose with or without fee is hereby granted, provided that the above 
# copyright notice and this permission notice appear in all copies. 
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR 
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES 
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN 
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF 
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. 

FROM ubuntu:utopic

MAINTAINER Leynos <leynos@troubledskies.net>

# Install Python and requirements
# For utopic (Python 3)
#RUN apt-get update && apt-get -y install --force-yes python3-all curl postgresql-client-9.4 libpq-dev python3-dev libssl-dev krb5-multidev comerr-dev libpython3-dev python3.4-dev libexpat1-dev libc6-dev libssl1.0.0=1.0.1f-1ubuntu9.1 libc6=2.19-10ubuntu2.3 gcc apt-transport-https libgeos-dev
# For utopic (Python 2)
RUN apt-get update && apt-get -y install --force-yes curl postgresql-client-9.4 libpq-dev libssl-dev krb5-multidev comerr-dev python-all-dev libexpat1-dev libc6-dev libssl1.0.0=1.0.1f-1ubuntu9.1 libc6=2.19-10ubuntu2.3 gcc apt-transport-https libgeos-dev

# Install node-js and git
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && ( echo 'deb https://deb.nodesource.com/node utopic main' && echo 'deb-src https://deb.nodesource.com/node utopic main' ) > /etc/apt/sources.list.d/nodesource.list && apt-get update && apt-get -y install nodejs git

# Install pip from Python Packaging Authority
RUN curl https://bootstrap.pypa.io/get-pip.py | python -

# The version of django-generic-json-views on PyPI is incompatible with Python 3.  Remove this line once v0.6.5 is available on PyPI
RUN cd /opt && curl -L https://github.com/bbengfort/django-generic-json-views/archive/v0.6.5.tar.gz | tar xvz && cd django-generic-json-views-0.6.5/ && python setup.py install && cd / && rm -rf /opt/django-generic-json-views-0.6.5 /tmp/pip_build_root

# Install the micro wsgi server
RUN pip install uwsgi && rm -rf /tmp/pip_build_root

# Install bower, the package manager for client-side JS libs
RUN npm install -g bower grunt-cli npm-cache

# Run pip with the local requirements to install the remainer of the Python lib requirements
RUN mkdir -p /opt/comrade/requirements
ADD comrade/requirements/* /opt/comrade/requirements/
RUN pip install -r /opt/comrade/requirements/local.txt && rm -rf /tmp/pip_build_root

# Add the application itself
ADD comrade /opt/comrade

# Set up a user for the application
RUN useradd -b /var/opt -s /bin/false -r -m comrade
RUN chown -R comrade:comrade /opt/comrade

# Expose port 8080 for WSGI requests
EXPOSE 8080

# Add encapsulation script
ADD files/run.py /
RUN chmod 555 /run.py

# Everything from this point on will be executed as the comrade user
USER comrade
RUN mkdir /var/opt/comrade/.package_cache
WORKDIR /opt/comrade

CMD ["/run.py"]
