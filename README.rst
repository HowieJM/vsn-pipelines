VSN-Pipelines
==============

## **2024-09-03**

# **Fork Notes:**

I noticed that the repository has been archived. Unfortunately, the most recent version does not run with the most up-to-date motif files. Therefore, I produced a fork that can run the scenic module of this VSN-pipeline in both single-run and multi-run modes. To do this, I borrowed two fixes from the ``ccasar/vsn-pipelines`` fork. These allow the VSN-pipeline to run in single-run mode if ``skipReports = true`` in the config. To allow the multi-run aggregation to function, I made one further tweak. These are small changes but can be tricky to ID. Hopefully they will save time for people who want to use SCENIC multi-run mode with aggregation. I've noted key setup options.

---

# **Run Notes:**

To run, produce an environment and install the following:

- **Singularity:** 3.8.6
- **Nextflow:** 21.04.03 (crucial)

Then export these variables, checking before and after:

.. code-block:: bash

   locale
   export LANG="C"
   export LC_ALL="C"
   locale


After this, pull the fork:

.. code-block:: bash

   nextflow pull HowieJM/vsn-pipelines -r master
   ls -l ~/.nextflow/assets/HowieJM/vsn-pipelines


Make the Config file:

.. code-block:: bash

   nextflow config HowieJM/vsn-pipelines \
      -profile scenic,scenic_multiruns,scenic_use_cistarget_motifs,scenic_use_cistarget_tracks,hg38,singularity > nf_CPUopt-Real-MultiRun.config


Then edit the config:

.. code-block:: bash

   container = 'aertslab/pyscenic_scanpy:0.12.0_1.9.1'  #crucial note -> you can run with 0.12.1_1.9.1 but in Linux this can lead to low multicore rates, using 0.12.0 allows full use
   skipReports = true   #crucial, for up-to-date feather files for the motifs/tracks


Run the pipeline:

.. code-block:: bash

   nextflow -C nf_CPUopt-Real-MultiRun.config run HowieJM/vsn-pipelines -entry scenic -r master 


You can run the VSN-pipeline implementation of pySCENIC in single-run mode or in multiple-run with aggregation. 


# **Further Notes:** 

If ``skipReports=false`` the run will fail. To re-introduce these reports would require at least edits to ``vsn-pipelines/src/scenic/bin/reports/scenic_report.ipynb``. 
I have not looked at this. But, if interested, have a look at ccasar/vsn-pipelines fork for one attempt to fix this. Here, we simply set to ``skipReports=true`` to hot fix.

# **JMH, Sept, 3rd, 2024 [+edits 30 Sept 2024]** 


##




VSN-Pipelines has now been archived
-----------------------------

**2023-04-19 - Unfortunately due to lack of developers, VSN-pipelines is no longer being worked on and has been archived. The repo will remain in read-only mode from this point on.**

A repository of pipelines for single-cell data analysis in Nextflow DSL2.

|VSN-Pipelines| |ReadTheDocs| |Zenodo| |Gitter| |Nextflow|


**Full documentation** is available on `Read the Docs <https://vsn-pipelines.readthedocs.io/en/latest/>`_, or take a look at the `Quick Start <https://vsn-pipelines.readthedocs.io/en/latest/getting-started.html#quick-start>`_ guide.

This main repo contains multiple workflows for analyzing single cell transcriptomics data, and depends on a number of tools, which are organized into subfolders within the ``src/`` directory.
The VIB-Singlecell-NF_ organization contains this main repo along with a collection of example runs (`VSN-Pipelines-examples <https://vsn-pipelines-examples.readthedocs.io/en/latest/>`_).
Currently available workflows are listed below.

If VSN-Pipelines is useful for your research, consider citing:

- VSN-Pipelines All Versions (latest): `10.5281/zenodo.3703108 <https://doi.org/10.5281/zenodo.3703108>`_.

Raw Data Processing Workflows
-----------------------------

These are set up to run Cell Ranger and DropSeq pipelines.

.. list-table:: Raw Data Processing Workflows
    :widths: 15 10 30
    :header-rows: 1

    * - Pipeline / Entrypoint
      - Purpose
      - Documentation
    * - cellranger
      - Process 10x Chromium data
      - cellranger_
    * - demuxlet_freemuxlet
      - Demultiplexing
      - demuxlet_freemuxlet_
    * - nemesh
      - Process Drop-seq data
      - nemesh_

.. _cellranger: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#cellranger
.. _demuxlet_freemuxlet: https://vsn-pipelines.readthedocs.io/en/develop/pipelines.html#demuxlet-freemuxlet
.. _nemesh: https://vsn-pipelines.readthedocs.io/en/develop/pipelines.html#nemesh


Single Sample Workflows
-----------------------

The **Single Sample Workflows** perform a "best practices" scRNA-seq analysis. Multiple samples can be run in parallel, treating each sample separately.

.. list-table:: Single Sample Workflows
    :header-rows: 1

    * - Pipeline / Entrypoint
      - Purpose
      - Documentation
    * - single_sample
      - Independent samples
      - |single_sample|
    * - single_sample_scenic
      - Ind. samples + SCENIC
      - |single_sample_scenic|
    * - scenic
      - SCENIC GRN inference
      - |scenic|
    * - scenic_multiruns
      - SCENIC run multiple times
      - |scenic_multiruns|
    * - single_sample_scenic_multiruns
      - Ind. samples + multi-SCENIC
      - |single_sample_scenic_multiruns|
    * - single_sample_scrublet
      - Ind. samples + Scrublet
      - |single_sample_scrublet|
    * - decontx
      - DecontX
      - |decontx|
    * - single_sample_decontx
      - Ind. samples + DecontX
      - |single_sample_decontx|
    * - single_sample_decontx_scrublet
      - Ind. samples + DecontX + Scrublet
      - |single_sample_decontx_scrublet|


