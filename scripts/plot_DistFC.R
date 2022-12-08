#' Function to plot the distance x functional connectivity scatter plot 
#' 
#' @param FC_list A list of symmetric matrix (ROI x ROI) with functional connectivity.
#' @param Dist_list A list of symmetric distance matrix (ROI x ROI) that describes the distances between any two ROIs.
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
plot_DistFC <- function(FC_list, Dist_list, color.line = "red", lwd.line = 2, title = NULL){
  require(ggplot2)
  
  ## Check dimension
  dim.FC <- lapply(FC_list, dim)
  dim.Dist <- lapply(Dist_list, dim)
  
  ### Get dimensions for each matrix
  dim2check.FC <- lapply(lapply(dim.FC, unique), length) > 1
  dim2check.Dist <- lapply(lapply(dim.Dist, unique), length) > 1
  
  ### If the inputs are square matrices
  if (sum(dim2check.FC) > 0 | sum(dim2check.Dist) > 0){
    if (sum(dim2check.FC) > 0){
      dim2check.FC.show <- dim2check.FC[dim2check.FC == TRUE]
      message("FC_list needs to have square matrices. Please check the FC matrix below.")
      print(dim2check.FC.show)
    }
    if (sum(dim2check.Dist) > 0){
      dim2check.Dist.show <- dim2check.Dist[dim2check.Dist == TRUE]
      message("Dist_list needs to be a square matrix. Please check the Dist matrices listed below.")
      print(dim2check.Dist.show)
    }
    stop("Error: Dimension mismatch.")
  }
  
  ### If the dimensions of the FC and Dist are matching
  if (sum(!(dim.FC %in% dim.Dist)) > 0){
    dimComp.show <- dim.FC %in% dim.Dist
    message("The dimensions of FC matrices do not match the dimensions of Dist matrices.")
    print(dimComp.show)
    stop("Error: Dimension mismatch.")
  }
  if (length(dim.FC) != length(dim.Dist)){
    stop("FC_list and Dist_list need to include the same number of matrices.")
  }
  
  ### If the matrices are symmetric
  if (sum(lapply(FC_list, isSymmetric.matrix) == 0) > 0)
    warning("Some matrices in your FC_list are not symmetric. The upper triangle was used to plot.")
  if (sum(lapply(Dist_list, isSymmetric.matrix) == 0) > 0)
    warning("Some matrices in your Dist_list are not symmetric. The upper triangle was used to plot.")
  
  ## Organize data
  FClist.in.vec <- lapply(FC_list, as.vector)
  Distlist.in.vec <- lapply(Dist_list, as.vector)
  data2plot <- data.frame(FC_vec = unlist(FClist.in.vec),
                          Dist_vec = unlist(Distlist.in.vec))
  ## plot
  data2plot %>%
    ggplot(aes(x = Dist_vec, y = FC_vec)) +
    geom_point() +
    geom_smooth(se = FALSE, color = color.line, size = lwd.line) +
    geom_hline(yintercept = 0) +
    ggtitle(paste0(title, "\nr = ", round(cor(data2plot$Dist_vec, data2plot$FC_vec), 2))) +
    xlab("Distance") +
    ylab("FC") +
    theme(panel.grid = element_blank(),
          panel.grid.major = element_blank(),
          panel.background = element_blank(),
          axis.line = element_line(colour = "black"))
}