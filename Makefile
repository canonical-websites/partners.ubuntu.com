define HELP_TEXT
Canonical.com website project
===

Usage:

> make develop  # Auto-compile sass files and run the dev server

endef

# Variables
##

ENVPATH=${VIRTUAL_ENV}
VEX=vex --path ${ENVPATH}

ifeq ($(ENVPATH),)
	ENVPATH=env
endif

ifeq ($(PORT),)
	PORT=8002
endif

help:
	$(info ${HELP_TEXT})

clean:
	rm -rf pip-cache

start-dev:
	$(MAKE) sass-watch
	env/bin/python manage.py runserver_plus 0.0.0.0:7500

develop:
	python bootstrap.py env
	$(MAKE) pip-requirements
	. env/bin/activate && $(MAKE) update-db
	$(MAKE) sass
	$(MAKE) runserver

apt-requirements:
	sudo apt-get -y install libjpeg-dev graphviz zlib1g-dev libpng12-dev python-dev

pip-requirements:
	env/bin/pip install -r requirements/dev.txt

sass-watch:
	# Build sass
	sass --debug-info --watch cms/static/css/styles.scss:cms/static/css/styles.css &

sass:
	# Build sass
	sass --style compressed --update cms/static/css/styles.scss:cms/static/css/styles.css

runserver_prod:
	gunicorn fenchurch.wsgi:application

rebuild-dependencies-cache:
	-rm -rf pip-cache
	bzr branch lp:~webteam-backend/ubuntu-partner-website/dependencies pip-cache
	pip install --exists-action=w --download pip-cache/ -r requirements/standard.txt
	bzr commit pip-cache/ -m 'automatically updated partners requirements'
	bzr push --directory pip-cache lp:~webteam-backend/ubuntu-partner-website/dependencies
	bzr revno pip-cache > pip-cache-revno.txt
	rm -rf pip-cache src
	@echo "** Remember to commit pip-cache-revno.txt"

pip-cache:
	bzr branch -r `cat pip-cache-revno.txt` lp:~webteam-backend/ubuntu-partner-website/dependencies pip-cache

graph:
	./manage.py graph_models cms -o cms.svg -X PartnerModel,CategoryModel && xdg-open cms.svg

update-db:
	./manage.py syncdb --noinput --migrate

update-charm:
	if [ $(DATABASE_URL) ]; then $(MAKE) update-db; fi
