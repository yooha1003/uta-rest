#!/bin/bash

## STEP 04: rs-fMRI analysis

## assign variables
ilist=($(echo $ilist_tmp))
temp_path=($(echo $t_tmp))
mni_path=($(echo $m_tmp))
subjid=($(echo $sub_tmp))
##########################

### current status #########
{
echo "<td><p id="textelement4">&nbsp;Processing ...&nbsp;</p>"
}>> ${PWD}/${subjid}_qc_html/${subjid}_report_status.html


#
time_start_04=`date +%s`

echo "
  [utaS04] resting-state fMRI analysis starting ...
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
echo "<h1><strong><font color="black"><font size="7"><left><em>rs-fMRI Analysis</em></left></font></font></strong></h1>"
echo "</body>"
echo "<hr color="grey" size="15px"><br>"
echo "<body>"
}> ${PWD}/${subjid}_qc_html/${subjid}_report_rs.html


############### MAIN RUN #####################
# convert to lower resolved image
# mni convert of gm mask
antsApplyTransforms \
           --dimensionality 3 \
           --input ct_BrainSegmentationPosteriors02.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ct_BrainSegmentationPosteriors02_mni.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0
# input
flirt -in ct_BrainSegmentationPosteriors02_mni.nii.gz -ref ct_BrainSegmentationPosteriors02_mni.nii.gz -applyisoxfm 3 -out ct_BrainSegmentationPosteriors02_mni_3mm.nii.gz

## 3dRSFC (except temporal filtering)
3dRSFC -mask ${ilist[1]}_brain_mni_3mm.nii.gz -prefix ${ilist[0]} 0.01 0.1 ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui.nii.gz
3dcopy ${ilist[0]}_mALFF+orig.HEAD ${ilist[0]}_mALFF.nii.gz
3dcopy ${ilist[0]}_fRSFA+orig.HEAD ${ilist[0]}_fRSFA.nii.gz
3dcopy ${ilist[0]}_mRSFA+orig.HEAD ${ilist[0]}_mRSFA.nii.gz
3dcopy ${ilist[0]}_RSFA+orig.HEAD ${ilist[0]}_RSFA.nii.gz
3dcopy ${ilist[0]}_ALFF+orig.HEAD ${ilist[0]}_ALFF.nii.gz
3dcopy ${ilist[0]}_LFF+orig.HEAD ${ilist[0]}_LFF.nii.gz
3dcopy ${ilist[0]}_fALFF+orig.HEAD ${ilist[0]}_fALFF.nii.gz

## 3dReHo
3dReHo -mask ${ilist[1]}_brain_mni_3mm.nii.gz -prefix ${ilist[0]}_ReHo -inset ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz
3dcopy ${ilist[0]}_ReHo+orig.HEAD ${ilist[0]}_ReHo.nii.gz

3dDegreeCentrality
3dDegreeCentrality -prefix ${ilist[i]}_DC -thresh 0.5 -sparsity 1 -mask ct_BrainSegmentationPosteriors02_mni_3mm.nii.gz ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz
3dcopy ${ilist[0]}_DC+orig.HEAD ${ilist[0]}_DC.nii.gz

## 3dLFCD
3dLFCD -prefix ${ilist[0]}_LFCD -mask ${ilist[1]}_brain_mni_3mm.nii.gz ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz
3dcopy ${ilist[0]}_LFCD+orig.HEAD ${ilist[0]}_LFCD.nii.gz

## 3dECM
3dECM -prefix ${ilist[0]}_3dECM -sparsity 1 -mask ${ilist[1]}_brain_mni_3mm.nii.gz ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz
3dcopy ${ilist[0]}_3dECM+orig.HEAD ${ilist[0]}_3dECM.nii.gz

## VMHC
fslswapdim ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz -x y z ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_flip.nii.gz
# caculate vmhc
3dTcorrelate -pearson -polort -1 -prefix ${ilist[0]}_VMHC ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp.nii.gz ${ilist[0]}_ext_despike_sl_mc_reg_norm_sm_nui_temp_flip.nii.gz
3dcopy ${ilist[0]}_VMHC+orig.HEAD ${ilist[0]}_VMHC.nii.gz


## Check errors ####
if [ ! -f "${ilist[0]}_VMHC.nii.gz" ];then
    {
    echo "<td align=center><font size="5"><b><font color='black'>[ utaS04.sh processing error ] File '${ilist[0]}_VMHC.nii.gz' not found.</b></font><br>"
    }>> ${PWD}/${subjid}_qc_html/${subjid}_report_error.html
    exit 1
fi

## QC check image
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_mALFF.png ${ilist[0]}_mALFF.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_fRSFA.png ${ilist[0]}_fRSFA.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_mRSFA.png ${ilist[0]}_mRSFA.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_RSFA.png ${ilist[0]}_RSFA.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_ALFF.png ${ilist[0]}_ALFF.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_LFF.png ${ilist[0]}_LFF.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_fALFF.png ${ilist[0]}_fALFF.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_ReHo.png ${ilist[0]}_ReHo.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_DC.png ${ilist[0]}_DC.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_LFCD.png ${ilist[0]}_LFCD.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_3dECM.png ${ilist[0]}_3dECM.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_VMHC.png ${ilist[0]}_VMHC.nii.gz

{
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} mALFF | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_mALFF.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} fRSFA | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_fRSFA.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} mRSFA | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_mRSFA.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} RSFA | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_RSFA.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} ALFF | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_ALFF.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} LFF | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_LFF.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} fALFF | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_fALFF.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} ReHo | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_ReHo.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} DC | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_DC.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} LFCD | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_LFCD.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} 3dECM | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_3dECM.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${subjid} VMHC | </left></font></font></h2>"
echo "<img src="../${subjid}_qc_img/${ilist[0]}_VMHC.png" Width="100%"><br><br>"
}>> ${PWD}/${subjid}_qc_html/${subjid}_report_rs.html
################################################

################################################
echo "
  [utaS04] resting-state fMRI analysis finised.

"
time_end_04=`date +%s`
time_elapsed_04=$((time_end_04 - time_start_04))
#
{
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/clock.png" WIDTH=60 align="left">"
echo "<font color='black' size="6" align="left"><b>&nbsp;&nbsp;$(( time_elapsed_04 / 60 )) minutes</b></font>"
echo "<hr color="grey" size="3px"><br><br>"
}>> ${PWD}/${subjid}_qc_html/${subjid}_report_me.html

## Computation Time record
{
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement4\").innerHTML = \""Completed\""</script></td>"
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement4\").style.color = \""#c91a1a\""</script></td>"
  echo "<td>&nbsp;$(( time_elapsed_04 / 3600 ))h $(( time_elapsed_04 %3600 / 60 ))m&nbsp;</td></tr>"
}>> ${PWD}/${subjid}_qc_html/${subjid}_report_status.html


















#
