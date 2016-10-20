#!/usr/bin/env Rscript

# merge several source OTU lists and make a bar plot on source proportion for each OTU
# dir is the directory of the files, where all files ending with "contributions.txt" is accepted
# gg.path is the path to the greengenes taxonomy file
# phylum sets which taxa to show in the plot, give 'NULL' for all taxa
# format is a flag which sets the type of plot to produce: format = NULL, plots all sources of the signal (i.e. each bar adds to one) while; format = source name, plots the source of interest (i.e. format = sewage)  
# sample is a flag which selects one sample if there are multiple samples available, otherwise the only sample is chosen (the default)
#
#
# NB! The header is needed for each separate file, which is given by the script modify_full_results_for_github.R
# NB! The order of the header should be (separated by tab): OTU.ID	sample.ID	row.number	taxonomy
# by Jon Ahlinder

helpstr <- c('merge several source OTU lists and make a bar plot on probability of source origin for each OTU contributing to the signal. NB! The header is needed for each separate file, which is given by the script modify_full_results_for_github.R. Make sure that the header of all files all start with OTU.ID!\n\n-d directory where all source associated OTU files are stored. All file names ending with "contributions.txt" is processed as given from script modify_full_results_for_Github.R.\n-p Utilized reference taxonomy (e.g. taxonomy file from GreenGenes).\n-r which taxonomic groups to show in the plot (i.e. Firmicutes), default is all taxa.\n-o file path of the created figure.\n-f which source to plot, where the default is showing all sources.\n-i the sample for which to plot the obtained signal.\n-v verbosity\n')

allowed.args <- list('-d' = NULL, '-p' = NULL, '-r' = NULL, '-o' = NULL, '-f' = NULL,'-i' = NULL,'-v' = NULL)

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
arglist <- parse.args(allowed.args)
dir <- arglist[['-d']]
verbosity <- arglist[['-v']]
fig.path <- arglist[['-o']]
format <- arglist[['-f']]
sample <- arglist[['-i']]
phylum <- arglist[['-r']]
gg.path <- arglist[['-p']]

# set default values
if(is.null(verbosity)) verbosity <- 0
if(is.null(phylum)) phylum <- c("Firmicutes","Proteobacteria")
if(is.null(gg.path)) gg.path <- "/mnt/powervault/andrsjod/qiime_db/gg_13_8_otus/taxonomy/97_otu_taxonomy.txt"
if(is.null(fig.path)) fig.path <- "OTU_source_signal_bar_plot.eps"
save <- 1

# read files from directory
files<-list.files(path=dir)
files2<-grep("contributions.txt",files,value=TRUE)
if(verbosity==1) print(files2)
n.files<-length(files2)
# change sample names
for(i in 1:n.files){

  path<-paste(dir,files2[i],sep="")
  data.n<-read.table(path,sep='\t',header=T)

  # change sample name and drop unwanted columns
  name<-strsplit(files2[i],"_")[[1]][1]
  if(verbosity==1) cat(sprintf("name: %s\n",name))
  if(is.null(sample)){
    colnames(data.n)[2]<-name
    data.n2<-data.n[,1:2]
  }
  else{
    c.names<-colnames(data.n)
    index<-which(c.names==sample)
    l1<-length(data.n[,1])
    data.n2<-cbind(data.n[,1],data.n[,index])
    dim(data.n2)<-c(l1,2)
    if(verbosity==1) cat(sprintf("dimension of data.n2: %d x %d\n",dim(data.n2)[1],dim(data.n2)[2]))
    colnames(data.n2)[2]<-name
    colnames(data.n2)[1]<-"OTU.ID"

  } 
  if(i > 1){ # merge files
    if(verbosity==1) cat(sprintf('colnames of data frames prior to merging....:\n'))
    if(verbosity==1) print(colnames(data.a))
    if(verbosity==1) print(colnames(data.n2))
    data.m<-merge(data.a,data.n2,all=TRUE,by="OTU.ID")
    

    data.a<-data.m
  } 
  else data.a<-data.n2

 # if(verbosity==1) print(read.table(files2[i],sep='\t',header=T))
 # if(verbosity==1) print(l.data[i])
}
n.files1<-n.files+1
for(i in 2:n.files1){
    index<-is.na(data.a[,i])
    data.a[index,i]<-0

}

# add taxonomy from greengenes
tax<-read.table(gg.path,sep="\t")
colnames(tax)<-c("OTU.ID","taxonomy")
data.m<-merge(data.a,tax,all.x=TRUE,by="OTU.ID")
l.p<-length(phylum)

if(l.p > 0){
  index<-0
  for(i in 1:l.p){
    index.t<-grep(phylum[i],data.m$taxonomy)
    index<-c(index,index.t)
  }
  index<-index[-1]
}
data.m<-data.m[index,]
c.names<-colnames(data.m)
col.vec<-0
# definition of standard env colors
std.env.colors <- c(
'#47697E',
'#5B7444',
'#79BEDB',
'#FFCC33',
'#003366',
'#272B20',
'#885588',
'#128244',
'#1DBDBC',
'#EF81E9',
'#5EEA6E',
'#CC6666',
'#A43995',
'#E93E4A',
'#F4EE16',
'#663333',
'#3F52A2',
'#656565'
)
for(i in 2:n.files1){ # pre-defined source group names
  if(c.names[i]=='background' | c.names[i]=='raw') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-11])
  if(c.names[i]=='sewage') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-10]) 
  if(c.names[i]=='stormwater' | c.names[i]=='storm') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-9])
  if(c.names[i]=='dog') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-8])
  if(c.names[i]=='cow') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-7])
  if(c.names[i]=='calf') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-6])
  if(c.names[i]=='wild_bird' | c.names[i]=='wild') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-5])
  if(c.names[i]=='sheep') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-4])
  if(c.names[i]=='domestic_bird' | c.names[i]=='domestic') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-3])
  if(c.names[i]=='horse') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-2])
  if(c.names[i]=='pig_piglet' | c.names[i]=='pig') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)-1])
  if(c.names[i]=='Unknown') col.vec<-c(col.vec,std.env.colors[length(std.env.colors)])
}
col.vec<-col.vec[-1]
if(is.null(format)){
  # plot results
  cat(sprintf('fig.path: %s\n',fig.path))
  postscript(fig.path)
  barplot(t(as.matrix(data.m[,2:n.files1])), col=col.vec, xlab="OTU", ylab="Source proportion", border=NA,cex.lab=1.4,cex.axis=1.4, space=0, xaxt='n') 
  dev.off()
} else {

  j<-which(c.names==format)
  index<-which(data.m[,j]==0)
  tax<-data.m[-index,n.files+2] 
  data.s<-data.m[-index,j]
  data.s<-as.vector(data.s)
  n.OTU<-length(data.s)
  col.vec<-vector("character",n.OTU)
  jon.col <- c('red','blue','green','yellow','grey','brown','pink','black','cyan','lightblue')
  if(l.p > 0){ # get colors for different taxonomic groups
    for(i in 1:l.p){
      index.t<-grep(phylum[i],tax)
      col.vec[index.t]<-jon.col[i]
      cat(sprintf('nOTU in %s: %d\n',phylum[i],length(index.t)))
    }
  }
  # plot results
  postscript(fig.path)
  barplot(data.s, col=col.vec, xlab="OTU", ylab=c(format," proportion"), border=NA,cex.lab=1.4,cex.axis=1.4, space=0, xaxt='n') 
 dev.off()
}

 



