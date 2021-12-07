test_that("PMID:19023454 returns a PMCID", {
  expect_equal(get_pmcid(19023454), list('19023454' = "PMC2480524"))
})

# invalid response

test_that("PMID:2645508 returns 'invalid'", {
  expect_equal(get_pmcid(2645508), list('2645508' = "invalid"))
})
