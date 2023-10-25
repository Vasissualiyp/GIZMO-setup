#!/bin/bash

systemname=$(hostname)

# Move out of the scripts directory
#cd ..
mkdir archive
mkdir output
mkdir last_job

#Step 1: Choose which repository to clone:{{{
pull_gizmo() {
  # Prompt the user to select which repo to clone
  echo "Which repo do you want to clone?"
  echo "1) Public repo"
  echo "2) Private repo"
  echo "3) Starforge repo"
  read -p "Enter the number corresponding to your choice: " choice

  # Clone the selected repo
  case $choice in
    1)
      git clone git@bitbucket.org:phopkins/gizmo-public.git gizmo
      ;;
    2)
      git clone git@bitbucket.org:phopkins/gizmo.git
      ;;
    3)
      git clone git@bitbucket.org:guszejnov/gizmo_imf.git gizmo
      ;;
    *)
      echo "Invalid choice. Exiting."
      return 1
      ;;
  esac
} #}}}

pull_gizmo

# Step 2: Alter the Makefile.systype
cd gizmo
sed -i '/^[^#]/ s/^/#/' Makefile.systype
#sed -i '29s/^.//' Makefile.systype
if [ "$systemname" == "niagara" ]; then
	echo "SYSTYPE=\"SciNet\"" >> Makefile.systype
elif [ "$systemname" == "starq" ]; then
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

