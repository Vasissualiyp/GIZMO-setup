#!/usr/bin/env bash
NOSUBMIT=1 # Set to 0 to ACTUALLY submit jobs
submit_job() {
    script="$1"
    galname="$2"
    restart_flag="$3"
    chain_no="$4"
    dependency="$5"  # optional dependency argument
    
    jobname="SPLITFIRE_${galname}_${chain_no}"
	outdir="logfiles/jeans_refinement"
    output="$outdir/$jobname.log"
	#echo "Submitting job $jobname with output into $output, and chain number $chain_no"
    
	if [[ $NOSUBMIT == 0 ]]; then
        if [[ -n "$dependency" ]]; then
            local jobid=$(sbatch --parsable --job-name=$jobname --output=$output --dependency=afterany:$dependency "$script" "$galname" "$restart_flag" "$chain_no")
        else
            local jobid=$(sbatch --parsable --job-name=$jobname --output=$output "$script" "$galname" "$restart_flag" "$chain_no")
        fi
	else
		jobid=$chain_no
	fi
    
    echo $jobid
}

submit_single_chain() {
	chain_start=$1
	chain_length=$2
	submission_script="$3"
	galname="$4"
	firstrun_restart="$5"
	#echo "Submission params: $1 $2 $3 $4"
	local l_chain_length=$(($chain_length+$chain_start))
	job=$(submit_job "$submission_script" "$galname" "$firstrun_restart" "$chain_start")
	job_string="Submitted job chain: $job"
	curr_chain=$(($chain_start+1))
	while [[ $curr_chain -lt $l_chain_length ]]; do
		job=$(submit_job "$submission_script" "$galname" 1 $curr_chain $job)
		curr_chain=$(($curr_chain+1))
		job_string="$job_string -> $job"
	done
	echo "Galaxy name: $galname"
	echo "$job_string"

}
#galnames="m12f m12q m12b m12c m12m"
galnames="m12q m12c m12m" # 6 nodes
galnames="m12i m12c"
#galnames="m12f"
chain_start=1
chain_length=3
firstrun_restart=0 # Set to 0 if you are starting a new run, set to 1 if you are restarting
submission_script="run_m12ANY.sh"
#submission_script="run_gizmo_shivan_cont.sh"
for galname in $galnames; do
	submit_single_chain "$chain_start" "$chain_length" "$submission_script" "$galname" "$firstrun_restart"
done
