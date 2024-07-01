#!/usr/bin/env bash

systemname=$(hostname)
program_to_setup="none"

# Move out of the scripts directory
#cd ..

# Create relevant directories
mkdir archive
mkdir output
mkdir last_job

pull_git() {
# Choose which repository to clone and clone it:{{{
  # Prompt the user to select which repo to clone

  echo "--------------------------------------------------"
  echo "Which repo do you want to clone?"
  echo ""
  echo "1) Public gizmo repo"
  echo "2) Private gizmo repo (PRIVATE)"
  echo "3) Starforge gizmo repo (PRIVATE)"
  echo ""
  echo "a) GIZMO analysis"
  echo "m) MUSIC (Cosmological ICs generation)"
  echo "i) PeakPatch-MUSIC Interface"
  echo "r) Rockstar (Halo Finder)"
  echo "g) GRACKLE (Thermochemistry library)"
  echo ""
  echo "p) Peak Patch (PRIVATE)"
  echo "M) MUSIC (Cosmological ICs generation) (PRIVATE)"
  echo "--------------------------------------------------"
  read -p "Enter the number corresponding to your choice: " choice

  # Clone the selected repo
  case $choice in
    1)
    mkdir gizmo
    git clone git@bitbucket.org:phopkins/gizmo-public.git gizmo || echo "Failed to copy GIZMO - make sure to add your machine's ssh key on BitBucket"
    program_to_setup="gizmo"
    ;;
  2)
    mkdir gizmo
    git clone git@bitbucket.org:phopkins/gizmo.git || echo "Failed to copy GIZMO - make sure to add your machine's ssh key on BitBucket"
    program_to_setup="gizmo"
    ;;
  3)
    mkdir gizmo
    git clone git@bitbucket.org:guszejnov/gizmo_imf.git gizmo  || echo "Failed to copy GIZMO - make sure to add your machine's ssh key on BitBucket"
    program_to_setup="gizmo"
    ;;
  a)
    mkdir analysis
    git clone https://github.com/Vasissualiyp/GIZMO-analysis.git analysis  || echo "Failed to git clone the analysis directory"
    program_to_setup="gizmo"
    ;;
  p)
    mkdir peakpatch
    git clone git@gitlab.com:natecarlson/peakpatch.git peakpatch  || echo "Failed to git clone the Peak Patch directory"
    program_to_setup="peakpatch"
    ;;
  m)
    # Create temporary directory to store git-tracked parts of music
    mkdir musictmp
    mv -r music/* musictmp/
    git clone git@bitbucket.org:ohahn/music.git || echo "Failed to git clone music"
    mv -r musictmp/* music/
    rm -rf musictmp
    cd music
    program_to_setup="music"
    ;;
  M)
    # Create temporary directory to store git-tracked parts of music
    mkdir musictmp
    mv -r music/* musictmp/
    git clone git@bitbucket.org:vpustovoit/music.git || echo "Failed to git clone music"
    mv -r musictmp/* music/
    rm -rf musictmp
    cd music
    program_to_setup="music"
    ;;
  i)
    # FIRST, CLONE PeakPatch:
    mkdir peakpatch
    git clone git@gitlab.com:natecarlson/peakpatch.git peakpatch  || echo "Failed to git clone the Peak Patch directory"
    # SECOND, CLONE MUSIC:
    # Create temporary directory to store git-tracked parts of music
    mkdir musictmp
    mv -r music/* musictmp/
    git clone git@bitbucket.org:vpustovoit/music.git || echo "Failed to git clone music"
    mv -r musictmp/* music/
    rm -rf musictmp
    program_to_setup="music+pp"
	# FINALLY, CLONE pp-music-interface:
	git clone https://github.com/Vasissualiyp/pp-music-interface pp-music-interface \
			|| echo "Failed to clone pp-music-interface"
    ;;
  r)
    # Create temporary directory to store git-tracked parts of rockstar
    mkdir rockstartmp
    mv -r rockstar/* rockstartmp/
    git clone https://github.com/Vasissualiyp/rockstar-gizmo.git rockstar || echo "Failed to git clone rockstar"
    mv -r rockstartmp/* rockstar/
    rm -rf rockstartmp
    cd rockstar
    program_to_setup="rockstar"
    ;;
  g)
    git clone https://github.com/grackle-project/grackle.git grackle || echo "Failed to git clone grackle"
    cp ./template/grackle_makefile_cita ./grackle/src/clib/Make.mach.cita || echo "Failed to clone grackle cita Makefile. Please, copy in manually into grackle/src/clib"
    cd grackle
    program_to_setup="grackle"
    ;;
  *)
    echo "Invalid choice. Exiting."
    return 1
    ;;
  esac
#}}}
}

pull_git

if [ "$program_to_setup" == "gizmo" ]; then 
# Rest of GIZMO setup {{{
    # Step 2: Alter the Makefile.systype
    cd gizmo
    sed -i '/^[^#]/ s/^/#/' Makefile.systype
    #sed -i '29s/^.//' Makefile.systype
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
        echo "\nSYSTYPE=\"SciNet\"" >> Makefile.systype
    else # Sunnyvale
        echo "\nSYSTYPE=\"CITA-starq\"" >> Makefile.systype
    
        # Path to the Makefile
        makefile_path="./Makefile"
        
        # Path to the CITA-starqMakefile.txt
        cita_file_path="../template/CITA-starqMakefile.txt"
        
        # Temporary file for the new Makefile
        temp_file_path="../template/temp.txt"
        
        # Use awk to insert the contents of CITA-starqMakefile.txt into Makefile
        awk -v r="$cita_file_path" '
            {
                lines[NR] = $0;
            }
            NR==1 {
                next;
            }
            NR==2 {
                next;
            }
            NR==3 {
                next;
            }
            NR>3 && lines[NR-3] == "ifeq ($(SYSTYPE),\"CITA\")" {
                while ((getline line < r) > 0) {
                    print line
                }
            }
            {
                print lines[NR-3]
            }
            END {
                print lines[NR-1];
                print lines[NR];
            }' "$makefile_path" > "$temp_file_path"
        
        # Replace the original Makefile with the new Makefile
        mv "$temp_file_path" "$makefile_path"
    fi
    
    cp ./cooling/TREECOOL ../TREECOOL
    
    # Step 3: Create Config.sh
    echo "HYDRO_MESHLESS_FINITE_MASS" > Config.sh
    echo "USE_FFTW3" >> Config.sh
    echo "OPENMP=2" >> Config.sh
    echo "MULTIPLEDOMAINS=16" >> Config.sh
    
    # Step 4: Get the spcool tables
    cd ..
    wget http://www.tapir.caltech.edu/~phopkins/public/spcool_tables.tgz
    mkdir -p spcool_tables
    tar -xzvf spcool_tables.tgz -C spcool_tables
    mv spcool_tables/spcool_tables/* ./spcool_tables/
    rm -rf spcool_tables/spcool_tables
    rm -f -r spcool_tables.tgz
    cd gizmo
    
    
    # Step 5: Open Config.sh with vim
    #vim Config.sh
# }}}
elif [ "$program_to_setup" == "music" ]; then 
# Make MUSIC {{{
    module load gcc hdf5 gsl fftw || echo "modules are unavailable for current system"
    make -j20
    cp ../template/*.conf ./
#}}}
elif [ "$program_to_setup" == "music+pp" ]; then 
# Make MUSIC {{{
    cd music
    module load gcc hdf5 gsl fftw python cfitsio || echo "modules are unavailable for current system"
    make -j20
    cp ../template/*.conf ./
	cd .. # Return to main dir
# Make PeakPatch
    source ~/.bashrc
    cd peakpatch || exit 1
    python -m venv env
    source ./env/bin/activate
    pip install matplotlib numpy healpy
    echo "Python environment for Peak Patch has been created"
    echo "The script to make Peak Patch hasn't been set up yet"
	cd .. # Return to main dir
#}}}
elif [ "$program_to_setup" == "rockstar" ]; then 
# Make Rockstar {{{
    module load hdf5 || echo "modules are unavailable for current system"
    sed -i '2iCFLAGS += -I/usr/include/tirpc' Makefile
    sed -i '5iOFLAGS += -ltirpc' Makefile
    make with_hdf5
    cp ../template/rockstar.cfg ./rockstar.cfg
#}}}
elif [ "$program_to_setup" == "grackle" ]; then 
# Make GRACKLE {{{
    ./configure
    cd src/clib
    module load gcc hdf5 || echo "modules are unavailable for current system"
    make clean
    make machine-cita
    make -j20
#}}}
elif [ "$program_to_setup" == "peakpatch" ]; then 
# Make PeakPatch {{{
    source ~/.bashrc
    module load python || echo "modules are unavailable for current system"
    cd peakpatch || exit 1
    python -m venv env
    source ./env/bin/activate
    pip install matplotlib numpy healpy
    echo "Python environment for Peak Patch has been created"
    echo "The script to make Peak Patch hasn't been set up yet"
# }}}
fi
