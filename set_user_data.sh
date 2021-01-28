#!/bin/bash

# load the user data
. /etc/sat_data/user.conf

# substitute LOC, LOC_NAME, LOC_COUNTRY in the index
INDEX="/var/www/html/index.php"
sed -i s/"%LOC%"/${LOC}/ ${INDEX}
sed -i s/"%LOC_NAME%"/${LOC_NAME}/ ${INDEX}
sed -i s/"%LOC_COUNTRY%"/${LOC_COUNTRY}/ ${INDEX}
