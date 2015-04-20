FROM debian:wheezy

MAINTAINER sebastien@cakemail.com

ENV DEBIAN_FRONTEND noninteractive
ENV PROJECT_PATH /opt/cakemail/sinatra-apps/social

RUN apt-get update && \
    apt-get install -y apache2 libapache2-mod-passenger ruby1.8 ruby1.8-dev perl \
    rsyslog supervisor sudo git librmagick-ruby

RUN gem install bundler --no-ri --no-rdoc

# configure apache
RUN a2dissite 000-default
RUN a2enmod rewrite
RUN a2enmod headers
ADD docker/apache2/social.conf /etc/apache2/sites-available/social
RUN a2ensite social

# deploy user
RUN useradd -u 1050 -G www-data -m -d /home/cake cake

# prepare directories
RUN mkdir -p ${PROJECT_PATH}
RUN chown -R cake:cake /opt/cakemail
RUN mkdir -p /webapps
RUN ln -s ${PROJECT_PATH} /webapps/social

# deploy the project
ADD . ${PROJECT_PATH}
RUN chown -R cake:cake /opt/cakemail
RUN sudo su cake -c "cd ${PROJECT_PATH} && bundle install --quiet --deployment --path=${PROJECT_PATH}/bundle"

# remote logging
ADD docker/rsyslog/remote.conf /etc/rsyslog.d/remote.conf
ADD docker/supervisor/supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord"]
