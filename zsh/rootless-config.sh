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

cd
wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz
tar -xvzf ncurses-6.5.tar.gz
rm ncurses-6.5.tar.gz
cd ncurses-6.5
./configure --prefix=$BUILD_PATH --with-termlib --with-shared --with-versioned-syms
make
make install
ln -s /home/rafael.ito/local-build/lib/libncursesw.so.6 /home/rafael.ito/local-build/lib/libtinfo.so.5
echo "export LD_LIBRARY_PATH=$HOME/local-build/lib" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$HOME/local-build/lib" >> ~/.config/zsh/.zshenv
