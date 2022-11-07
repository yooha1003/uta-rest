#!/bin/bash

Usage() {
  echo "
* * * * * * * * * * * * * * * * * * * * * * * * * * * *  uta-rest.sh  * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    (U)nified toolbox for the (T)ailored (A)nalysis of (RE)sting-state functional and (S)tructural MRI datase(T) "

  echo ""
  echo "
  [Example Usage]"
  echo "  uta-rest.sh --subjid=subject01 \ "
  echo "              --atlas=atlas_list.txt \ "
  echo "              --template=../bin/template \ "
  echo "              --mni=../bin/mni \ "
  echo "              --proc=proc_list.txt "
  echo "
  [Description]
      --subjid  :  string                      subject ID
      --atlas   :  text file                   a single column list of file names without extension
      --template:  string                      a directory path of specific template
      --mni     :  string                      a directory path of MNI template
      --proc    :  text file                   processing numbering with space "

  echo "
  [Scripts]
      [01]  utaS01.sh: Brain extraction and cortical thickness analysis using ANTs
      [02]  utaS02.sh: VBM analysis and spatial normalization using customized strategy (Choi et al., 2021)
      [06]  utaS03.sh: fMRI data preprocessing
      [07]  utaS04.sh: rs-fMRI map construction using AFNI
      [08]  utaS05.sh: Atlas based data extraction and merged into a single csv file (default = AAL3 and DKT)

  [Version History]
    Version 0.11:  modified main script for dataset without 'rest.nii.gz' (2022.11.7.)
    Version 0.10:  the script release (2022.10.25.)

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * ** * * * * * * * * * * * * * * *  "

echo ""
exit
}
[ "$2" = "" ] && Usage

## parameter check
get_opt1() {
    arg=`echo $1 | sed 's/=.*//'`
    echo $arg
}

get_arg1() {
    if [ X`echo $1 | grep '='` = X ] ; then
	echo "Option $1 requires an argument" 1>&2
	exit 1
    else
	arg=`echo $1 | sed 's/.*=//'`
	if [ X$arg = X ] ; then
	    echo "Option $1 requires an argument" 1>&2
	    exit 1
	fi
	echo $arg
    fi
}

## set the inputs
sub_id="";
atlas_list="";
temp_path="";
mni_path="";
proc_list="";

## input check
if [ $# -eq 0 ] ; then Usage; exit 1; fi
if [ $# -lt 3 ] ; then Usage; exit 1; fi
while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;
    case "$iarg"
	in
  --subjid)
      sub_id=`get_arg1 $1`;
      shift;;
  --atlas)
      atlas_list=`get_arg1 $1`;
      shift;;
  --template)
      temp_path=`get_arg1 $1`;
      shift;;
  --mni)
	    mni_path=`get_arg1 $1`;
	    shift;;
  --proc)
      proc_list=`get_arg1 $1`;
      shift;;
	-h)
	    Usage;
	    exit 0;;
	*)
	    echo "Unrecognised parameter $1" 1>&2
	    exit 1
    esac
done

## time_start
time_start_main=`date +%s`

################ preparation #######################################################################################################
## create input list file
# first check for rest.nii.gz file
if [ -f "$PWD/${sub_id}_rest.nii.gz" ]; then
  echo "[Check] *_rest.nii.gz was found "
else
  echo "No rest.nii.gz file was found, the empty file is being constructed"
  touch $PWD/${sub_id}_rest.nii.gz
fi

# file list check
if [ -f "$PWD/${sub_id}_input_list.txt" ]; then
  echo "
  ## Skip to create input file list"
else
  ls | sed -n 's/\.nii.gz$//p' > $PWD/${sub_id}_input_list.txt
fi
# check input Files
echo ""
echo "@Input file check"
ilist=($(cat $PWD/${sub_id}_input_list.txt))

if [ ${ilist[0]:(-4)} = "rest" ]; then
  echo "[OK] *_rest.nii.gz was found "
else
  echo "[ERROR] Check *_rest.nii.gz file name "
  exit 1
fi
#
if [ ${ilist[1]:(-2)} = "t1" ]; then
  echo "[OK] *_t1.nii.gz was found "
else
  echo "[ERROR] Check *_t1.nii.gz file name "
  exit 1
fi

# load files
alist=($(cat ${atlas_list}))
plist=($(cat ${proc_list}))

ilist_tmp=${ilist[@]}
alist_tmp=${alist[@]}
t_tmp=${temp_path}
m_tmp=${mni_path}
sub_tmp=${sub_id}

export ilist_tmp
export alist_tmp
export t_tmp
export m_tmp
export sub_tmp
export proc_list
export utaHOME=/home/jeong/abin/uta-rest
####################################################################################################################################

