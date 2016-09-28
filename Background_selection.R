#!/usr/bin/env Rscript
#
# selection of background microbiomes via model based clustering of count data
# 
# by Jon Ahlinder

helpstr <- c('selection of background microbiomes via the model based clustering of count data as presented in Holmes et al. (2012)\nNB! Make sure the package "DirichletMultinomial" is installed!\n\n-d path to the classic OTU table containing both sink and background samples\n-u The starting number of metacommunities to analyze (default is 2)\n-e ending number of metacommunities to analyze (8)\n-v verbosity\n-f filename of a figure of the optimal number of metacommunities (optional)\n-o filename of the metacommunity source proportion (source_proportion_dmn.txt) \n-c model selection criterion for selecting optimal number of partitions in the data. Choose between laplace, aic or bic (default: laplace)\n-s seed (1)')

allowed.args <- list('-d' = NULL, '-u' = NULL, '-e' = NULL,'-v' = NULL,'-f' = NULL,'-o' = NULL,'-c' = NULL, '-s' = NULL)

"parse.args" <- function(allowed.args,helplist=NULL){
    argv <- commandArgs(trailingOnly=TRUE)
    # print help string if requested
    if(!is.null(helpstr) && sum(argv == '-h')>0){
        cat('',helpstr,'',sep='\n')
        q(runLast=FALSE)
    }
    argpos <- 6
    for(name in names(allowed.args)){
        argpos <- which(argv == name)
        if(length(argpos) > 0){
            # test for flag without argument
            if(argpos == length(argv) || substring(argv[argpos + 1],1,1) == '-')
                allowed.args[[name]] <- TRUE
            else {
                allowed.args[[name]] <- argv[argpos + 1]
            }
        }
    }
    return(allowed.args)
}

# parse arg list
flag <- 0
arglist <- parse.args(allowed.args)
path <- arglist[['-d']]
verbosity <- arglist[['-v']]
ns <- arglist[['-u']]
ne <- arglist[['-e']]
filename <- arglist[['-f']]
filename2 <- arglist[['-o']]
crit <- arglist[['-c']]
seed <- arglist[['-s']]

# set default values
if(is.null(verbosity)) 
  flag <- 1

if(is.null(ns)) ns <- 2
if(is.null(ne)) ne <- 8
if(is.null(crit)) crit <- "laplace"
if(is.null(seed)) seed <- 1
#if(is.null(filename)) filename <- "number_of_partitions.eps"
if(is.null(filename2)) filename2 <- "source_proportion_dmn.txt"


# check input
if(ns > ne){
  ntmp<-ne
  ne<-ns
  ns<-ntmp
}

# load library
library("DirichletMultinomial")


#Read data from file
if(flag==1) cat(sprintf('Read data from file %s...\n',path))
data<-as.matrix(t(read.table(path,sep='\t',header=T,row.names=1,check=F,skip=1,comment='')))


if(flag==1) cat(sprintf('dim(data): %d x %d\n',dim(data)[1],dim(data)[2]))
if(dim(data)[1]==0 | dim(data)[2]==0){
  stop('NB! Dimension of otu matrix is: %d x %d\nPlease check if the provided path is correct!\n',dim(data)[1],dim(data)[2])
}

# main loop over the number of metacommunities
if(flag==1){ 
  cat(sprintf('Analyzing number of metacommunities...\n'))
  fit <- mclapply(ns:ne, dmn, count=data, verbose=TRUE, seed=seed)
}else {
  fit <- mclapply(ns:ne, dmn, count=data, verbose=FALSE, seed=seed)
}

if(flag==1) cat(sprintf('fit\n'))
if(flag==1) print(fit)

lplc <- sapply(fit, crit) 
if(flag==1) cat(sprintf('Model selection score:\n'))
if(flag==1) print(lplc)
if(!is.null(filename)){
   pdf(filename) 
   plot(lplc, type="b", xlab="Number of Dirichlet Components", ylab="Model Fit")
   dev.off() 
}
best <- fit[[which.min(lplc)]]
cat(sprintf('The optimal number of metacommunities using %s criterion:',crit))
print(best)
if(flag==1) cat(sprintf('Metacommunity proportions:\n'))
if(flag==1) print(mixture(best))
write.table(mixture(best),filename2,quote=F,sep='\t')





