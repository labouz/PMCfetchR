get_pmcid <- function(...){
  # ... : vector of integers, chars, if more than one pmid supplied not as a vector
  id_ls = list(...)

  id_to_char <- lapply(
    X = id_ls,
    FUN = as.character
  )

  base_url <- "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?versions=no&format=json&idtype=pmid&"

  id_to_pmc <- lapply(id_to_char, function(x){

    # paste pmid to url
    pmid_vec <- paste0("ids=", x)
    url <- paste0(base_url, pmid_vec)
    # call to API that returns JSON
    convert <- fromJSON(url)
    # extract PMCID
    PMCID <- convert$records$pmcid

    if(is.null(PMCID)){
      c(PMID = x, PMCID = "invalid")
    }else{
      c(PMID = x, PMCID = PMCID)
    }
  }
  )

  id_to_pmc

}