################################################# Check dependencies ###############################################################
#### check software dependencies
echo ""
echo "@Software check"
# software 01
if command -v fsl >/dev/null 2>&1 ; then
    echo "[OK] 'FSL' found"
else
    echo "[ERROR] FSL not found, please install before running this script"
    exit 1
fi

# software 02
if command -v antsRegistration >/dev/null 2>&1 ; then
    echo "[OK] 'ANTs' found"
else
    echo "[ERROR] ANTs not found, please install before running this script"
    exit 1
fi

# software 03
if command -v 3dRSFC >/dev/null 2>&1 ; then
    echo "[OK] 'AFNI' found"
else
    echo "[ERROR] AFNI not found, please install before running this script"
    exit 1
fi

# software 04
if command -v pv >/dev/null 2>&1 ; then
    echo "[OK] 'pv' bash module found"
else
    echo "[ERROR] 'pv' bash module not found, please install before running this script"
    exit 1
fi

#### check script dependencies
echo ""
echo "@Scripts check"
# script 01
if command -v antsCorticalThickness.sh >/dev/null 2>&1 ; then
    echo "[OK] 'antsCorticalThickness.sh' found"
else
    echo "[ERROR] antsCorticalThickness.sh not found, please install before running this script"
    exit 1
fi

################################# Set report HTML #################################
mkdir -p ${PWD}/${sub_id}_qc_html
mkdir -p ${PWD}/${sub_id}_qc_img

{
echo "<html>"
echo "<!--Softwares and CiNet logos-->"
echo "<p><body>"
echo "<hr color="black" size="2px">"
echo "<h1><B><font color="black"><font size="5">&nbsp;&nbsp;Dependency Softwares</font></font></B></h1>"
echo "<hr color="black" size="2px"></body>"
echo "<body>"
echo "<TD ALIGN=LEFT>"
echo "<a href=\"http://www.fmrib.ox.ac.uk/fsl\"" target=\"_top\"">"
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/fsl.jpeg" WIDTH=120></a>"
echo "</TD> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
echo "<TD ALIGN=CENTER>"
echo "<a href=\"http://stnava.github.io/ANTs/\"" target=\"_top\"">"
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/ants.png" WIDTH=190></a>"
echo "</TD>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
echo "<TD ALIGN=CENTER>"
echo "<a href=\"https://afni.nimh.nih.gov/\"" target=\"_top\"">"
echo "<IMG BORDER=0 SRC="${utaHOME}/icon/afni.jpeg" WIDTH=90></a>"
echo "</TD>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
echo "</TD>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</p></body>"
echo "<body>"
echo "<hr color="grey" size="2px">"
echo "</body>"
echo "<style type="text/css">"
echo "</style>"
####################################################################################################
echo "<div style=width:"13%" float:"left">"
echo "<table BORDER=1 align="left" width="400">"
echo "<tr><td align=center><font size="5"><b><font color='red'>&nbsp;</font>${sub_id}_report<font color="blue"><font size="3">&nbsp;&nbsp;&nbsp;<br><em>Ver 0.10</em></br></font></font></b></font></tr>"
echo "<tr valign=bottom><td align=left>"
echo "<ul><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_status.html"><li><font size="4"><font color='blue'> Processing Status</font></li></A><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_error.html"><li><font size="4"><font color='red'> Error Reports</font></font></li></A><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_ct.html"><li><font size="4"> Brain Extraction and Cortical Thickness</font></li></A><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_vbm.html"><li><font size="4"> VBM and Spatial Normalization</li></A><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_fmri_preproc.html"><li><font size="4"> fMRI Preprocessing</font></li></A><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_rs.html"><li><font size="4"> rs-fMRI Analysis</font></li></A><br>"
echo "<A HREF="./${sub_id}_qc_html/${sub_id}_report_me.html"><li><font size="4"> Measurement Extraction</font></li></A><br>"
echo "</tr></table></div>"
}> ${sub_id}_report.html
#############################################################################################################################################################################################################

########################## files information html ####################################################################
{
  echo "<div><table border=1 align=left width=100>"
  echo "<tr><td align=center>"
  echo "<A HREF=./${sub_id}_qc_html/${sub_id}_input_info.html><IMG BORDER=0 SRC=${utaHOME}/icon/input.png WIDTH=100></tr></table></div>"
}>> ${sub_id}_report.html

