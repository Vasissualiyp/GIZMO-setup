#!/bin/bash

systemname=$(hostname)
program_to_setup="none"

# Move out of the scripts directory
#cd ..

# Create relevant directories
mkdir archive
mkdir output
mkdir last_job

#Step 1: Choose which repository to clone:{{{
pull_git() {
  # Prompt the user to select which repo to clone
  echo "Which repo do you want to clone?"
  echo "1) Public repo"
  echo "2) Private repo"
  echo "3) Starforge repo"
  echo "m) MUSIC (Cosmological ICs generation)"
  echo "r) Rockstar (Halo Finder)"
  echo "g) GRACKLE (Thermochemistry library)"
  read -p "Enter the number corresponding to your choice: " choice

  # Clone the selected repo
  case $choice in
    1)
    git clone git@bitbucket.org:phopkins/gizmo-public.git gizmo
    program_to_setup="gizmo"
    ;;
  2)
    git clone git@bitbucket.org:phopkins/gizmo.git
    program_to_setup="gizmo"
    ;;
  3)
    git clone git@bitbucket.org:guszejnov/gizmo_imf.git gizmo
    program_to_setup="gizmo"
    ;;
  m)
    # Create temporary directory to store git-tracked parts of music
    mkdir musictmp
    mv -r music/* musictmp/
    git clone git@bitbucket.org:ohahn/music.git
    mv -r musictmp/* music/
    rm -rf musictmp
    cd music
    program_to_setup="music"
    ;;
  r)
    # Create temporary directory to store git-tracked parts of rockstar
    mkdir rockstartmp
    mv -r rockstar/* rockstartmp/
    git clone git@bitbucket.org:gfcstanford/rockstar.git rockstar
    mv -r rockstartmp/* rockstar/
    rm -rf rockstartmp
    cd rockstar
    program_to_setup="rockstar"
    ;;
  g)
    git clone https://github.com/grackle-project/grackle.git grackle
    cp ./template/grackle_makefile_cita ./grackle/src/clib/Make.mach.cita || echo "Failed to clone grackle cita Makefile. Please, copy in manually into grackle/src/clib"
    program_to_setup="grackle"
    ;;
  *)
    echo "Invalid choice. Exiting."
    return 1
    ;;
  esac
} #}}}

pull_git

# Rest of GIZMO setup {{{
if [ "$program_to_setup" == "gizmo" ]; then 
    # Step 2: Alter the Makefile.systype
    cd gizmo
    sed -i '/^[^#]/ s/^/#/' Makefile.systype
    #sed -i '29s/^.//' Makefile.systype
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
    	echo "SYSTYPE=\"SciNet\"" >> Makefile.systype
    else # Sunnyvale
    	echo "SYSTYPE=\"CITA-starq\"" >> Makefile.systype
    
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
    rm -f -r spcool_tables.tgz
    cd gizmo
    
    
    # Step 5: Open Config.sh with vim
    #vim Config.sh
# }}}
elif [ "$program_to_setup" == "music" ]; then 
    module load gcc fftw gsl hdf5
elif [ "$program_to_setup" == "rockstar" ]; then 
    module load gcc
elif [ "$program_to_setup" == "grackle" ]; then 
    module load gcc
fi
