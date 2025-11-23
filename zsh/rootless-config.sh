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
