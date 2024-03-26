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
