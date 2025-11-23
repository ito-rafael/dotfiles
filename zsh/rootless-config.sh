cd
mkdir local-build
export PATH=/home/rafael.ito/local-build/bin:$PATH
BUILD_PATH=$HOME/local-build

cd
wget ftp.gnu.org/gnu/m4/m4-latest.tar.gz
tar -xvzf m4-latest.tar.gz
rm m4-latest.tar.gz
cd m4-*
./configure --prefix=$BUILD_PATH
make
make install

cd
wget https://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz
tar -xvzf autoconf-*
rm autoconf-latest.tar.gz
cd autoconf-*
./configure --prefix=$BUILD_PATH
make
make install

cd
wget https://ftp.gnu.org/gnu/automake/automake-1.17.tar.gz
tar -xvzf automake-1.17.tar.gz
rm automake-1.17.tar.gz
cd automake-1.17
./configure --prefix=$BUILD_PATH
make
make install
