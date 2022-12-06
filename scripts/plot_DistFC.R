#' Function to plot the distance x functional connectivity scatter plot 
#' 
#' @param FC_matrix A symmetric matrix (ROI x ROI) with functional connectivity.
#' @param Dist_matrix A symmetric distance matrix (ROI x ROI) that describes the distances between any two ROIs.
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
#' FC_matrix <- cor(timeseries)
#' 
#' dim.mat <- dim(FC_matrix)[1]
#' distance <- diag(0, dim.mat)
#' distance[upper.tri(distance)] <- abs(rnorm(dim.mat*(dim.mat-1)/2, 1, 1))
#' distance  = distance + t(distance)
#' 
#' ## plot the results
#' plot_DistFC(FC_matrix = FC_matrix,
#'             Dist_matrix = distance, 
#'             color.line = "red", lwd.line = 2,
#'             title = "FD threshold = w, scrubs = v")
plot_DistFC <- function(FC_matrix, Dist_matrix, color.line = "red", lwd.line = 2, title = NULL){
  require(ggplot2)
  
  ## convert to matrix
  FC_matrix <- as.matrix(FC_matrix)
  Dist_matrix <- as.matrix(Dist_matrix)
  
  ## Check dimension
  dim.FC <- dim(FC_matrix)
  dim.Dist <- dim(Dist_matrix)
  
  ### If the inputs are square matrices
  if (dim.FC[1] != dim.FC[2])
    stop("FC_matrix needs to be a square matrix.")
  if (dim.Dist[1] != dim.Dist[2])
    stop("Dist_matrix needs to be a square matrix.")
  if (dim.FC[1] != dim.Dist[1] | dim.FC[2] != dim.Dist[2])
    stop("The dimensions of FC_matrix do not match the dimensions of Dist_matrix.")
  if (!isSymmetric.matrix(FC_matrix))
    warning("FC_matrix is not symmetric. The upper triangle was used to plot.")
  if (!isSymmetric.matrix(Dist_matrix))
    warning("Dist_matrix is not symmetric. The upper triangle was used to plot.")
  
  ## Organize data
  data2plot <- data.frame(FC_vec = FC_matrix[upper.tri(FC_matrix)],
                          Dist_vec = Dist_matrix[upper.tri(Dist_matrix)])
  
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