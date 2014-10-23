# export preview_images_downsampled_200nm_voxel_Reslice.tif to nifti
# using imagej ... probably a better way.
# BEWARE: nifti images can be buggy when they get too large
# in some cases it will fail to read-in or write-out all data
fourdimg=AZEP.nii.gz
hislice=`PrintHeader $fourdimg | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
hislice="$(($hislice-1))" # 0-indexing
if [[ ! -s output ]] ; then
  mkdir output
fi
identifier=output/AZEP
initialaverage=${identifier}_raw_avg.nii.gz
finalaverage=${identifier}_diff_avg.nii.gz
if [[ ! -s $initialaverage ]] ; then
  antsMotionCorr -d 3 -a  $fourdimg -o $initialaverage
fi
tx=SyN[0.15,3,0.2] # critical parameters (though others matter too)
for x in `seq -w 0 $hislice` ; do
  pre=${identifier}_slice_${x}
  if [[ ! -s ${pre}.nii.gz ]] ; then
    ExtractSliceFromImage 4 $fourdimg ${pre}.nii.gz 3 $x
    antsRegistration --dimensionality 3 --float 0 \
      --output   [${pre}_,${pre}Warped.nii.gz] \
      --interpolation Linear --use-histogram-matching 1 \
      --winsorize-image-intensities [0.005,0.995] --transform $tx \
      --metric MI[${initialaverage},${pre}.nii.gz,1,16] \
      --convergence [5x5,1e-6,10] --shrink-factors 2x1 \
      --smoothing-sigmas 1x0vox
  fi
done
imgs=`ls ${identifier}*[0-9]Warped.nii.gz`
AverageImages 3 $finalaverage 1 $imgs
# this is the reconstructed stack
ImageMath 4 diff_stack.nii.gz TimeSeriesAssemble 1 0 $imgs
#
# ok for a first pass ... you might loop over this procedure a few times
# this would be a crude "template construction" process
#
