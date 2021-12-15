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
#' @export
#'
#' @examples
#' fetch_fulltext("PMC2480524")
#' fetch_fulltext("PMC2480524", vars = c("text"))

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

  # call aws bucket for given pmcid and tidy ----
  call_bucket <- function(pmcid){
    # URL for OPEN ACCESS CREATIVE COMMONS LICENSE
    dir_oa_noncomm <- paste0("oa_noncomm/xml/all/", pmcid, ".xml")
    # URL for OPEN ACCESS COMMERCIAL LICENSE
    dir_oa_comm <- paste0("oa_comm/xml/all/", pmcid, ".xml")
    # URL for AUTHOR MANUSCRIPT SUBSET
    dir_auth <- paste0("author_manuscript/xml/all", pmcid, ".xml")
    # wrap trycatch in a function to test the pmcid against each available URL
    # trycatch for pmcids that return error
    try_url <- function(url){
      tryCatch(
        expr = {
          capture.output(xml <- s3read_using(FUN = xml2::read_xml,
                                             bucket = "pmc-oa-opendata",
                                             object = url))
          # tidy xml
          xml_to_df <- suppressMessages(tidypmc::pmc_text(xml))
          # process
          if(vars != "all"){
            xml_to_df <- xml_to_df[vars]
          }

          tibble(PMCID = pmcid, xml_to_df) %>%
            mutate(id = 1:n())

        },

        error = function(e){
          message(paste0("Article ",pmcid, " does not exsist in ",
                         str_extract(url, "([a-z]+_[a-z]+/)")))
        }
        # finally = {
        #   message("All manuscripts have read")
        # }
      )
    }
    purrr::map_dfr(c(dir_oa_comm, dir_oa_noncomm, dir_auth), try_url)

  }

  map_df(id_ls, call_bucket)
}
