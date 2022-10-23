#!/bin/bash

## utaS02: VBM using ANTs algorithms

### current status #########
sub_id=($(echo $sub_tmp))
{
echo "<td><p id="textelement2">&nbsp;Processing ...&nbsp;</p>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html

## assign variables
ilist=($(echo $ilist_tmp))
temp_path=($(echo $t_tmp))
mni_path=($(echo $m_tmp))
##########################

time_start_02=`date +%s`

echo "
  [utaS02] VBM and Spatial Normalization starting ...

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
echo "<h1><strong><font color="black"><font size="7"><left><em>VBM and Spatial Normalization</em></left></font></font></strong></h1>"
echo "</body>"
echo "<hr color="grey" size="15px"><br>"
}> ${PWD}/${sub_id}_qc_html/${sub_id}_report_vbm.html


############### MAIN RUN ###################
# run
# Brain normalization to MNI
antsRegistration \
          --dimensionality 3 \
          --float 0 \
          --output ${ilist[1]} \
          --interpolation Linear \
          --winsorize-image-intensities [0.005,0.995] \
          --use-histogram-matching 1 \
          --initial-moving-transform [${mni_path}/mni_Brain.nii.gz,${ilist[1]}_brain.nii.gz,1] \
          --transform Rigid[0.1] \
          --metric MI[${mni_path}/mni_Brain.nii.gz,${ilist[1]}_brain.nii.gz,0.7,32,Regular,0.25] \
          --convergence [1000x500x250x100,1e-6,10] \
          --shrink-factors 8x4x2x1 \
          --smoothing-sigmas 3x2x1x0vox \
          --transform Affine[0.1] \
          --metric MI[${mni_path}/mni_Brain.nii.gz,${ilist[1]}_brain.nii.gz,0.7,32,Regular,0.25] \
          --convergence [1000x500x250x100,1e-6,10] \
          --shrink-factors 8x4x2x1 \
          --smoothing-sigmas 3x2x1x0vox \
          --transform SyN[0.1,3,0] \
          --metric CC[${mni_path}/mni_Brain.nii.gz,${ilist[1]}_brain.nii.gz,1,4] \
          --convergence [100x70x50x20,1e-6,10] \
          --shrink-factors 8x4x2x1 \
          --smoothing-sigmas 3x2x1x0vox \
          -v

antsApplyTransforms \
           --dimensionality 3 \
           --input ${ilist[1]}_brain.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ${ilist[1]}_brain_mni.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0

# GM
antsApplyTransforms \
           --dimensionality 3 \
           --input ct_BrainSegmentationPosteriors02.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ${ilist[1]}_mni_gm_ini.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0
# WM
antsApplyTransforms \
           --dimensionality 3 \
           --input ct_BrainSegmentationPosteriors03.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ${ilist[1]}_mni_wm_ini.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0


# GM nonlinear transformation
antsRegistration \
           --dimensionality 3 \
           --float 0 \
           --output gm_mni_init \
           --interpolation Linear \
           --winsorize-image-intensities [0.005,0.995] \
           --use-histogram-matching 1 \
           --initial-moving-transform [${mni_path}/priors2_vbm.nii.gz,${ilist[1]}_mni_gm_ini.nii.gz,1] \
           --transform Rigid[0.1] \
           --metric MI[${mni_path}/priors2_vbm.nii.gz,${ilist[1]}_mni_gm_ini.nii.gz,0.7,32,Regular,0.25] \
           --convergence [1000x500x250x100,1e-6,10] \
           --shrink-factors 8x4x2x1 \
           --smoothing-sigmas 3x2x1x0vox \
           --transform Affine[0.1] \
           --metric MI[${mni_path}/priors2_vbm.nii.gz,${ilist[1]}_mni_gm_ini.nii.gz,0.7,32,Regular,0.25] \
           --convergence [1000x500x250x100,1e-6,10] \
           --shrink-factors 8x4x2x1 \
           --smoothing-sigmas 3x2x1x0vox \
           --transform SyN[0.1,3,0] \
           --metric CC[${mni_path}/priors2_vbm.nii.gz,${ilist[1]}_mni_gm_ini.nii.gz,1,2] \
           --convergence [100x70x50x20,1e-6,10] \
           --shrink-factors 8x4x2x1 \
           --smoothing-sigmas 3x2x1x0vox \
           -v

## apply the transformation
antsApplyTransforms \
           --dimensionality 3 \
           --input ${ilist[1]}_mni_gm_ini.nii.gz \
           --reference-image ${mni_path}/priors2_vbm.nii.gz \
           --output ${ilist[1]}_norm_gm_post.nii.gz \
           --n Linear \
           --transform gm_mni_init1Warp.nii.gz \
           --transform gm_mni_init0GenericAffine.mat \
           --default-value 0

