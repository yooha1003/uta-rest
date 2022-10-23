#!/bin/bash

## utaS03: fMRI preprocessing

### current status #########
sub_id=($(echo $sub_tmp))
{
echo "<td><p id="textelement3">&nbsp;Processing ...&nbsp;</p>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html

## assign variables
ilist=($(echo $ilist_tmp))
temp_path=($(echo $t_tmp))
mni_path=($(echo $m_tmp))
##########################

time_start_03=`date +%s`

echo "
  [utaS03] fMRI preprocessing starting ...
"

{
echo "<head>"
echo "<style type="text/css">"
echo "table{background-color:#DCDCDC}"
echo "thead {color:#708090}"
echo "tbody {color:#191970}"
echo "</style>"
echo "</head>"
echo "<body>"
echo "<h1><strong><font color="black"><font size="7"><left><em>fMRI Preprocessing</em></left></font></font></strong></h1>"
echo "</body>"
echo "<hr color="grey" size="15px"><br>"
}> ${PWD}/${sub_id}_qc_html/${sub_id}_report_fmri_preproc.html


############### MAIN RUN ###################
# 3mm masking
flirt -in ${ilist[1]}_brain_mni.nii.gz -ref ${ilist[1]}_brain_mni.nii.gz -applyisoxfm 3 -out ${ilist[1]}_brain_mni_3mm.nii.gz

## excluded 10 points
cp ${ilist[0]}.nii.gz ${ilist[0]}_back.nii.gz
fslroi ${ilist[0]} ${ilist[0]} 10 -1

## EPI extraction
fslmaths ${ilist[0]} -Tmean ${ilist[0]}_mean
bet2 ${ilist[0]}_mean ${ilist[0]}_mean_bet -f 0.3 -w 1.2 | pv -t -N "[${ilist[0]}] image extraction processing time"
fslmaths ${ilist[0]} -mas ${ilist[0]}_mean_bet ${ilist[0]}_ext -odt short
fslroi ${ilist[0]}_ext ${ilist[0]}_mc_ref 0 1

## Despiking
3dcopy ${ilist[0]}_ext.nii.gz ${ilist[0]}_ext
3dDespike ${ilist[0]}_ext+orig.HEAD
3dcopy despike+orig.HEAD ${ilist[0]}_ext_despike.nii.gz

## Slice timing correction
slicetimer -i ${ilist[0]}_ext_despike -o ${ilist[0]}_ext_despike_sl -v | pv -t -N "[${ilist[0]}] slice timing correction processing time" # slice timing correction not interleaved
fslmeants -i ${PWD}/${ilist[0]}_ext_despike.nii.gz -o ${PWD}/${subjid}_qc_img/${ilist[0]}_s1.txt -m ${PWD}/${ilist[0]}_mean_bet.nii.gz
fslmeants -i ${PWD}/${ilist[0]}_ext_despike_sl.nii.gz -o ${PWD}/${subjid}_qc_img/${ilist[0]}_s2.txt -m ${PWD}/${ilist[0]}_mean_bet.nii.gz
paste ${PWD}/${subjid}_qc_img/${ilist[0]}_s1.txt ${PWD}/${subjid}_qc_img/${ilist[0]}_s2.txt | column -s $'\t' -t > ${PWD}/${subjid}_qc_img/${ilist[0]}_sl.txt
fsl_tsplot -i ${PWD}/${subjid}_qc_img/${ilist[0]}_sl.txt -t 'Time Series of EPI' -u 1 --start=1 --finish=2 -y Intensity -x Volumes -a Uncorrected,Corrected -w 1200 -h 300 -o ${PWD}/${subjid}_qc_img/${ilist[0]}_sl.png
fslmaths ${ilist[0]}_ext_despike_sl ${ilist[0]}_ext_despike_sl -odt short

## Motion correction
mkdir -p ${PWD}/MotionCorrectionResults
mcflirt -in ${ilist[0]}_ext_despike_sl -out ${ilist[0]}_ext_despike_sl_mc -reffile ${ilist[0]}_mc_ref -mats -plots -rmsrel -rmsabs -spline_final -report
fsl_tsplot -i ${ilist[0]}_ext_despike_sl_mc.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o ${PWD}/MotionCorrectionResults/${ilist[0]}_rot.png
fsl_tsplot -i ${ilist[0]}_ext_despike_sl_mc.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o ${PWD}/MotionCorrectionResults/${ilist[0]}_trans.png
fsl_tsplot -i ${ilist[0]}_ext_despike_sl_mc_abs.rms,${ilist[0]}_ext_despike_sl_mc_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative \
            -o ${PWD}/MotionCorrectionResults/${ilist[0]}_disp.png
fsl_motion_outliers -i ${ilist[0]}_ext_despike_sl -o ${ilist[0]}_ext_despike_sl_outliers -s ${ilist[0]}_ext_despike_sl_dvars.txt --nomoco --dvars | pv -t -N "${ilist[0]}_ext_despike_sl_dvars.txt is being extracted"
fsl_motion_outliers -i ${ilist[0]}_ext_despike_sl -o ${ilist[0]}_ext_despike_sl_outliers -s ${ilist[0]}_ext_despike_sl_fd.txt --fd | pv -t -N "${ilist[0]}_ext_fd.txt is being extracted"
fslmaths ${ilist[0]}_ext_despike_sl_mc ${ilist[0]}_ext_despike_sl_mc -odt short
mv ${ilist[0]}_ext_despike_sl_mc* ${PWD}/MotionCorrectionResults
mv ${PWD}/MotionCorrectionResults/${ilist[0]}_ext_despike_sl_mc.nii.gz ${PWD}

## EPI to t1w registration
fslmaths ${ilist[0]}_ext_despike_sl_mc -Tmean ${ilist[0]}_ext_despike_sl_mc_mean
epi_res=($(echo `fslval ${ilist[0]}_ext_despike_sl_mc_mean pixdim1`))
ana_res=($(echo `fslval ${ilist[1]} pixdim1`))
flirt -in ${ilist[0]}_ext_despike_sl_mc_mean -ref ${ilist[0]}_ext_despike_sl_mc_mean -applyisoxfm $ana_res -out ${ilist[0]}_ext_despike_sl_mc_mean_resol
flirt -ref ${ilist[1]}_brain -in ${ilist[0]}_ext_despike_sl_mc_mean -dof 12 -nosearch -omat ${ilist[0]}_ext_despike_sl_mc_mean2ana_trans_init.mat
flirt -ref ${ilist[1]}_brain -in ${ilist[0]}_ext_despike_sl_mc_mean -init ${ilist[0]}_ext_despike_sl_mc_mean2ana_trans_init.mat -omat ${ilist[0]}_ext_despike_sl_mc_mean2ana_trans.mat
flirt -ref ${ilist[1]}_brain -in ${ilist[0]}_ext_despike_sl_mc -applyxfm -init ${ilist[0]}_ext_despike_sl_mc_mean2ana_trans.mat -out ${ilist[0]}_ext_despike_sl_mc_reg

## EPI to MNI normalization
antsApplyTransforms \
           --dimensionality 3 \
           -e 3 \
           --input ${ilist[0]}_ext_despike_sl_mc_reg.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ${ilist[0]}_ext_despike_sl_mc_reg_norm.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm.nii.gz ${ilist[0]}_ext_despike_sl_mc_reg_norm.nii.gz -odt short
flirt -in ${ilist[0]}_ext_despike_sl_mc_reg_norm.nii.gz -ref ${ilist[0]}_ext_despike_sl_mc_reg_norm.nii.gz \
      -applyisoxfm 3 -out ${ilist[0]}_ext_despike_sl_mc_reg_norm.nii.gz

## smoothing
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm -s 3 ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm  -odt short

## nuisance signal extraction
fslmeants -i ${ilist[0]}_ext_despike_sl_mc_reg -o ${ilist[0]}_csf.txt -m ct_BrainSegmentationPosteriors01 | pv -t -N "[${ilist[0]}] csf signal extraction time"
fslmeants -i ${ilist[0]}_ext_despike_sl_mc_reg -o ${ilist[0]}_gm.txt -m ct_BrainSegmentationPosteriors02 | pv -t -N "[${ilist[0]}] gm signal extraction time" # wm signal
fslmeants -i ${ilist[0]}_ext_despike_sl_mc_reg -o ${ilist[0]}_wm.txt -m ct_BrainSegmentationPosteriors03 | pv -t -N "[${ilist[0]}] wm signal extraction time" # wm signal
paste ${ilist[0]}_csf.txt ${ilist[0]}_wm.txt ${PWD}/MotionCorrectionResults/${ilist[0]}_ext_despike_sl_mc.par ${ilist[0]}_ext_despike_sl_dvars.txt ${ilist[0]}_ext_despike_sl_fd.txt | column -s $'\t' -t > ${ilist[0]}_nui_reg.mat

# nuisance signal regressor out
fsl_regfilt -i ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm -o ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui -d ${ilist[0]}_nui_reg.mat -f "1,2,3,4,5,6,7,8,9,10" \
  | pv -t -N "[${ilist[0]}] csf+wm+motion signal regression out time" # csf+wm signal regression out
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui -odt short

## Temporal filtering
highfq=0.01
lowfq=0.08
tr=($(echo `fslval ${ilist[0]} pixdim4`))

echo "1/(${tr}*2*${highfq})" | bc -l > high_sig.txt
high_sig=($(cat high_sig.txt))
echo "1/(${tr}*18*${lowfq})" | bc -l > low_sig.txt # matthew's recommendation
low_sig=($(cat low_sig.txt))

fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui -Tmean ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_mean -odt short | pv -t -N "[${ilist[0]}] temporal meaning processing time"
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui -bptf ${high_sig} ${low_sig} \
  -add ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_mean ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp -odt short | pv -t -N "[${ilist[0]}] temporal filtering processing time"
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp -odt short

## tSNR
# normalized original epi
antsApplyTransforms \
           --dimensionality 3 \
           -e 3 \
           --input ${ilist[0]}_ext.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ${ilist[0]}_ext_norm.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0
flirt -in ${ilist[0]}_ext_norm -ref ${ilist[0]}_ext_norm -applyisoxfm 3 -out ${ilist[0]}_ext_norm
fslmaths ${ilist[0]}_ext_norm -s 3 ${ilist[0]}_ext_norm_sm
# extract epi
fslmaths ${ilist[0]}_ext_norm_sm -Tmean ${ilist[0]}_ext_norm_sm_mean
fslmaths ${ilist[0]}_ext_norm_sm -Tstd ${ilist[0]}_ext_norm_sm_std
fslmaths ${ilist[0]}_ext_norm_sm_mean -div ${ilist[0]}_ext_norm_sm_std -mas ${ilist[1]}_brain_mni_3mm.nii.gz ${ilist[0]}_ext_norm_sm_tsnr
# extract and preprocessed epi
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp -Tmean ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_mean
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp -Tstd ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_std
fslmaths ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_mean -div ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_std -mas ${ilist[1]}_brain_mni_3mm.nii.gz ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_tsnr

## QC check image
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[0]}_ext1.png ${ilist[0]}.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[0]}_ext2.png ${ilist[0]}_ext.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[0]}_ext%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[0]}_ext.gif
# reg
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[0]}_reg1.png ${ilist[0]}_ext_despike_sl_mc_reg.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[0]}_reg2.png ${ilist[1]}_brain.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[0]}_reg%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[0]}_reg.gif
#
fsleyes render -s lightbox -zx Z -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[0]}_tsnr1.png ${ilist[0]}_ext_norm_sm_tsnr.nii.gz -cm hot -dr 0 1000
fsleyes render -s lightbox -zx Z -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[0]}_tsnr2.png ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_tsnr.nii.gz -cm hot -dr 0 1000
#
{
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} EPI extraction | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[0]}_ext.gif" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} Motion Correction (displacement, mm) | </left></font></font></h2>"
echo "<img src="../MotionCorrectionResults/${ilist[0]}_disp.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} Motion Correction (rotation, radians) | </left></font></font></h2>"
echo "<img src="../MotionCorrectionResults/${ilist[0]}_rot.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} Motion Correction (translation, mm) | </left></font></font></h2>"
echo "<img src="../MotionCorrectionResults/${ilist[0]}_trans.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} non-corrected EPI (tSNR) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[0]}_tsnr1.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} corrected EPI (tSNR) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[0]}_tsnr2.png" Width="100%"><br><br>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_fmri_preproc.html
################################################

