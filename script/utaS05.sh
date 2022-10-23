#!/bin/bash

## STEP 05: rs-fMRI analysis

## assign variables
ilist=($(echo $ilist_tmp))
temp_path=($(echo $t_tmp))
mni_path=($(echo $m_tmp))
subjid=($(echo $sub_tmp))
alist=($(echo $alist_tmp))
##########################

### current status #########
{
echo "<td><p id="textelement5">&nbsp;Processing ...&nbsp;</p>"
}>> ${PWD}/${subjid}_qc_html/${subjid}_report_status.html

#
time_start_05=`date +%s`

echo "
  [utaS05] Extracting values from pre-defined atlas ...
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
echo "<h1><strong><font color="black"><font size="7"><left><em>Measurement Extraction</em></left></font></font></strong></h1>"
echo "</body>"
echo "<hr color="grey" size="15px"><br>"
echo "<body>"
}> ${PWD}/${subjid}_qc_html/${subjid}_report_me.html

################ MAIN RUN #####################
# extract rs-measurements
fslmeants -i ${ilist[0]}_VMHC.nii.gz --label=${alist[1]} > ${ilist[0]}_VMHC_aal.txt
fslmeants -i ${ilist[0]}_DC.nii.gz --label=${alist[1]} > ${ilist[0]}_DC_aal.txt
fslmeants -i ${ilist[0]}_ReHo.nii.gz --label=${alist[1]} > ${ilist[0]}_ReHo_aal.txt
fslmeants -i ${ilist[0]}_fALFF.nii.gz --label=${alist[1]} > ${ilist[0]}_fALFF_aal.txt
fslmeants -i ${ilist[0]}_ALFF.nii.gz --label=${alist[1]} > ${ilist[0]}_ALFF_aal.txt
fslmeants -i ${ilist[0]}_RSFA.nii.gz --label=${alist[1]} > ${ilist[0]}_RSFA_aal.txt
fslmeants -i ${ilist[0]}_mRSFA.nii.gz --label=${alist[1]} > ${ilist[0]}_mRSFA_aal.txt
fslmeants -i ${ilist[0]}_fRSFA.nii.gz --label=${alist[1]} > ${ilist[0]}_fRSFA_aal.txt
fslmeants -i ${ilist[0]}_mALFF.nii.gz --label=${alist[1]} > ${ilist[0]}_mALFF_aal.txt
fslmeants -i ${ilist[0]}_3dECM.nii.gz --label=${alist[1]} > ${ilist[0]}_3dECM_aal.txt

# extract cortical thickness and vbm of GM and WM
fslmeants -i ${ilist[1]}_CorticalThickness_mni.nii.gz --label=${alist[0]} > ${ilist[1]}_ct_aal.txt
fslmeants -i ${ilist[1]}_vbm_gm_s3p4.nii.gz --label=${alist[0]} > ${ilist[1]}_vbm_gm_aal.txt
fslmeants -i ${ilist[1]}_vbm_wm_s3p4.nii.gz --label=${alist[2]} > ${ilist[1]}_vbm_wm_aal.txt

