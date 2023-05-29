#Step 1: Clone the repository
git clone git@bitbucket.org:phopkins/gizmo.git

# Step 2: Alter the Makefile.systype
cd gizmo
sed -i '/^[^#]/ s/^/#/' Makefile.systype
sed -i '29s/^.//' Makefile.systype

cp TREECOOL ../TREECOOL

# Step 3: Create Config.sh
echo "HYDRO_MESHLESS_FINITE_MASS" > Config.sh
echo "USE_FFTW3" >> Config.sh
echo "OPENMP=2" >> Config.sh
echo "MULTIPLEDOMAINS=16" >> Config.sh

# Step 4: Open Config.sh with vim
vim Config.sh

