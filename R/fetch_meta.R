#' Retrieve meta data for a paper given a PMCID or URL and/or specific meta data parameters and return a data.table
#'
#' @param id a single PMCID, a vector of PMCIDs or a list of PMCIDs returned from \code{\link{fetch_pmcid}}
#'
#' @return a \code{data.frame} containing all available meta data of an article in long format, given a PMID(s).
#' @importFrom rlang arg_match
#' @export
#'
#' @examples
#' fetch_meta("17284678")

fetch_meta <- function(id){
  # convert input, id, to list ----
  # id could be list returned from fetch_pmcid() or a string of PMCIDs
  # if(is.list(id) == FALSE){
  #   id_ls <- as.list(as.character(id))
  # }else{
  #   id_ls <- id
  # }
  # # remove "invalid" PMCIDs ----
  # id_ls <- Filter(function(x) x != "invalid", id_ls)

  # make url
  pmid <- as.numeric(id)
  url <- paste0("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=",pmid,"&retmode=json&rettype=docsum")
  convert <- fromJSON(url)
  results <- convert$result[[2]]

  meta <- lapply(1:length(results), function(i){
    the_var <- results[i]
    if(is.list(the_var)){
      data.frame(varname = names(the_var), var = as.matrix(the_var), row.names = NULL)
    }else{
      data.frame(varname = names(the_var), var = the_var, row.names = NULL)
    }

  })

  do.call(rbind, meta)

}
