nextflow.enable.dsl=2

// binDir = !params.containsKey("test") ? "${workflow.projectDir}/src/template/bin/" : ""

toolParams = params.tools.bwamaptools

process BWAMAPTOOLS__BWA_MEM_PE {

    container toolParams.container
    label 'compute_resources__bwa_mem'

    input:
        tuple path(bwa_fasta),
              path(bwa_index),
              val(sampleId),
              path(fastq_PE1),
              path(fastq_PE2)

    output:
        tuple val(sampleId),
              path("${sampleId}.bwa.out.possorted.bam")

    script:
        def sampleParams = params.parseConfig(sampleId, params.global, toolParams)
        processParams = sampleParams.local
        def samtools_cpus = (task.cpus > 6) ? 6 : task.cpus
        """
        set -euo pipefail
        ${toolParams.bwa_version} mem \
            -t ${task.cpus} \
            -C \
            ${bwa_fasta} \
            ${fastq_PE1} \
            ${fastq_PE2} \
        | samtools fixmate -m -u -O bam - - \
        | samtools sort -@ ${samtools_cpus} -u -O bam - \
        | samtools markdup -@ ${samtools_cpus} -f ${sampleId}.markdup.log - ${sampleId}.bwa.out.possorted.bam
        """
}

