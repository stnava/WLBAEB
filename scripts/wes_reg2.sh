# export preview_images_downsampled_200nm_voxel_Reslice.tif to nifti
# using imagej ... probably a better way.
# BEWARE: nifti images can be buggy when they get too large
# in some cases it will fail to read-in or write-out all data
fourdimg=AZEP.nii.gz
hislice=`PrintHeader $fourdimg | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
if [[ ! -s output2 ]] ; then
  mkdir output2
fi
identifier=output2/AZEP
initialaverage=${identifier}_raw_avg.nii.gz
finalaverage=${identifier}_diff_avg.nii.gz
if [[ ! -s $initialaverage ]] ; then
  antsMotionCorr -d 3 -a  $fourdimg -o $initialaverage
  stackavg=" "
  for x in `seq 1 $hislice` ; do
    stackavg=" $stackavg $initialaverage "
  done
  ImageMath 4 $initialaverage TimeSeriesAssemble 1 0 $stackavg
fi
tx=SyN[0.15,5,0.0] # critical parameters (though others matter too)
antsRegistration --dimensionality 4 --float 1 \
      --output   [${identifier}_,${identifier}Warped.nii.gz] \
      --interpolation Linear --use-histogram-matching 1 \
      --winsorize-image-intensities [0.005,0.995] --transform $tx \
      --metric meansquares[${initialaverage},$fourdimg,1,32] \
      --convergence [15x10,1e-6,4] --shrink-factors 2x1 \
      --smoothing-sigmas 1x0vox --restrict-deformation 1x1x1x0
