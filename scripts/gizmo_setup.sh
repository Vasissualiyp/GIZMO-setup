#!/bin/bash

systemname=$(hostname)

# Move out of the scripts directory
#cd ..
mkdir archive
mkdir output
mkdir last_job

#Step 1: Choose which repository to clone:{{{
#Clone public repo
#git clone git@bitbucket.org:phopkins/gizmo-public.git
#mv -f gizmo-public gizmo
# OR
#Clone private repo
git clone git@bitbucket.org:phopkins/gizmo.git
#}}}

if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then
	systemname="niagara"
else
	systemname="starq"
fi


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

# Step 4: Open Config.sh with vim
vim Config.sh

