Testing Visualization
================
Ju-Chi Yu
2022-12-06

### Visualzing the correlation between euclidean distance and activation to QC for motion

#### Fake data

``` r
FC_matrix <- list()
Dist_matrix <- list()

## sub 1
set.seed(2022)
timeseries <- matrix(rnorm(10000), nrow = 100)
FC_matrix[['sub1']] <- cor(timeseries)

dim.mat <- dim(FC_matrix[['sub1']])[1]
distance <- diag(0, dim.mat)
distance[upper.tri(distance)] <- abs(rnorm(dim.mat*(dim.mat-1)/2, 1, 1))
Dist_matrix[['sub1']]  = distance + t(distance)

## sub 2
set.seed(2023)
timeseries <- matrix(rnorm(10000), nrow = 100)
FC_matrix[['sub2']] <- cor(timeseries)

dim.mat <- dim(FC_matrix[['sub2']])[1]
distance <- diag(0, dim.mat)
distance[upper.tri(distance)] <- abs(rnorm(dim.mat*(dim.mat-1)/2, 1, 1))
Dist_matrix[['sub2']]  = distance + t(distance)

## sub 3
set.seed(2024)
timeseries <- matrix(rnorm(10000), nrow = 100)
FC_matrix[['sub3']] <- cor(timeseries)

dim.mat <- dim(FC_matrix[['sub3']])[1]
distance <- diag(0, dim.mat)
distance[upper.tri(distance)] <- abs(rnorm(dim.mat*(dim.mat-1)/2, 1, 1))
Dist_matrix[['sub3']]  = distance + t(distance)

## arrays
FC_Array <- array(unlist(FC_matrix), dim = c(dim(FC_matrix[[1]]), 3))
Dist_Array <- array(unlist(Dist_matrix), dim = c(dim(Dist_matrix[[1]]), 3))

## face mean FD

meanFD_vec <- rnorm(3)
```

<img src="Testing-Visualization_files/figure-gfm/unnamed-chunk-2-1.png" width="50%" /><img src="Testing-Visualization_files/figure-gfm/unnamed-chunk-2-2.png" width="50%" />

#### FC-QC vs. correlation

The `plot_DistFCQC` can be used to plot the scatter plot of distances
(diagonals included) and the correlations between mean frame
displacements (FDs; as QC measures) and functional connectivity (FC).
The aim of this figure is to help check if there is a bump when their
euclidean distance in the 3D space is small. If so, it means that there
is a motion confound in the functional connectivity data. If the motion
effect is removed by scrubbing, you should see a line that is almost
flat.

##### How to use `plot_DistFCQC`

`plot_DistFCQC` takes two arguments:

-   `FC_Array`: An array of symmetric matrices (ROI x ROI x subject)
    with functional connectivity.

-   `Dist_Array`: An array of symmetric distance matrices (ROI x ROI x
    subject) that describes the distances between any two ROIs.

-   `meanFD_vec`: A vector of mean FD.

There are also other arguments that you can specify:

-   `color.line`: The color for the estimated smoothed line. Default:
    red.

-   `lwd.line`: The width of the line. Default: 2.

-   `title`: The title of the figure. Default: NULL. When NULL, only the
    coefficient of correlation will be printed.

*Note: If you want to remove the correlation in the title, you can add
`theme(title = element_blank())` to your ggplot.*

``` r
## This is how you source the function
source("../scripts/plot_DistFCQC.R")

## and plot the results
plot_DistFCQC(FC_Array = FC_Array,
            Dist_Array = Dist_Array, 
            meanFD_vec = meanFD_vec,
            color.line = "red", lwd.line = 2,
            title = "FD threshold = w, scrubs = v")
```

    ## Warning in cor(meanFD_vec, t(FC_upper)): the standard deviation is zero

    ## `geom_smooth()` using method = 'gam' and formula 'y ~ s(x, bs = "cs")'

    ## Warning: Removed 100 rows containing non-finite values (stat_smooth).

    ## Warning: Removed 100 rows containing missing values (geom_scattermore).

![](Testing-Visualization_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->
