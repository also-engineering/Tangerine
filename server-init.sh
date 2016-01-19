# editor

# apt-get update
if ! $updated_recently; then
  sudo apt-get update
  export updated_recently=TRUE
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
  sudo apt-get install python-dev -y
  curl -O https://bootstrap.pypa.io/get-pip.py
  sudo python get-pip.py
  sudo pip install couchapp
fi

# hand it over to the gulp file
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dir
npm install

npm start init

cd app
couchapp push