## Check errors ####
if [ ! -f "${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz" ];then
    {
    echo "<td align=center><font size="5"><b><font color='black'>[ utaS03.sh processing error ] File '${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz' not found.</b></font><br>"
    }>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_error.html
    exit 1
fi

################################################
echo "
  [utaS03] fMRI preprocessing Analysis finised.

"
time_end_03=`date +%s`
time_elapsed_03=$((time_end_03 - time_start_03))
#
{
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/clock.png" WIDTH=60 align="left">"
echo "<font color='black' size="6" align="left"><b>&nbsp;&nbsp;$(( time_elapsed_03 / 60 )) minutes</b></font>"
echo "<hr color="grey" size="3px"><br><br>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_fmri_preproc.html

## Computation Time record
{
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement3\").innerHTML = \""Completed\""</script></td>"
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement3\").style.color = \""#c91a1a\""</script></td>"
  echo "<td>&nbsp;$(( time_elapsed_03 / 3600 ))h $(( time_elapsed_03 %3600 / 60 ))m&nbsp;</td></tr>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html



#####################################################################################################################################

## Backup codes ##
## run with afni (old version)
# afni_proc.py -subj_id ${sub_id} \
#              -dsets ${ilist[0]}+orig.HEAD \
#              -copy_anat ${ilist[1]}+orig.HEAD \
#              -blocks despike tshift align tlrc volreg \
#                      blur mask regress \
#              -tcat_remove_first_trs 2 \
#              -volreg_align_e2a \
#              -blur_size 6 \
#              -regress_anaticor_fast \
#              -regress_censor_motion 0.2 \
#              -regress_censor_outliers 0.1 \
#              -regress_bandpass 0.01 0.1 \
#              -regress_apply_mot_types demean deriv \
#              -bash \
#              -regress_run_clustsim no -regress_est_blur_errts
# tcsh -xef proc.test 2>&1 | tee output.proc.test
