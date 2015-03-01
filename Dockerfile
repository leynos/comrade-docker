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
# For trusty:
#RUN apt-get -y install --force-yes python3-all curl postgresql-client-9.3 libpq-dev python3-dev libssl-dev krb5-multidev comerr-dev libpython3-dev python3.4-dev libexpat1-dev libc6-dev libssl1.0.0=1.0.1f-1ubuntu2 libc6=2.19-0ubuntu6 gcc apt-transport-https
# For utopic
RUN apt-get -y install --force-yes python3-all curl postgresql-client-9.4 libpq-dev python3-dev libssl-dev krb5-multidev comerr-dev libpython3-dev python3.4-dev libexpat1-dev libc6-dev libssl1.0.0=1.0.1f-1ubuntu9 libc6=2.19-10ubuntu2 gcc apt-transport-https

# Install node-js and git
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && ( echo 'deb https://deb.nodesource.com/node utopic main' && echo 'deb-src https://deb.nodesource.com/node utopic main' ) > /etc/apt/sources.list.d/nodesource.list && apt-get update && apt-get -y install nodejs git

# Install pip from Python Packaging Authority
RUN curl https://bootstrap.pypa.io/get-pip.py | python3 -

# The version of django-generic-json-views on PyPI is incompatible with Python 3.  Remove this line once v0.6.5 is available on PyPI
RUN cd /opt && curl -L https://github.com/bbengfort/django-generic-json-views/archive/v0.6.5.tar.gz | tar xvz && cd django-generic-json-views-0.6.5/ && python3 setup.py install && cd / && rm -rf /opt/django-generic-json-views-0.6.5 /tmp/pip_build_root

# Install the micro wsgi server
RUN pip install uwsgi && rm -rf /tmp/pip_build_root

# Install bower, the package manager for client-side JS libs
RUN npm install -g bower

# Add the application itself
ADD comrade /opt/comrade

# Run pip with the local requirements to install the remainer of the Python lib requirements
RUN pip install -r /opt/comrade/requirements/local.txt && rm -rf /tmp/pip_build_root

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
WORKDIR /opt/comrade

RUN bower install

CMD ["/run.py"]
