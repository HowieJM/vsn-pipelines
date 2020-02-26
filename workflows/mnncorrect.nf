nextflow.preview.dsl=2

//////////////////////////////////////////////////////
//  Import sub-workflows from the modules:

include '../src/utils/processes/files.nf' params(params.sc.file_concatenator + params.global + params)
include '../src/utils/processes/utils.nf' params(params.sc.file_concatenator + params.global + params)
include '../src/utils/workflows/utils.nf' params(params)

include QC_FILTER from '../src/scanpy/workflows/qc_filter.nf' params(params)
include NORMALIZE_TRANSFORM from '../src/scanpy/workflows/normalize_transform.nf' params(params)
include SC__SCANPY__REGRESS_OUT from '../src/scanpy/processes/regress_out.nf' params(params)
include HVG_SELECTION from '../src/scanpy/workflows/hvg_selection.nf' params(params)
include NEIGHBORHOOD_GRAPH from '../src/scanpy/workflows/neighborhood_graph.nf' params(params)
include DIM_REDUCTION_PCA from '../src/scanpy/workflows/dim_reduction_pca.nf' params(params + params.global)
include DIM_REDUCTION_TSNE_UMAP from '../src/scanpy/workflows/dim_reduction.nf' params(params + params.global)
// CLUSTER_IDENTIFICATION
include '../src/scanpy/processes/cluster.nf' params(params + params.global)
include '../src/scanpy/workflows/cluster_identification.nf' params(params + params.global) // Don't only import a specific process (the function needs also to be imported)
include BEC_MNNCORRECT from '../src/scanpy/workflows/bec_mnncorrect.nf' params(params)
include SC__H5AD_TO_FILTERED_LOOM from '../src/utils/processes/h5adToLoom.nf' params(params)
include FILE_CONVERTER from '../src/utils/workflows/fileConverter.nf' params(params)

// reporting:
include UTILS__GENERATE_WORKFLOW_CONFIG_REPORT from '../src/utils/processes/reports.nf' params(params)
include SC__SCANPY__MERGE_REPORTS from '../src/scanpy/processes/reports.nf' params(params + params.global)
include SC__SCANPY__REPORT_TO_HTML from '../src/scanpy/processes/reports.nf' params(params + params.global)

workflow mnncorrect {

    take:
        data

    main:

        // Run the pipeline
        QC_FILTER( data ) // Remove concat
        SC__FILE_CONCATENATOR( 
            QC_FILTER.out.filtered.map {
                it -> it[1]
            }.toSortedList( 
                { a, b -> getBaseName(a) <=> getBaseName(b) }
            )
        )
        NORMALIZE_TRANSFORM( SC__FILE_CONCATENATOR.out )
        HVG_SELECTION( NORMALIZE_TRANSFORM.out )
        if(params.sc.scanpy.containsKey("regress_out")) {
            preprocessed_data = SC__SCANPY__REGRESS_OUT( HVG_SELECTION.out.scaled )
        } else {
            preprocessed_data = HVG_SELECTION.out.scaled
        }
        DIM_REDUCTION_PCA( preprocessed_data )
        NEIGHBORHOOD_GRAPH( DIM_REDUCTION_PCA.out )
        DIM_REDUCTION_TSNE_UMAP( NEIGHBORHOOD_GRAPH.out )

        // Perform the clustering step w/o batch effect correction (for comparison matter)
        clusterIdentificationPreBatchEffectCorrection = CLUSTER_IDENTIFICATION( 
            NORMALIZE_TRANSFORM.out,
            DIM_REDUCTION_TSNE_UMAP.out.dimred_tsne_umap,
            "Pre Batch Effect Correction"
        )

        BEC_MNNCORRECT(
            NORMALIZE_TRANSFORM.out,
            HVG_SELECTION.out.hvg,
            clusterIdentificationPreBatchEffectCorrection.marker_genes
        )

        // Conversion
        // Convert h5ad to X (here we choose: loom format)
        filteredloom = SC__H5AD_TO_FILTERED_LOOM( SC__FILE_CONCATENATOR.out )
        scopeloom = FILE_CONVERTER(
            BEC_MNNCORRECT.out.data.groupTuple(),
            'loom',
            SC__FILE_CONCATENATOR.out,
        )

        project = CLUSTER_IDENTIFICATION.out.marker_genes.map { it -> it[0] }
        UTILS__GENERATE_WORKFLOW_CONFIG_REPORT(
            file(workflow.projectDir + params.utils.workflow_configuration.report_ipynb)
        )
        
        // Collect the reports:
        // Define the parameters for clustering
        def clusteringParams = SC__SCANPY__CLUSTERING_PARAMS( clean(params.sc.scanpy.clustering) )
        // Pairing clustering reports with bec reports
        if(!clusteringParams.isParameterExplorationModeOn()) {
            clusteringBECReports = BEC_MNNCORRECT.out.cluster_report.map {
                it -> tuple(it[0], it[1])
            }.combine(
                BEC_MNNCORRECT.out.mnncorrect_report.map {
                    it -> tuple(it[0], it[1])
                },
                by: 0
            ).map {
                it -> tuple(it[0], *it[1..it.size()-1], null)
            }
        } else {
            clusteringBECReports = COMBINE_BY_PARAMS(
                BEC_MNNCORRECT.out.cluster_report.map { 
                    it -> tuple(it[0], it[1], *it[2])
                },
                BEC_MNNCORRECT.out.mnncorrect_report,
                clusteringParams
            )
        }
        ipynbs = project.combine(
            UTILS__GENERATE_WORKFLOW_CONFIG_REPORT.out
        ).join(
            HVG_SELECTION.out.report.map {
                it -> tuple(it[0], it[1])
            }
        ).combine(
            clusteringBECReports,
            by: 0
        ).map {
            it -> tuple(it[0], it[1..it.size()-2], it[it.size()-1])
        }

        // reporting:
        SC__SCANPY__MERGE_REPORTS(
            ipynbs,
            "merged_report",
            clusteringParams.isParameterExplorationModeOn()
        )
        SC__SCANPY__REPORT_TO_HTML(SC__SCANPY__MERGE_REPORTS.out)

    emit:
        filteredloom
        scopeloom
}
