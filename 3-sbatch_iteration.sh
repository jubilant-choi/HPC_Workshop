sbatch_script="3-systematic_sbatch.sh"

curr_date=$(date +'%y%m%d-%H%M')
job_name="${curr_date}_systematic_lr_wd_maskratio"

lrs=(1e-1 1e-2)
weight_decays=(1e-1 1e-2)
mask_ratios=(0.4 0.8)

for lr in "${lrs[@]}"; do
    for wd in "${weight_decays[@]}"; do
        for mask_ratio in "${mask_ratios[@]}"; do
            sbatch --job-name="${job_name}" "${sbatch_script}" $lr $wd $mask_ratio
        done
    done
done