# WM nonlinear transformation
antsRegistration \
           --dimensionality 3 \
           --float 0 \
           --output wm_mni_init \
           --interpolation Linear \
           --winsorize-image-intensities [0.005,0.995] \
           --use-histogram-matching 1 \
           --initial-moving-transform [${mni_path}/priors3_vbm.nii.gz,${ilist[1]}_mni_wm_ini.nii.gz,1] \
           --transform Rigid[0.1] \
           --metric MI[${mni_path}/priors3_vbm.nii.gz,${ilist[1]}_mni_wm_ini.nii.gz,0.7,32,Regular,0.25] \
           --convergence [1000x500x250x100,1e-6,10] \
           --shrink-factors 8x4x2x1 \
           --smoothing-sigmas 3x2x1x0vox \
           --transform Affine[0.1] \
           --metric MI[${mni_path}/priors3_vbm.nii.gz,${ilist[1]}_mni_wm_ini.nii.gz,0.7,32,Regular,0.25] \
           --convergence [1000x500x250x100,1e-6,10] \
           --shrink-factors 8x4x2x1 \
           --smoothing-sigmas 3x2x1x0vox \
           --transform SyN[0.1,3,0] \
           --metric CC[${mni_path}/priors3_vbm.nii.gz,${ilist[1]}_mni_wm_ini.nii.gz,1,2] \
           --convergence [100x70x50x20,1e-6,10] \
           --shrink-factors 8x4x2x1 \
           --smoothing-sigmas 3x2x1x0vox \
           -v
# apply the transformation
antsApplyTransforms \
           --dimensionality 3 \
           --input ${ilist[1]}_mni_wm_ini.nii.gz \
           --reference-image ${mni_path}/priors3_vbm.nii.gz \
           --output ${ilist[1]}_norm_wm_post.nii.gz \
           --n Linear \
           --transform wm_mni_init1Warp.nii.gz \
           --transform wm_mni_init0GenericAffine.mat \
           --default-value 0

## calculate mod1 (initial modulation for GM and WM VBMs)
ComposeMultiTransform 3 ${ilist[1]}compWarp1.nii.gz -R ${mni_path}/mni_Brain.nii.gz \
${ilist[1]}1Warp.nii.gz ${ilist[1]}0GenericAffine.mat

CreateJacobianDeterminantImage 3 ${ilist[1]}compWarp1.nii.gz ${ilist[1]}_mod_ini.nii.gz
fslroi ${ilist[1]}compWarp1.nii.gz ${ilist[1]}compWarp1_single.nii.gz 0 1
fslcpgeom ${ilist[1]}compWarp1_single.nii.gz ${ilist[1]}_mod_ini.nii.gz
# transform initial mod to post mod space
# GM
antsApplyTransforms \
           --dimensionality 3 \
           --input ${ilist[1]}_mod_ini.nii.gz \
           --reference-image ${mni_path}/priors2_vbm.nii.gz \
           --output ${ilist[1]}_mod_gm_iniReg.nii.gz \
           --n Linear \
           --transform gm_mni_init1Warp.nii.gz \
           --transform gm_mni_init0GenericAffine.mat \
           --default-value 0
# WM
antsApplyTransforms \
           --dimensionality 3 \
           --input ${ilist[1]}_mod_ini.nii.gz \
           --reference-image ${mni_path}/priors3_vbm.nii.gz \
           --output ${ilist[1]}_mod_wm_iniReg.nii.gz \
           --n Linear \
           --transform wm_mni_init1Warp.nii.gz \
           --transform wm_mni_init0GenericAffine.mat \
           --default-value 0

# mod2
# GM
ComposeMultiTransform 3 ${ilist[1]}compWarp2_gm.nii.gz -R ${mni_path}/priors2_vbm.nii.gz \
gm_mni_init1Warp.nii.gz gm_mni_init0GenericAffine.mat
CreateJacobianDeterminantImage 3 ${ilist[1]}compWarp2_gm.nii.gz ${ilist[1]}_mod_gm_post.nii.gz
fslroi ${ilist[1]}compWarp2_gm.nii.gz ${ilist[1]}compWarp2_gm_single.nii.gz 0 1
fslcpgeom ${ilist[1]}compWarp2_gm_single.nii.gz ${ilist[1]}_mod_gm_post.nii.gz
rm ${ilist[1]}compWarp2_gm_single.nii.gz

# WM
ComposeMultiTransform 3 ${ilist[1]}compWarp2_wm.nii.gz -R ${mni_path}/priors3_vbm.nii.gz \
wm_mni_init1Warp.nii.gz wm_mni_init0GenericAffine.mat
CreateJacobianDeterminantImage 3 ${ilist[1]}compWarp2_wm.nii.gz ${ilist[1]}_mod_wm_post.nii.gz
fslroi ${ilist[1]}compWarp2_wm.nii.gz ${ilist[1]}compWarp2_wm_single.nii.gz 0 1
fslcpgeom ${ilist[1]}compWarp2_wm_single.nii.gz ${ilist[1]}_mod_wm_post.nii.gz
rm ${ilist[1]}compWarp2_wm_single.nii.gz

