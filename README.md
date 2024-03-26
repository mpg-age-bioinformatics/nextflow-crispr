# nextflow-crispr

If you have a flaski config file you can extract the parameters file from it with:

```
LATEST_RELEASE=$(  curl --silent "https://api.github.com/repos/mpg-age-bioinformatics/nf-flaski-configs/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )
nextflow run mpg-age-bioinformatics/nf-flaski-configs -r ${LATEST_RELEASE} --raw </path/to/raw/data> --json </path/to/flaski/config.json --out </path/to/output> -profile local
```

And then run the workflow with:
```
bash nextflow-local.sh clone </path/to/output/params.json>
```

This workflow is based on the following nextflow pipes:

- https://github.com/mpg-age-bioinformatics/nf-fastqc
- https://github.com/mpg-age-bioinformatics/nf-cutadapt
- https://github.com/mpg-age-bioinformatics/nf-mageck
- https://github.com/mpg-age-bioinformatics/nf-bagel
- https://github.com/mpg-age-bioinformatics/nf-drugz
- https://github.com/mpg-age-bioinformatics/nf-acer
- https://github.com/mpg-age-bioinformatics/nf-maude

Once run you will find in the `work` folder the file `software.txt` with information on all the respective versions used for your run.
