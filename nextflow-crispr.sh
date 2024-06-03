#!/bin/bash

# set -e

## variables
PROFILE=$2
LOGS="work"
PARAMS="params.json"
source crispr.config

LOGS_=${project_folder}/logs

export NXF_WORK=${project_folder}/nfx_work

mkdir -p ${LOGS} ${LOGS_}

## functions
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

wait_for(){
    PID=$(echo "$1" | cut -d ":" -f 1 )
    PRO=$(echo "$1" | cut -d ":" -f 2 )
    echo "$(date '+%Y-%m-%d %H:%M:%S'): waiting for ${PRO}"
    wait $PID
    CODE=$?
    
    if [[ "$CODE" != "0" ]] ; 
        then
            echo "$PRO failed"
            echo "$CODE"
            failed=true
            #exit $CODE
    fi
}

failed=false

## define nextflow modules source
if [[ "$1" == "release" ]] ; 
  then

    ORIGIN="mpg-age-bioinformatics/"
    
    FASTQC_RELEASE=$(get_latest_release ${ORIGIN}nf-fastqc)
    echo "${ORIGIN}nf-fastqc:${FASTQC_RELEASE}" >> ${LOGS}/software.txt
    FASTQC_RELEASE="-r ${FASTQC_RELEASE}"
    
    CUTADAPT_RELEASE=$(get_latest_release ${ORIGIN}nf-cutadapt)
    echo "${ORIGIN}nf-cutadapt:${CUTADAPT_RELEASE}" >> ${LOGS}/software.txt
    CUTADAPT_RELEASE="-r ${CUTADAPT_RELEASE}"
    
    MAGECK_RELEASE=$(get_latest_release ${ORIGIN}nf-mageck)
    echo "${ORIGIN}nf-mageck:${MAGECK_RELEASE}" >> ${LOGS}/software.txt
    MAGECK_RELEASE="-r ${MAGECK_RELEASE}"
    
    BAGEL_RELEASE=$(get_latest_release ${ORIGIN}nf-bagel)
    echo "${ORIGIN}nf-bagel:${BAGEL_RELEASE}" >> ${LOGS}/software.txt
    BAGEL_RELEASE="-r ${BAGEL_RELEASE}"
    
    DRUGZ_RELEASE=$(get_latest_release ${ORIGIN}nf-drugz)
    echo "${ORIGIN}nf-drugz:${DRUGZ_RELEASE}" >> ${LOGS}/software.txt
    DRUGZ_RELEASE="-r ${DRUGZ_RELEASE}"

    ACER_RELEASE=$(get_latest_release ${ORIGIN}nf-acer)
    echo "${ORIGIN}nf-acer:${ACER_RELEASE}" >> ${LOGS}/software.txt
    ACER_RELEASE="-r ${ACER_RELEASE}"

    MAUDE_RELEASE=$(get_latest_release ${ORIGIN}nf-maude)
    echo "${ORIGIN}nf-maude:${MAUDE_RELEASE}" >> ${LOGS}/software.txt
    MAUDE_RELEASE="-r ${MAUDE_RELEASE}"

    CLEANR_RELEASE=$(get_latest_release ${ORIGIN}nf-crisprcleanr)
    echo "${ORIGIN}nf-crisprcleanr:${CLEANR_RELEASE}" >> ${LOGS}/software.txt
    CLEANR_RELEASE="-r ${CLEANR_RELEASE}"
    
    uniq ${LOGS}/software.txt ${LOGS}/software.txt_
    mv ${LOGS}/software.txt_ ${LOGS}/software.txt
    
else

  for repo in nf-fastqc nf-cutadapt nf-mageck nf-bagel nf-drugz nf-acer nf-maude nf-crisprcleanr ; 
    do

      if [[ ! -e ${repo} ]] ;
        then
          git clone git@github.com:mpg-age-bioinformatics/${repo}.git
      fi

      if [[ "$1" == "checkout" ]] ;
        then
          cd ${repo}
          git pull
          RELEASE=$(get_latest_release ${ORIGIN}${repo})
          git checkout ${RELEASE}
          cd ../
          echo "${ORIGIN}${repo}:${RELEASE}" >> ${LOGS}/software.txt
      else
        cd ${repo}
        COMMIT=$(git rev-parse --short HEAD)
        cd ../
        echo "${ORIGIN}${repo}:${COMMIT}" >> ${LOGS}/software.txt
      fi

  done

  uniq ${LOGS}/software.txt >> ${LOGS}/software.txt_ 
  mv ${LOGS}/software.txt_ ${LOGS}/software.txt

fi


## start pipeline

