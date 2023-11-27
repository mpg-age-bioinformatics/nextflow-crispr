#!/bin/bash

set -e

PROFILE=raven
LOGS="work"
PARAMS="params.json"

source crispr.config.src

mkdir -p ${LOGS}

get_images() {
  echo "- downloading images"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1
  nextflow run ${ORIGIN}nf-cutadapt ${CUTADAPT_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1
  nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry images -profile ${PROFILE} >> ${LOGS}/get_images.log 2>&1 


  #&& \
}

run_fastqc() {
  echo "- running fastqc"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

run_fastqc_clean() {
  echo "- running fastqc on clean reads"
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} --fastqc_raw_data ${clean_reads} --fastqc_output ${fastqc_clean} -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1 && \
  nextflow run ${ORIGIN}nf-fastqc ${FASTQC_RELEASE} -params-file ${PARAMS} --fastqc_output ${fastqc_clean} -entry upload -profile ${PROFILE} >> ${LOGS}/nf-fastqc.log 2>&1
}

get_images && sleep 1

run_fastqc & RUN_fastqc_PID=$!
sleep 1

echo "- running cutadpt"
nextflow run ${ORIGIN}nf-cutadapt ${CUTADAPT_RELEASE} -params-file ${PARAMS} -profile ${PROFILE} >> ${LOGS}/nf-cutadapt.log 2>&1 & CUTADAPT_PID=$!
sleep 1
wait $CUTADAPT_PID
CODE=$?
if [[ "$CODE" != "0" ]] ; 
    then
        echo "exit $CODE"
        exit $CODE
fi

run_fastqc_clean & RUN_fastqc_clean_PID=$!
sleep 1 

echo "- running mageck count"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_count -profile ${PROFILE} >> ${LOGS}/nf-mageck-count.log 2>&1 & MAGECK_COUNT_PID=$!
sleep 1
wait $MAGECK_COUNT_PID
CODE=$?
if [[ "$CODE" != "0" ]] ; 
    then
        echo "exit $CODE"
        exit $CODE
fi


echo "- running mageck pre-test"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_pretest -profile ${PROFILE} >> ${LOGS}/nf-mageck-test.log 2>&1 & MAGECK_TEST_PID=$!
sleep 1
wait $MAGECK_TEST_PID
CODE=$?
if [[ "$CODE" != "0" ]] ; 
    then
        echo "exit $CODE"
        exit $CODE
fi
echo "- running mageck test"
nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_test -profile ${PROFILE} >> ${LOGS}/nf-mageck-test.log 2>&1 & MAGECK_TEST_PID=$!

nextflow run ${ORIGIN}nf-mageck ${MAGECK_RELEASE} -params-file ${PARAMS} -entry mageck_pressc -profile ${PROFILE} >> ${LOGS}/nf-mageck-pressc.log 2>&1 & MAGECK_PRESSC_PID=$!


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