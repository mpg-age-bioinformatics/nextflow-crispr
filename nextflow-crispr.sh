#!/bin/bash

# set -e

## variables
PROFILE=$1
# PROFILE=raven
LOGS="work"
PARAMS="params.json"
source crispr.config.src


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
            #exit $CODE
    fi
}


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
    ACER_RELEASE="-r ${MAUDE_RELEASE}"
    
    uniq ${LOGS}/software.txt ${LOGS}/software.txt_
    mv ${LOGS}/software.txt_ ${LOGS}/software.txt
    
else

  for repo in nf-fastqc nf-cutadapt nf-mageck nf-bagel nf-drugz nf-acer nf-maude ; 
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

mkdir -p ${LOGS}

## start pipeline

get_images() {
  echo "$(date '+%Y-%m-%d %H:%M:%S'): images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1
  nextflow run ${ORIGIN}nf-cutadapt ${CUTADAPT_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1
  nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1
  nextflow run ${ORIGIN}nf-bagel ${BAGEL_RELEASE} -params-file ${PARAMS}  -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1
  nextflow run ${ORIGIN}nf-drugz ${DRUGZ_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1
  nextflow run ${ORIGIN}nf-acer ${ACER_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1
  nextflow run ${ORIGIN}nf-maude ${MAUDE_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 && sleep 1

}

run_upload(){
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} --fastqc_output ${fastqc_clean} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

get_images && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): preprocess"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry pre_process -profile ${PROFILE} >> ${LOGS}/nf-mageck-pre_process.log 2>&1 && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): fastqc"
nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 & FASTQC_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): cutadapt"
nextflow run ${ORIGIN}nf-cutadapt ${CUTADAPT_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-cutadapt.log 2>&1 && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): fastqc on trimmed reads"
nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} --fastqc_raw_data ${clean_reads} --fastqc_output ${fastqc_clean} -profile ${PROFILE} >> ${LOGS}/nf-fastqc-clean.log 2>&1 & FASTQC_CLEAN_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck count"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_count -profile ${PROFILE} >> ${LOGS}/nf-mageck-count.log 2>&1 && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck test"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_test -profile ${PROFILE} >> ${LOGS}/nf-mageck-test.log 2>&1 && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck pathway"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_pathway -profile ${PROFILE} >> ${LOGS}/nf-mageck-pathway.log 2>&1 & MAGECK_PATHWAY_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck plot"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_plot -profile ${PROFILE} >> ${LOGS}/nf-mageck-plot.log 2>&1 & MAGECK_PLOT_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): bagel"
nextflow run ${ORIGIN}nf-bagel ${BAGEL_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-bagel.log 2>&1 & BAGEL_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): drugz"
nextflow run ${ORIGIN}nf-drugz ${DRUGZ_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-drugz.log 2>&1 & DRUGZ_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): acer"
nextflow run ${ORIGIN}nf-acer ${ACER_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-acer.log 2>&1 & ACER_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): maude"
nextflow run ${ORIGIN}nf-maude ${MAUDE_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-maude.log 2>&1 & MAUDE_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck mle"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_premle -profile ${PROFILE} >> ${LOGS}/nf-mageck-premle.log 2>&1  && \
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_mle -profile ${PROFILE} >> ${LOGS}/nf-mageck-mle.log 2>&1 && sleep 1

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck vispr"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_vispr -profile ${PROFILE} >> ${LOGS}/nf-mageck-vispr.log 2>&1 & MAGECK_VISPR_PID=$!

echo "$(date '+%Y-%m-%d %H:%M:%S'): mageck flute"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_flute -profile ${PROFILE} >> ${LOGS}/nf-mageck-flute.log 2>&1 & MAGECK_FLUTE_PID=$!


for PID in "${FASTQC_PID}:FASTQC" \
  "${FASTQC_CLEAN_PID}:FASTQC_CLEAN" \
  "${MAGECK_PATHWAY_PID}:MAGECK_PATHWAY" \
  "${MAGECK_PLOT_PID}:MAGECK_PLOT" \
  "${BAGEL_PID}:BAGEL" \ 
  "${DRUGZ_PID}:DRUGZ" \
  "${ACER_PID}:"ACER" \
  "${MAUDE_PID}:"MAUDE" \
  "${MAGECK_VISPR_PID}:MAGECK_VISPR" \
  "${MAGECK_FLUTE_PID}:MAGECK_FLUTE"
  do 
    wait_for $PID
done


echo "Done"
exit

# run_kallisto & RUN_kallisto_PID=$!
# sleep 1

# for PID in $RUN_fastqc_PID $RUN_kallisto_PID ; 
#     do
#         wait $PID
#         CODE=$?
#         if [[ "$CODE" != "0" ]] ; 
#             then
#                 echo "exit $CODE"
#                 exit $CODE
#         fi
        
# done