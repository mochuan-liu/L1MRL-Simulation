# R codes below are forked from https://github.com/cran/ITRSelect.
# Please see repo instruction for more information.
PAL.control <-
function(pi1.est = NULL, pi2.est = NULL, h1.est=NULL, h2.est=NULL, kappa=NULL, 
         penalty='SCAD')
{
    rval <- list(pi1.est=pi1.est, pi2.est=pi2.est, h1.est=h1.est, h2.est=h2.est,
	             penalty='SCAD')
    rval
}
