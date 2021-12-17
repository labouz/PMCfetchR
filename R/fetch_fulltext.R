#' Get full-text articles from PMC Open Access Subset in an AWS S3 bucket
#'
#' @param id a single PMCID, a vector of PMCIDs or a list of PMCIDs returned from \code{\link{fetch_pmcid}}
#' @param vars which variables you would like to keep in output dataframe, options
#'   are \code{c("all", "section", "paragraph", "sentence", "text")}. Defaults to "all".
#'
#' @return a tidy \code{data.frame} containing each manuscript retrieved, tokenized by sentence.
#' @importFrom tibble tibble
#' @importFrom aws.s3 s3read_using
#' @importFrom tidypmc pmc_text
#' @importFrom dplyr n mutate
#' @importFrom purrr map_df
#' @importFrom utils capture.output
#' @importFrom magrittr %>%
#' @importFrom rlang arg_match
#' @importFrom xml2 read_xml
#' @importFrom stringr str_extract str_remove
#' @export
#'
#' @examples
#' fetch_fulltext("PMC5465829")
#' fetch_fulltext("PMC5465829", vars = c("text"))

fetch_fulltext <- function(id, vars = c("all", "section", "paragraph", "sentence", "text")){
  # convert input, id, to list ----
  # id could be list returned from fetch_pmcid() or a string of PMCIDs
  if(is.list(id) == FALSE){
    id_ls <- as.list(as.character(id))
  }else{
    id_ls <- id
  }
  vars <- rlang::arg_match(vars)
  # remove "invalid" PMCIDs ----
  id_ls <- Filter(function(x) x != "invalid", id_ls)

  # FYI:returns 2k PMC articles in a prettier way
  # pmc_aws <- data.table::rbindlist(get_bucket("pmc-oa-opendata"))

  # GET AWS DIRECTORIES BASED ON PMCID-------
  get_source <- function(pmcid){
    # URL for OPEN ACCESS CREATIVE COMMONS LICENSE
    dir_oa_noncomm <- paste0("oa_noncomm/xml/all/", pmcid, ".xml")
    # URL for OPEN ACCESS COMMERCIAL LICENSE
    dir_oa_comm <- paste0("oa_comm/xml/all/", pmcid, ".xml")
    # URL for AUTHOR MANUSCRIPT SUBSET
    dir_auth <- paste0("author_manuscript/xml/all", pmcid, ".xml")

    return(list(dir_auth, dir_oa_comm, dir_oa_noncomm))
  }

  # FUNCTION TO TRY EACH PMCID ON EACH AWS DIR---------------------
  fetch_paper_aws <- function (pmcid, source){
    paper <-  tryCatch(
      expr = {
        capture.output(xml <- s3read_using(FUN = xml2::read_xml,
                                           bucket = "pmc-oa-opendata",
                                           object = source))

        # convert xml to df
        xml_to_df(xml, pmcid)
        # return paper
      },
      error = function(e){
        message(paste0("Article ",pmcid, " does not exsist in s3://pmc-oa-opendata/",
                       str_extract(source, "([a-z]+_[a-z]+/)")))

      }
    )
    paper
  }

  # FAILSAFE FUNCTION THAT GETS CALLED IF NOTHING IS RETURNED FROM AWS------------
  fetch_paper_eutility <- function (pmcid) {
    # strip 'PMC' from PMCID
    id <- stringr::str_remove(pmcid, "PMC")
    api <- paste0("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&id=",id)

    response <- xml2::read_xml(api)
    # convert xml to df
    xml_to_df(response, pmcid)
  }

  # FUNCTION TO PARSE RETURNED XML TO DATAFRAME USING TIDYPMC---------
  xml_to_df <- function(paper_xml, pmcid){
    # tidy xml
    df <- suppressMessages(tidypmc::pmc_text(paper_xml))
    # process
    if(vars != "all"){
      df <- df[vars]
    }

    tibble(pmcid = pmcid, df) %>%
      mutate(id = 1:n())
  }

  # FINAL FUNCTION CALL TO GET PAPERS FROM AWS OR EUTILITIES---------
  fetch_paper_pmcid <- function (pmcid) {
    # browser()
    sources <- sapply(pmcid, get_source)
    for (source in sources) {
      paper <- fetch_paper_aws(pmcid, source)

      if (!is.null(paper)) {
        return(paper)
        # exit function when there is a paper returned from AWS
        break
      }
    }
    # pmcid not found in AWS sources
    paper <- fetch_paper_eutility(pmcid)

    return(paper)
  }

  map_df(id_ls, fetch_paper_pmcid)
}