# merge files as a single lined text
cat ${ilist[0]}_VMHC_aal.txt ${ilist[0]}_DC_aal.txt \
${ilist[0]}_ReHo_aal.txt ${ilist[0]}_fALFF_aal.txt \
${ilist[0]}_ALFF_aal.txt ${ilist[0]}_RSFA_aal.txt \
${ilist[0]}_mRSFA_aal.txt ${ilist[0]}_fRSFA_aal.txt \
${ilist[0]}_mALFF_aal.txt ${ilist[0]}_3dECM_aal.txt \
${ilist[1]}_ct_aal.txt ${ilist[1]}_vbm_gm_aal.txt ${ilist[1]}_vbm_wm_aal.txt \
 | tr -d '\n' | tr -s '[:blank:]' ',' > ${subjid}_merged.csv

 ## Check errors ####
 if [ ! -f "${subjid}_merged.csv" ];then
     {
     echo "<td align=center><font size="5"><b><font color='black'>[ utaS05.sh processing error ] File '${ilist[1]}_merged.csv' not found.</b></font><br>"
     }>> ${PWD}/${subjid}_qc_html/${subjid}_report_error.html
     exit 1
 fi

 ## QC check image
 fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_atlas_gm.png ${ilist[1]}_vbm_gm_s3p4.nii.gz ${alist[0]} -cm random -a 50
 fsleyes render -s ortho -hc -of ${PWD}/${subjid}_qc_img/${ilist[0]}_atlas_wm.png ${ilist[1]}_vbm_wm_s3p4.nii.gz ${alist[2]} -cm random -a 50

 {
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} GM atlas | </left></font></font></h2>"
 echo "<img src="../${subjid}_qc_img/${ilist[0]}_atlas_gm.png" Width="100%"><br><br>"
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} WM atlas | </left></font></font></h2>"
 echo "<img src="../${subjid}_qc_img/${ilist[0]}_atlas_wm.png" Width="100%"><br><br>"
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} VMHC | </left></font></font></h2>"
 cat ${ilist[0]}_VMHC_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} DC | </left></font></font></h2>"
 cat ${ilist[0]}_DC_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} ReHo | </left></font></font></h2>"
 cat ${ilist[0]}_ReHo_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} fALFF | </left></font></font></h2>"
 cat ${ilist[0]}_fALFF_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} ALFF | </left></font></font></h2>"
 cat ${ilist[0]}_ALFF_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} RSFA | </left></font></font></h2>"
 cat ${ilist[0]}_RSFA_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} mRSFA | </left></font></font></h2>"
 cat ${ilist[0]}_mRSFA_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} fRSFA | </left></font></font></h2>"
 cat ${ilist[0]}_fRSFA_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} mALFF | </left></font></font></h2>"
 cat ${ilist[0]}_mALFF_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} 3dECM | </left></font></font></h2>"
 cat ${ilist[0]}_3dECM_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} cortical thickness | </left></font></font></h2>"
 cat ${ilist[1]}_ct_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} vbm_gm | </left></font></font></h2>"
 cat ${ilist[1]}_vbm_gm_aal.txt
 echo ""
 echo "<tr valign=bottom><td align=left>"
 echo "<h2><font color="black"><font size="5"><left> | ${subjid} vbm_wm | </left></font></font></h2>"
 cat ${ilist[1]}_vbm_wm_aal.txt
 echo ""
}>> ${PWD}/${subjid}_qc_html/${subjid}_report_me.html

 echo "
   [utaS05] Extracting values from pre-defined atlas finised.

 "
 time_end_05=`date +%s`
 time_elapsed_05=$((time_end_05 - time_start_05))
 #
 {
 echo "<br><br>"
 echo "<IMG BORDER=0 SRC="${utaHOME}/icon/clock.png" WIDTH=60 align="left">"
 echo "<font color='black' size="6" align="left"><b>&nbsp;&nbsp;$(( time_elapsed_05 / 60 )) minutes</b></font>"
 echo "<hr color="grey" size="3px"><br><br>"
 }>> ${PWD}/${subjid}_qc_html/${subjid}_report_me.html

 ## Computation Time record
 {
   echo "<script type=\"text/javascript\">
     document.getElementById(\"textelement5\").innerHTML = \""Completed\""</script></td>"
   echo "<script type=\"text/javascript\">
     document.getElementById(\"textelement5\").style.color = \""#c91a1a\""</script></td>"
   echo "<td>&nbsp;$(( time_elapsed_05 / 3600 ))h $(( time_elapsed_05 %3600 / 60 ))m&nbsp;</td></tr>"
 }>> ${PWD}/${subjid}_qc_html/${subjid}_report_status.html






















#