Sample Aggregation Workflows
----------------------------

**Sample Aggregation Workflows**: perform a "best practices" scRNA-seq analysis on a merged and batch-corrected group of samples. Available batch correction methods include BBKNN, mnnCorrect, and Harmony.

.. list-table:: Sample Aggregation Pipelines
    :widths: 15 10 30
    :header-rows: 1

    * - Pipeline / Entrypoint
      - Purpose
      - Documentation
    * - bbknn
      - Sample aggregation + BBKNN
      - |bbknn|
    * - bbknn_scenic
      - BBKNN + SCENIC
      - |bbknn_scenic|
    * - harmony
      - Sample aggregation + Harmony
      - |harmony|
    * - harmony_scenic
      - Harmony + SCENIC
      - |harmony_scenic|
    * - mnncorrect
      - Sample aggregation + mnnCorrect
      - |mnncorrect|


----

In addition, the pySCENIC_ implementation of the SCENIC_ workflow is integrated here and can be run in conjunction with any of the above workflows.
The output of each of the main workflows is a loom_-format file, which is ready for import into the interactive single-cell web visualization tool SCope_.
In addition, data is also output in h5ad format, and reports are generated for the major pipeline steps.

scATAC-seq workflows
--------------------

Single cell ATAC-seq processing steps are now included in VSN Pipelines.
Currently, a preprocesing workflow is available, which will take fastq inputs, apply barcode correction, read trimming, bwa mapping, and output bam and fragments files for further downstream analysis.
See `here <https://vsn-pipelines.readthedocs.io/en/latest/scatac-seq.html>`_ for complete documentation.


.. |VSN-Pipelines| image:: https://img.shields.io/github/v/release/vib-singlecell-nf/vsn-pipelines
    :target: https://github.com/vib-singlecell-nf/vsn-pipelines/releases
    :alt: GitHub release (latest by date)

.. |ReadTheDocs| image:: https://readthedocs.org/projects/vsn-pipelines/badge/?version=latest
    :target: https://vsn-pipelines.readthedocs.io/en/latest/?badge=latest
    :alt: Documentation Status

.. |Nextflow| image:: https://img.shields.io/badge/nextflow-21.04.3-brightgreen.svg
    :target: https://www.nextflow.io/
    :alt: Nextflow

.. |Gitter| image:: https://badges.gitter.im/vib-singlecell-nf/community.svg
    :target: https://gitter.im/vib-singlecell-nf/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge
    :alt: Gitter

.. |Zenodo| image:: https://zenodo.org/badge/199477571.svg
    :target: https://zenodo.org/badge/latestdoi/199477571
    :alt: Zenodo

.. _VIB-Singlecell-NF: https://github.com/vib-singlecell-nf
.. _pySCENIC: https://github.com/aertslab/pySCENIC
.. _SCENIC: https://aertslab.org/#scenic
.. _loom: http://loompy.org/
.. _SCope: http://scope.aertslab.org/

.. |single_sample| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/single_sample/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#single-sample-single-sample
    :alt: Single-sample Pipeline

.. |single_sample_scenic| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/single_sample_scenic/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#single-sample-scenic-single-sample-scenic
    :alt: Single-sample SCENIC Pipeline

.. |scenic| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/scenic/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#scenic-scenic
    :alt: SCENIC Pipeline

.. |scenic_multiruns| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/scenic_multiruns/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#scenic-multiruns-scenic-multiruns-single-sample-scenic-multiruns
    :alt: SCENIC Multi-runs Pipeline

.. |single_sample_scenic_multiruns| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/single_sample_scenic_multiruns/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#scenic-multiruns-scenic-multiruns-single-sample-scenic-multiruns
    :alt: Single-sample SCENIC Multi-runs Pipeline

.. |single_sample_scrublet| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/single_sample_scrublet/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#single-sample-scrublet-single-sample-scrublet
    :alt: Single-sample Scrublet Pipeline

.. |decontx| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/decontx/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#decontx-decontx
    :alt: DecontX Pipeline

.. |single_sample_decontx| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/single_sample_decontx/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#single-sample-decontx-single-sample-decontx
    :alt: Single-sample DecontX Pipeline

.. |single_sample_decontx_scrublet| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/single_sample_decontx_scrublet/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#single-sample-decontx-scrublet-single-sample-decontx-scrublet
    :alt: Single-sample DecontX Scrublet Pipeline

.. |bbknn| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/bbknn/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#bbknn-bbknn
    :alt: BBKNN Pipeline

.. |bbknn_scenic| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/bbknn_scenic/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#bbknn-scenic
    :alt: BBKNN SCENIC Pipeline

.. |harmony| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/harmony/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#harmony-harmony
    :alt: Harmony Pipeline

.. |harmony_scenic| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/harmony_scenic/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#harmony-scenic
    :alt: Harmony SCENIC Pipeline

.. |mnncorrect| image:: https://github.com/vib-singlecell-nf/vsn-pipelines/workflows/mnncorrect/badge.svg
    :target: https://vsn-pipelines.readthedocs.io/en/latest/pipelines.html#mnncorrect-mnncorrect
    :alt: MNN-correct Pipeline

