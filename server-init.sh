sudo apt-get update

# couchdb
which_couchdb=`which couchdb`
if [ ! -z "$which_couchdb" ]; then
  echo "CouchDB already installed"
else
  sudo apt-get install python-software-properties
  sudo apt-add-repository ppa:couchdb/stable
  sudo apt-get update
  sudo apt-get install couchdb couchdb-bin couchdb-common -y
  sudo service couchdb start
fi

# curl
which_curl=`which curl`
if [ ! -z "$which_curl" ]; then
  echo "curl already installed"
else
  sudo apt-get install curl -y
fi

# couchapp
which_couchapp=`which couchapp`
if [ ! -z "$which_couchapp" ]; then
  echo "couchapp already installed"
else
  curl -O https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py
  pip install couchapp
fi

# hand it over to the gulp file
npm start init