########### ${sub_id}_input_info.html ########################################################################
{
echo "<head>"
echo "<style type="text/css">"
# echo "table{background-color:#DCDCDC}"
echo "thead {color:#708090}"
echo "tbody {color:#191970}"
echo "</style>"
echo "</head>"
echo "<body>"
echo "<h1><strong><font color="black"><font size="7"><left><em>Input Information</em></left></font></font></strong></h1>"
echo "</body>"
echo "<body><hr color="grey" size="15px"></body><br>"
echo "
<table border="1" align="left" width="1500" height="300" bordercolor="black">
    <thead>
        <tr>
           	<th bgcolor="white"><font size="5"><b><font color='black'>No.</th>
            <th bgcolor="white"><font size="5"><b><font color='black'>Input Files</th>
            <th bgcolor="white"><font size="5"><b><font color='black'>Header Info</th>
            <th bgcolor="white"><font size="5"><b><font color='black'>View</th>
        </tr>
    </thead>
    <tbody>
"
}> ${PWD}/${sub_id}_qc_html/${sub_id}_input_info.html

################ start to write #####################

## extract file Information and writing ${sub_id}_input_info.html
for (( i=0;i<$((${#ilist[@]})); i++ ))
do
  if [ "${ilist[i]}" == "0" ];then
    echo "  ### Skip to process [$((i+1))]th image
    "
  else
    # figures
    if [ ! -f $PWD/${sub_id}_qc_img/${ilist[i]}_ortho.png ]; then
      fsleyes render -s ortho -hc -of $PWD/${sub_id}_qc_img/${ilist[i]}_ortho.png ${ilist[i]}.nii.gz
    else
      echo " ## Skip to make figures
      "
    fi
    # extractio header info
    i_dimx=($(echo `fslval ${ilist[i]} dim1`))
    i_dimy=($(echo `fslval ${ilist[i]} dim2`))
    i_dimz=($(echo `fslval ${ilist[i]} dim3`))
    i_dimv=($(echo `fslval ${ilist[i]} dim4`))
    i_pixdimx=($(echo `fslval ${ilist[i]} pixdim1`))
    i_pixdimy=($(echo `fslval ${ilist[i]} pixdim2`))
    i_pixdimz=($(echo `fslval ${ilist[i]} pixdim3`))
    i_orientx=($(echo `fslval ${ilist[i]} sform_xorient`))
    i_orienty=($(echo `fslval ${ilist[i]} sform_yorient`))
    i_orientz=($(echo `fslval ${ilist[i]} sform_zorient`))
    stepN=`echo "$i+1" | bc`
    ## html writing
    {
      echo "<tr><td ALIGN=CENTER><font size="4">${stepN}</font></td>"
      echo "<td ALIGN=CENTER><font size="4">${ilist[i]}.nii.gz</font></td>"
      echo "<td><ul><li>Matrix = ${i_dimx} x ${i_dimy} x ${i_dimz} x ${i_dimv}</li>"
      echo "<li>Resolution = ${i_pixdimx} x ${i_pixdimy} x ${i_pixdimz}</li>"
      echo "<li>X-Orientation = ${i_orientx}</li>"
      echo "<li>Y-Orientation = ${i_orienty}</li>"
      echo "<li>Z-Orientation = ${i_orientz}</li></td>"
      echo "<td ALIGN=CENTER><img src="../${sub_id}_qc_img/${ilist[i]}_ortho.png" Width="100%"></font></td>"
    }>> ${PWD}/${sub_id}_qc_html/${sub_id}_input_info.html
  fi
done


######################### Preprocessing Steps description ############################################################
{
echo "<div style=width:"85%" float:"center">"
echo "
<table border="1" align="bottom" width="800">
    <thead>
        <tr>
           	<th bgcolor="white"><font size="3"><b><font color='black'>&nbsp;Step #&nbsp;</th>
            <th bgcolor="white"><font size="3"><b><font color='black'>&nbsp;Script Name&nbsp;</th>
            <th bgcolor="white"><font size="3"><b><font color='black'>&nbsp;Description&nbsp;</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><center>[1]</td>
            <td><center>utaS01.sh</td>
            <td>Brain extraction and cortical thicknes analysis using ANTs script</td>
        </tr>
        <tr>
            <td><center>[2]</td>
            <td><center>utaS02.sh</td>
            <td>In-house VBM analysis and spatial normalization using ANTs</td>
        </tr>
        <tr>
            <td><center>[3]</td>
            <td><center>utaS03.sh</td>
            <td>fMRI preprocessing adopting afni_proc pipeline</td>
        </tr>
        <tr>
            <td><center>[4]</td>
            <td><center>utaS04.sh</td>
            <td>rs-fMRI measurement calculation using AFNI</td>
        </tr>
        <tr>
            <td><center>[5]</td>
            <td><center>utaS05.sh</td>
            <td>Extract measurements and merged into a single csv file</td>
        </tr>
    </tbody></table></div><br><br><br><br><br><br>"

    ## copyright
}>> ${sub_id}_report.html
################################################################################################################################

### copyright
{
  echo "<body>"
  echo "<hr color="grey" size="2px">"
  echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=mailto:qtwing@naver.com>""<IMG BORDER=0 SRC="${utaHOME}/icon/email.png" WIDTH=60></a>"
  echo "</body>"
  echo "<hr color="grey" size="1px">"
  echo "<table align="center">"
  echo "<font color="black" size="4" align="right"><em><b>"
  echo "&nbsp;&nbsp;&nbsp;&#169;2022 Choi Uksu All Rights Reserved</b></em></font></table>"
  echo "<hr color="grey" size="2px"></p>"
  echo "<br>"
}>> ${sub_id}_report.html


######################### Processing Status ${sub_id}_report ############################################################
{
echo "<head>"
echo "<style type="text/css">"
# echo "table{background-color:#DCDCDC}"
echo "thead {color:#708090}"
echo "tbody {color:#191970}"
echo "</style>"
echo "</head>"
echo "<body>"
echo "<h1><strong><font color="black"><font size="7"><left><em>Processing Status</em></left></font></font></strong></h1>"
echo "</body>"
echo "<body><hr color="grey" size="15px"></body><br>"
echo "<h2><font color="blue">Selected Steps: ${plist[@]}</font></h2><br>"
echo "
<table border="1" align="left" width="1000" height="100" bordercolor="black">
    <thead>
        <tr>
           	<th bgcolor="white"><font size="5"><b><font color='black'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;No.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th bgcolor="white"><font size="5"><b><font color='black'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Processing Steps&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th bgcolor="white"><font size="5"><b><font color='black'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Status&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</th>
            <th bgcolor="white"><font size="5"><b><font color='black'>&nbsp;&nbsp;Computation Time&nbsp;&nbsp;</th>
        </tr>
    </thead>
    <tbody>
"
}> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html

######################### Error ${sub_id}_report ############################################################
{
echo "<head>"
echo "<style type="text/css">"
echo "table{background-color:#DCDCDC}"
echo "thead {color:#708090}"
echo "tbody {color:#191970}"
echo "</style>"
echo "</head>"
echo "<body>"
echo "<h1><strong><font color="black"><font size="7"><left><em>Error Messages</em></left></font></font></strong></h1>"
echo "</body>"
echo "<hr color="grey" size="15px"><br>"
}> ${PWD}/${sub_id}_qc_html/${sub_id}_report_error.html
###################################################################################################################



########################################## RUN ###################################################################
## backup raw data
mkdir -p $PWD/${sub_id}_rawData

for (( i=0;i<$((${#ilist[@]})); i++ ))
do
  if [ "${ilist[i]}" == "0" ];then
    echo "  ### Skip to copy [$((i+1))]th image
    "
  else
    cp ${ilist[i]}.nii.gz $PWD/${sub_id}_rawData
  fi
done

# copy
cp ${input_list} ${atlas_list} ${proc_list} $PWD/${sub_id}_rawData

## run Steps
ls ${utaHOME}/script/utaS*.sh > ${sub_id}Step.txt
slist=($(cat ${sub_id}Step.txt))

for (( i=0;i<$((${#plist[@]})); i++ ))
do
  # Error checking and exist before next utaSPip processing step
  Err=$( grep -i "not found" ${PWD}/${sub_id}_qc_html/${sub_id}_report_error.html )
  if [[ ! -z $Err ]]; then
    echo "    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    ++++ [Warning] Some problem was found, we stopped the entire process ++++

    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    exit 1
  else
    {
      echo "<tr><td ALIGN=CENTER><font size="4">${plist[i]}</font></td>"
      echo "<td>${slist[${plist[i]}-1]}</td>"
    }>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html
    ${slist[${plist[i]}-1]}
  fi
done


###################################################################################################################

# time end
time_end_main=`date +%s`
time_elapsed=$((time_end_main - time_start_main))

######### Total time table #############333
{
  echo "</tr></tbody><br>"
  echo "
  <table border="1" align="left" width="1000" height="100" bordercolor="black">
    <tbody>
        <tr>
            <td><font size="5"><b><font color='red'>&nbsp;&nbsp;Total&nbsp;&nbsp;</b></font></td>
            <td><font size="5"><b><font color='red'>&nbsp;&nbsp;$(( time_elapsed / 3600 ))H $(( time_elapsed %3600 / 60 ))M&nbsp;&nbsp;</b></font></td>
        </tr>
    </tbody>
  </table>
  <tbody>
  "
}>> ${PWD}/${sub_id}_qc_html/${sub_id}_report_status.html

echo
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * "
echo "       >>>>>>>>>>     Congratulation!! All process finished     <<<<<<<<<<<        "
echo " All process was finished in $time_elapsed seconds"
echo " $(( time_elapsed / 3600 ))h $(( time_elapsed %3600 / 60 ))m $(( time_elapsed % 60 ))s"
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * "

####################################################################################################################################
