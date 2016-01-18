sudo apt-get update

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
