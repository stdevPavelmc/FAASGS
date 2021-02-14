.DEFAULT_GOAL := help

.PHONY : help run remove clean

PWD = $(shell pwd)

conf: ## Create a configuration directory in /etc/
	sudo mkdir /etc/sat_data || exit 0
	echo "done" > conf

cconf: conf ## Copy the config files
	sudo cp sat_data/* /etc/sat_data/
	sudo chown -R root:root /etc/sat_data
	echo "done" > cconf

wwwt: ## Create the www folders
	sudo mkdir -p /var/www/html/ || exit 0
	sudo rm /var/www/html/index.html || exit 0
	echo "done" > wwwt

cwww: wwwt ## Copy the data to the web folder
	sudo cp -fr www/* /var/www/html/
	sudo mkdir /var/www/html/sat/ || exit 0
	sudo chown -R 33:33 /var/www/
	sudo find /var/www/ -type d -exec chmod 0770 {} \;
	sudo find /var/www/ -type f -exec chmod 0660 {} \;
	echo "done" > cwww

deps: ## Install some tools needed by the software
	sudo apt install -y imagemagick lame sox rtl-sdr librtlsdr0 at sed
	echo "done" > deps

install: deps cconf cwww ## Install the software
	sudo rm /usr/local/bin/sats.sh || exit 0
	sudo ln -s $(PWD)/sat.sh /usr/local/bin/sats.sh
	chmod +x sat.sh
	./set_user_data.sh
	echo "done" > install

permanent: install ## Setup the permanent job at 01 minutes every hour
	sudo cp sat.cron /etc/cron.d/sats
	echo "done" > permanent

remove: ## Remove the software from the PC
	sudo rm -rdf /etc/sat_data || exit 0
	sudo rm /etc/cron.d/sats || exit 0
	sudo rm /etc/cron.d/sat.cron || exit 0
	sudo for i in `atq | awk '{print $1}'`; do sudo atrm $i; done
	echo "== NOTICE ============================================================="
	echo "Data in '/var/www/html' was left intact, remove it yourself if needed"
	echo "======================================================================="

run: install ## Run the software
	/usr/local/bin/sats.sh

clean: ## Clean all the targets to start over
	sudo rm conf || exit 0
	sudo rm cconf || exit 0
	sudo rm wwwt || exit 0
	sudo rm cwww || exit 0
	sudo rm deps || exit 0
	sudo rm install || exit 0
	sudo rm permanent || exit 0

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
