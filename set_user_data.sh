#!/bin/bash

# load the user data
. /etc/sat_data/user.conf

# substitute LOC, LOC_NAME, LOC_COUNTRY in the index
sed -i s/"%LOC%"/${LOC}/ /etc/var/www/html/index.php
sed -i s/"%LOC_NAME%"/${LOC_NAME}/ /etc/var/www/html/index.php
sed -i s/"%LOC_COUNTRY%"/${LOC_COUNTRY}/ /etc/var/www/html/index.php