get_images() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log  ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-cutadapt ${CUTADAPT_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-bagel ${BAGEL_RELEASE} -params-file ${PARAMS}  -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-drugz ${DRUGZ_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-acer ${ACER_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-maude ${MAUDE_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1
  nextflow run ${ORIGIN}nf-crisprcleanr ${CLEANR_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} 2>&1 | tee ${LOGS}/get_images.log ${LOGS_}/get_images.log && sleep 1

}

run_upload(){
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-fastqc.log ${LOGS_}/nf-fastqc.log
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} --fastqc_output ${fastqc_clean} -entry upload -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-fastqc.log ${LOGS_}/nf-fastqc.log
}

get_images && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): preprocess"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry pre_process -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-pre_process.log ${LOGS_}/nf-mageck-pre_process.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): cleanR library formatting"
nextflow run ${ORIGIN}nf-crisprcleanr ${CLEANR_RELEASE} -params-file ${PARAMS} -entry lib_file_formatting -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-cleanR-lib.log ${LOGS_}/nf-cleanR-lib.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): fastqc"
nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-fastqc.log ${LOGS_}/nf-fastqc.log & FASTQC_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): cutadapt"
nextflow run ${ORIGIN}nf-cutadapt ${CUTADAPT_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-cutadapt.log ${LOGS_}/nf-cutadapt.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): fastqc on trimmed reads"
nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} --fastqc_raw_data ${clean_reads} --fastqc_output ${fastqc_clean} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-fastqc-clean.log  ${LOGS_}/nf-fastqc-clean.log & FASTQC_CLEAN_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck count"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_count -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-count.log ${LOGS_}/nf-mageck-count.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck test"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_test -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-test.log ${LOGS_}/nf-mageck-test.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): cleanR pipe"
nextflow run ${ORIGIN}nf-crisprcleanr ${CLEANR_RELEASE} -params-file ${PARAMS} -entry cleanR_workflow -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-cleanR-pipe.log ${LOGS_}/nf-cleanR-pipe.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): magecku"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry magecku -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-u.log ${LOGS_}/nf-mageck-u.log & MAGECK_U_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck pathway"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_pathway -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-pathway.log ${LOGS_}/nf-mageck-pathway.log & MAGECK_PATHWAY_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck plot"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_plot -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-plot.log ${LOGS_}/nf-mageck-plot.log & MAGECK_PLOT_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): bagel"
nextflow run ${ORIGIN}nf-bagel ${BAGEL_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-bagel.log ${LOGS_}/nf-bagel.log & BAGEL_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): drugz"
nextflow run ${ORIGIN}nf-drugz ${DRUGZ_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-drugz.log ${LOGS_}/nf-drugz.log & DRUGZ_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): acer"
nextflow run ${ORIGIN}nf-acer ${ACER_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-acer.log ${LOGS_}/nf-acer.log & ACER_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): maude"
nextflow run ${ORIGIN}nf-maude ${MAUDE_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-maude.log ${LOGS_}/nf-maude.log & MAUDE_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck mle"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_premle -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-premle.log ${LOGS_}/nf-mageck-premle.log && \
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_mle -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-mle.log ${LOGS_}/nf-mageck-mle.log && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck vispr"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_vispr -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-vispr.log ${LOGS_}/nf-mageck-vispr.log & MAGECK_VISPR_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck flute"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_flute -profile ${PROFILE} 2>&1 | tee ${LOGS}/nf-mageck-flute.log ${LOGS_}/nf-mageck-flute.log & MAGECK_FLUTE_PID=$!


for PID in "${FASTQC_PID}:FASTQC" \
  "${FASTQC_CLEAN_PID}:FASTQC_CLEAN" \
  "${MAGECK_U_PID}:MAGECK_U_PID" \
  "${MAGECK_PATHWAY_PID}:MAGECK_PATHWAY" \
  "${MAGECK_PLOT_PID}:MAGECK_PLOT" \
  "${BAGEL_PID}:BAGEL" \
  "${DRUGZ_PID}:DRUGZ" \
  "${ACER_PID}:ACER" \
  "${MAUDE_PID}:MAUDE" \
  "${MAGECK_VISPR_PID}:MAGECK_VISPR" \
  "${MAGECK_FLUTE_PID}:MAGECK_FLUTE"
  do 
    wait_for $PID
done

rsync -rtvh ${LOGS} ${project_folder}

if [ "$failed" = true ]; then

  echo "At least one process failed. Exiting."
  exit 1

else

  echo "All processes completed successfully. Proceeding to the next step."
  echo -e "Hi,\n\n\
Your run is now completed.\n\n\
This is an automatically generated analysis.\n\n\
Best wishes,\n\n\
The Bioinformatics Core Facility of the Max Planck Institute for Biology of Ageing" > "${upload_list}.email"
  git add -A . && git commit -m "finished; close #2" && git push
  echo $(date +"%Y/%m/%d %H:%M:%S")": finished"

fi

exit

