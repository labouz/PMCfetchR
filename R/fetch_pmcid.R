#' Convert PMIDs to PMCIDs
#'
#' @param ... multiple strings holding possible drug names
#'
#' @return A named list of PMCIDs with the input PMIDs
#' @importFrom jsonlite fromJSON
#' @export
#'
#' @examples
#' fetch_pmcid(19023454, "7016449")
fetch_pmcid <- function(...){
  # ... : vector of integers, chars, if more than one pmid supplied not as a vector

  if(...length() > 1){
    id_ls <- list(...)
  }else{
    id_ls <- as.list(...)
  }
  id_to_char <- lapply(
    X = id_ls,
    FUN = as.character
  )

  base_url <- "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?versions=no&format=json&idtype=pmid&"

  id_to_pmc <- lapply(id_to_char, function(x){
    # paste pmid to url
    pmid_vec <- paste0("ids=", x)

    url <- paste0(base_url, pmid_vec)

    convert <- fromJSON(url)
    # extract PMCID
    PMCID <- convert$records$pmcid

    if(is.null(PMCID)){
      # as.list(c("PMID" = id_to_char, "PMCID" = "invalid"))
      "invalid"
    }else{
      # as.list(c("PMID" = id_to_char, "PMCID" = PMCID))
      PMCID
    }
  }
  )
  # browser()
  names(id_to_pmc) <- id_to_char
  # names_vec <- c("PMID","PMCID")
  id_to_pmc

}