# modulation combination
fslmaths ${ilist[1]}_mod_gm_iniReg.nii.gz -mul ${ilist[1]}_mod_gm_post.nii.gz -sqrt ${ilist[1]}_mod_gm_comb.nii.gz
fslmaths ${ilist[1]}_mod_wm_iniReg.nii.gz -mul ${ilist[1]}_mod_wm_post.nii.gz -sqrt ${ilist[1]}_mod_wm_comb.nii.gz

# GM
fslmaths ${ilist[1]}_norm_gm_post.nii.gz -mul ${ilist[1]}_mod_gm_comb ${ilist[1]}_vbm_gm_s0
fslmaths ${ilist[1]}_norm_gm_post.nii.gz -mul ${ilist[1]}_mod_gm_comb -s 3.4 ${ilist[1]}_vbm_gm_s3p4

for i in 2 3 4 ; do
    fslmaths ${ilist[1]}_norm_gm_post.nii.gz -mul ${ilist[1]}_mod_gm_comb -s $i ${ilist[1]}_vbm_gm_s${i}
done
# WM
fslmaths ${ilist[1]}_norm_wm_post.nii.gz -mul ${ilist[1]}_mod_wm_comb ${ilist[1]}_vbm_wm_s0
fslmaths ${ilist[1]}_norm_wm_post.nii.gz -mul ${ilist[1]}_mod_wm_comb -s 3.4 ${ilist[1]}_vbm_wm_s3p4

for j in 2 3 4 ; do
    fslmaths ${ilist[1]}_norm_wm_post.nii.gz -mul ${ilist[1]}_mod_wm_comb -s $i ${ilist[1]}_vbm_wm_s${j}
done

## convert native cortical thickness map to mni space
antsApplyTransforms \
           --dimensionality 3 \
           --input ct_CorticalThickness.nii.gz \
           --reference-image ${mni_path}/mni_Brain.nii.gz \
           --output ${ilist[1]}_CorticalThickness_mni.nii.gz \
           --n Linear \
           --transform ${ilist[1]}1Warp.nii.gz \
           --transform ${ilist[1]}0GenericAffine.mat \
           --default-value 0
#

# QC check image
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_gm1.png ${ilist[1]}_mni_gm_ini.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_gm2.png ${ilist[1]}_vbm_gm_s3p4.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_gm%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_gm.gif
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_wm1.png ${ilist[1]}_mni_wm_ini.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_wm2.png ${ilist[1]}_vbm_wm_s3p4.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_wm%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[1]}_vbm_wm.gif
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_sn1.png ${mni_path}/mni_Brain.nii.gz
fsleyes render -s ortho -hc -of ${PWD}/${sub_id}_qc_img/${ilist[1]}_sn2.png ${ilist[1]}_brain_mni.nii.gz
ffmpeg -i ${PWD}/${sub_id}_qc_img/${ilist[1]}_sn%1d.png -r 5 ${PWD}/${sub_id}_qc_img/${ilist[1]}_sn.gif

{
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} VBM (GM) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_vbm_gm.gif" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} VBM (WM) | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_vbm_wm.gif" Width="100%"><br><br>"
echo "<tr valign=bottom><td align=left>"
echo "<h2><font color="black"><font size="5"><left> | ${sub_id} MNI normalization | </left></font></font></h2>"
echo "<img src="../${sub_id}_qc_img/${ilist[1]}_sn.gif" Width="100%"><br><br>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_vbm.html
################################################

## Check errors ####
if [ ! -f "${ilist[1]}_CorticalThickness_mni.nii.gz" ];then
    {
    echo "<td align=center><font size="5"><b><font color='black'>[ utaS02.sh processing error ] File '${ilist[1]}_CorticalThickness_mni.nii.gz' not found.</b></font><br>"
    }>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_error.html
    exit 1
fi

################################################
echo "
  [utaS02] VBM and Spatial Normalization finised.

"
time_end_02=`date +%s`
time_elapsed_02=$((time_end_02 - time_start_02))
#
{
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/clock.png" WIDTH=60 align="left">"
echo "<font color='black' size="6" align="left"><b>&nbsp;&nbsp;$(( time_elapsed_02 / 60 )) minutes</b></font>"
echo "<hr color="grey" size="3px"><br><br>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_vbm.html

## Computation Time record
{
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement2\").innerHTML = \""Completed\""</script></td>"
  echo "<script type=\"text/javascript\">
    document.getElementById(\"textelement2\").style.color = \""#c91a1a\""</script></td>"
  echo "<td>&nbsp;$(( time_elapsed_02 / 3600 ))h $(( time_elapsed_02 %3600 / 60 ))m&nbsp;</td></tr>"
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html



######################################################################################################################################
