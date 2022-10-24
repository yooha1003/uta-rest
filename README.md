# <font size=5><br>_**<font color=red>UTA-REST</br></font> <font size=4><font color=red>(U)</font>nified toolbox for <font color=red>(T)</font>ailored <font color=red>(A)</font>nalysis of <font color=red>(RE)</font>sting-state functional and <font color=red>(S)</font>tructural MRI datase<font color=red>(T)</font>**_</font>

## <font color=green>_Feature_</font>
<font size=4>An easy and powerful pipeline script for resting-state fMRI dataset
+ [uta01]: Brain extraction and cortical thickness analysis using ANTs


![CNEO_001_t1_ss](/assets/CNEO_001_t1_ss.png)
![ct_CorticalThicknessTiledMosaic](/assets/ct_CorticalThicknessTiledMosaic.png)  
+ [uta02]: VBM analysis and spatial normalization using customized strategy [(Choi et al., 2021)](https://academic.oup.com/cercorcomms/article/2/2/tgab037/6290107)


![CNEO_001_t1_vbm_gm](/assets/CNEO_001_t1_vbm_gm.gif)![CNEO_001_t1_vbm_wm](/assets/CNEO_001_t1_vbm_wm.gif)
+ [uta03]: fMRI data preprocessing


![CNEO_001_rest_ext](/assets/CNEO_001_rest_ext_6yqq9wupj.gif)
+ [uta04]: rs-fMRI map construction using AFNI


![CNEO_001_rest_mALFF](/assets/CNEO_001_rest_mALFF.png)
+ [uta05]: Atlas based data extraction and merged into a single csv file (default = AAL3 and DKT)

![CNEO_001_rest_atlas_gm](/assets/CNEO_001_rest_atlas_gm.png)
![CNEO_001_rest_atlas_wm](/assets/CNEO_001_rest_atlas_wm.png)


## <font color=yellow>Description</font>
+ Shell based script program
+ The script is very simple to use and robust
+ The script includes commonly used structural and functional MRI data analysis
+ Outputs are extracted functional and structural measurements from defined atlases
+ UTA-REST v1.0 supports rs-fMRI analysis of child dataset using [nihpd template](https://www.mcgill.ca/bic/software/tools-data-analysis/anatomical-mri/atlases/nihpd)

## Requirements
### &nbsp;_Softwares_
+ [AFNI](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/index.html)
+ [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation)
+ [ANTs](http://stnava.github.io/ANTs/)

### &nbsp;&nbsp;_Script_
+ antsCorticalThickness.sh

## Preparation
+ Atlas text file  
![Screen Shot 2022-10-23 at 11.08.20 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.08.20%20PM.png)
+ Template images  
![Screen Shot 2022-10-23 at 11.10.49 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.10.49%20PM.png)
+ MNI spaced images (included in UTA-REST)  
![Screen Shot 2022-10-23 at 11.26.06 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.26.06%20PM.png)
+ Processing step text file  
![Screen Shot 2022-10-23 at 11.17.56 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.17.56%20PM.png)

## Usage
+ <b>Run</b>
```
uta-rest.sh --subjid=subject01 \
            --atlas=atlas_list.txt \
            --template=../bin/template \
            --mni=../bin/mni \
            --proc=proc.txt
```

+ <b>Help</b>
```
uta-rest.sh --help
```
![Screen Shot 2022-10-23 at 5.58.56 PM](/assets/Screen%20Shot%202022-10-23%20at%205.58.56%20PM.png)  

## Inputs
+ MRI dataset (structural and rs-functional) with fixed names
![Screen Shot 2022-10-24 at 6.35.16 PM](/assets/Screen%20Shot%202022-10-24%20at%206.35.16%20PM_wd15ynpam.png)


## Outputs
+ <font color=yellow>A single merged text file of all measurements</font>
![Screen Shot 2022-10-23 at 11.21.38 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.21.38%20PM.png)
+ Measurement image files
![Screen Shot 2022-10-23 at 11.25.01 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.25.01%20PM.png)
+ Measurement text files
![Screen Shot 2022-10-23 at 11.24.21 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.24.21%20PM.png)
+ Report html file
![Screen Shot 2022-10-23 at 11.23.25 PM](/assets/Screen%20Shot%202022-10-23%20at%2011.23.25%20PM.png)

## Version history
+ Version 0.10 : The script release (2022.10.23)

## _Contact_
_Uksu, Choi (qtwing@naver.com)_
