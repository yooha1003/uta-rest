#!/bin/bash

## utaS01: Cortical Thickness Analysis using antsCorticalThickness.sh

### current status #########
sub_id=($(echo $sub_tmp))

{
echo "<td><p id="textelement1">&nbsp;Processing ...&nbsp;</p>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html

## assign variables
ilist=($(echo $ilist_tmp))
temp_path=($(echo $t_tmp))
##########################

time_start_01=`date +%s`

echo "
  [utaS01] Brain Extraction and Cortical Thickness Analysis starting ...

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
echo "<h1><strong><font color="black"><font size="7"><left><em>Brain Extraction and Cortical Thickness</em></left></font></font></strong></h1>"
echo "</body>"
echo "<hr color="grey" size="15px"><br>"
}> ${PWD}/${sub_id}_qc_html/${sub_id}_report_ct.html

################# MAIN RUN ###################
## check file
# temp_t1w
if [ ! -f ${temp_path}/temp_t1w.nii.gz ]; then
  echo "
  ! Change template T1 image into [temp_t1w.nii.gz]"
else
  echo "
  ## Skip to create input file list"
fi
# temp_prob
if [ ! -f ${temp_path}/temp_prob.nii.gz ]; then
  echo "
  ! Change template probability map into [temp_prob.nii.gz]"
else
  echo "
  ## Skip to create input file list"
fi
# prob%02d
if [ ! -f ${temp_path}/prob01.nii.gz ]; then
  echo "
  ! Change template prob map into [prob01.nii.gz]"
else
  echo "
  ## Skip to create input file list"
fi

############### MAIN RUN ###################
## run
antsCorticalThickness.sh \
            -d 3 \
            -a ${ilist[1]}.nii.gz \
            -e ${temp_path}/temp_t1w.nii.gz \
            -m ${temp_path}/temp_prob.nii.gz \
            -p ${temp_path}/prob%02d.nii.gz \
            -o ct_
# masking for extracted native brain
fslmaths ${ilist[1]}.nii.gz -mas ct_BrainExtractionMask.nii.gz ${ilist[1]}_brain.nii.gz
# move file to _qc_img
mv ct_CorticalThicknessTiledMosaic.png ${PWD}/${sub_id}_qc_img
mv ct_BrainSegmentationTiledMosaic.png ${PWD}/${sub_id}_qc_img
rm -r ct_
rm -r ct_Brain
#
# QC check image
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss.png ${ilist[1]}.nii.gz ${ilist[1]}_brain.nii.gz -cm green -a 70
fsleyes render -s lightbox -zx X -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_x1.png ${ilist[1]}.nii.gz
fsleyes render -s lightbox -zx X -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_x2.png ${ilist[1]}_brain.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_x%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_x.gif
fsleyes render -s lightbox -zx Y -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_y1.png ${ilist[1]}.nii.gz
fsleyes render -s lightbox -zx Y -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_y2.png ${ilist[1]}_brain.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_y%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_y.gif
fsleyes render -s lightbox -zx Z -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_z1.png ${ilist[1]}.nii.gz
fsleyes render -s lightbox -zx Z -ss 10 -nc 6 -nr 3 -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_z2.png ${ilist[1]}_brain.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_z%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[1]}_ss_z.gif

{
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id}_Brain | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_ss.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id}_Brain (SAG) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_ss_x.gif" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id}_Brain (COR) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_ss_y.gif" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id}_Brain (TRA) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_ss_z.gif" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id}_segmentation | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/ct_BrainSegmentationTiledMosaic.png" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id}_cortical thickness | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/ct_CorticalThicknessTiledMosaic.png" Width="100%"><br><br>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_ct.html
################################################

## Check errors ####
if [ ! -f "${ilist[1]}_brain.nii.gz" ];then
    {
    echo "<td align=center><font size="5"><b><font color='black'>[ utaS01.sh processing error ] File '${ilist[1]}_brain.nii.gz' not found.</b></font><br>"
    }>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_error.html
    exit 1
fi

################################################
echo "
  [utaS01] Brain Extraction and Cortical Thickness Analysis finised.

"
time_end_01=`date +%s`
time_elapsed_01=$((time_end_01 - time_start_01))
#
{
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/clock.png" WIDTH=60 align="left">"
echo "<font color='black' size="6" align="left"><b>&nbsp;&nbsp;$(( time_elapsed_01 / 60 )) minutes</b></font>"
echo "<hr color="grey" size="3px"><br><br>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_ct.html

## Computation Time record
{
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement1\").innerHTML = \""Completed\""</script></td>"
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement1\").style.color = \""#c91a1a\""</script></td>"
  echo "<td>&nbsp;$(( time_elapsed_01 / 3600 ))h $(( time_elapsed_01 %3600 / 60 ))m&nbsp;</td></tr>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html

######################################################################################################################################
