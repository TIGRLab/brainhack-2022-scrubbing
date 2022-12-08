#' Function to plot the distance x correlation b/w functional connectivity and mean FD scatter plot 
#' 
#' @param FC_Array An array of symmetric matrix (ROI x ROI) with functional connectivity.
#' @param Dist_Array A list of symmetric distance matrix (ROI x ROI) that describes the distances between any two ROIs.
#' @param meanFD_vec A vector of mean FDs
#' @param color.line The color for the estimated smoothed line. Default: red.
#' @param lwd.line The width of the line. Default: 2.
#' @param title The title of the figure. Default: NULL.
#'
#' @return A scatter plot with distance on the x axis and functional connectivity on the y axis.
#' @export
#'
#' @examples
#' ## create fake data
#' set.seed(2022)
#' timeseries <- matrix(rnorm(10000), nrow = 100)
#' FC_list <- cor(timeseries)
#' 
#' dim.mat <- dim(FC_list)[1]
#' distance <- diag(0, dim.mat)
#' distance[upper.tri(distance)] <- abs(rnorm(dim.mat*(dim.mat-1)/2, 1, 1))
#' distance  = distance + t(distance)
#' 
#' ## plot the results
#' plot_DistFC(FC_list = FC_list,
#'             Dist_list = distance, 
#'             color.line = "red", lwd.line = 2,
#'             title = "FD threshold = w, scrubs = v")
plot_DistFCQC <- function(FC_Array, Dist_Array, meanFD_vec, color.line = "red", lwd.line = 2, title = NULL){
  require(ggplot2, scattermore)
  
  ## Check dimension
  dim.FC <- dim(FC_Array)
  dim.Dist <- dim(Dist_Array)
  
  ### If the inputs are square matrices
  if ((dim.FC[1] != dim.FC[2]) | (dim.Dist[1] != dim.Dist[2])){
    if ((dim.FC[1] != dim.FC[2])){
      message("FC matrices need to be square matrices.")
    }
    if ((dim.Dist[1] != dim.Dist[2])){
      message("Dist matrices need to be square matrices.")
    }
    stop("Error: Dimension mismatch.")
  }
  
  ### If the dimensions of the FC and Dist are matching
  if (sum(dim.FC != dim.Dist) > 0){
    stop("Error: Dimensions of FC_Array and Dist_Arry are not matching.")
  }
  ### If the number of tables are the same as the number of subjects
  if (dim.FC[3] != length(meanFD_vec)){
    stop("The number of table doesn't match the number of subjects in meanFD_vec.")
  }
  
  ### If the matrices are symmetric
  if (sum(apply(FC_Array, 3, is_symmetric) == 0) > 0)
    warning("Some matrices in your FC_list are not symmetric. The upper triangle was used to plot.")
  if (sum(apply(Dist_Array, 3, is_symmetric) == 0) > 0)
    warning("Some matrices in your Dist_list are not symmetric. The upper triangle was used to plot.")
  
  ## Organize data
  ### Edges x subject
  FC_upper <- apply(FC_Array, 3, function(x) x[upper.tri(x, diag = TRUE)])
  Dist_upper <- apply(Dist_Array, 3, function(x) x[upper.tri(x, diag = TRUE)])
  
  ### data.frame
  data2plot <- data.frame(Dist_vec <- rowMeans(Dist_upper), ## Average Dist_upper for across subjects
                          FCQC_vec <- as.vector(cor(meanFD_vec, t(FC_upper))))   ## FC-QC correlation
  
  ## plot
  ## faster
  print(ggplot(data2plot, aes(x=Dist_vec, y=FCQC_vec)) +
          geom_scattermore()+
          geom_smooth(se = FALSE, color = color.line, size = lwd.line) +
          geom_hline(yintercept = 0) +
          ggtitle(paste0(title, "\nr = ", round(cor(data2plot$Dist_vec, data2plot$FCQC_vec), 2))) +
          xlab("Distance") +
          ylab("FC-QC correlation") +
          theme(panel.grid = element_blank(),
                panel.grid.major = element_blank(),
                panel.background = element_blank(),
                axis.line = element_line(colour = "black")))
}

is_symmetric <- function(x){
  up.x <- x[upper.tri(x)]
  lw.x <- t(x)[upper.tri(t(x))]
  if (sum(up.x != lw.x) > 0){
    return(FALSE)
  }else{
    return(TRUE)
  }
}
