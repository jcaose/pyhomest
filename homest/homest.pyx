
cimport numpy
import numpy
from stdlib cimport malloc, free

cdef extern from "homest.h":
    enum: 
        HOMEST_OK = 0 
        HOMEST_ERR = -1
    enum: 
        NUM_HPARAMS = 9

    enum:
        HOMEST_NO_NLN_REFINE   =0 #/* no non-linear refinement */
        HOMEST_XFER_ERROR      =1 #/* non-linear refinement using=2nd image homographic transfer error (non-symmetric) */
        HOMEST_SYM_XFER_ERROR  =2 #/* non-linear refinement using symmetric homographic transfer error */
        HOMEST_SAMPSON_ERROR   =3 #/* non-linear refinement using Sampson error */
        HOMEST_REPR_ERROR      =4 #/* non-linear refinement using reprojection error */
        HOMEST_XFER_ERROR1     =5 #/* non-linear refinement using=1st image inverse homographic transfer error (non-symmetric) */

    enum:
        HOMEST_XFER_ERROR2     =1 #HOMEST_XFER_ERROR /* alias */


    int c_homest "homest" (
            double (*pts0)[2], double (*pts1)[2], #matched point features
            int nmatches, 
            double inlPcent, #percentage of inliers >= 0.5
            double H01[NUM_HPARAMS], #estimated homography
            int normalize,  # if normalize according to Hartley
            int nl_refine,   #the cost function in the nonlinear refine step
            int *idx_outliers, #indices of detected outlying points
            int *noutliers, #number of outliers
            int verbosity #verbosity level 1 or 0
            ) 

def homest( 
        pts_pairs, # [((x1,y1),(x1',y1')), ...]
        normalize = True,
        inlie_percent = 0.7,
        nl_refine = "SYM_XFER_ERROR", 
        verbosity = 0):
    ''' python interface around the native c_homest
    '''

    cdef int n_matches_ = len(pts_pairs)
    cdef double (*pts0_)[2] 
    cdef double (*pts1_)[2]
    cdef double inlie_percent_ = inlie_percent
    cdef int normalize_ = 1 if normalize else 0 
    cdef int nl_refine_ = HOMEST_SYM_XFER_ERROR
    cdef int *idx_outliers_
    cdef int n_outliers_ = 0
    cdef int verbosity_ = verbosity
    cdef int i

    pts0_ = <double (*)[2]> malloc(n_matches_ * sizeof(double[2]))
    pts1_ = <double (*)[2]> malloc(n_matches_ * sizeof(double[2]))
    
    for i in range(n_matches_):
        pts0_[i][0] = pts_pairs[i][0][0]
        pts0_[i][1] = pts_pairs[i][0][1]
        pts1_[i][0] = pts_pairs[i][1][0]
        pts1_[i][1] = pts_pairs[i][1][1]
 
    idx_outliers_ = <int *> malloc(n_matches_*sizeof(int))

    if nl_refine == "NO_NLN_REFINE":
        nl_refine_ = HOMEST_NO_NLN_REFINE
    elif nl_refine == "XFER_ERROR":
        nl_refine_ = HOMEST_XFER_ERROR
    elif nl_refine == "SYM_XFER_ERROR":
        nl_refine_ = HOMEST_SYM_XFER_ERROR
    elif nl_refine == "SAMPSON_ERROR":
        nl_refine_ = HOMEST_SAMPSON_ERROR
    elif nl_refine == "XFER_ERROR1":
        nl_refine_ = HOMEST_XFER_ERROR1
    else:
        free(pts0_)
        free(pts1_) 
        free(idx_outliers_)
        raise Exception("Unknown nl_refine parameter: " + nl_refine)

    cdef double h01_[NUM_HPARAMS]
    cdef int ret_
    ret_ = c_homest( pts0_, pts1_, n_matches_, 
            inlie_percent_, h01_, normalize_, nl_refine_,
            idx_outliers_, &n_outliers_,
            verbosity_)
    
    if ret_ == HOMEST_ERR:
        free(pts0_)
        free(pts1_) 
        free(idx_outliers_)
        raise Exception("Error occured when call homest, try call with verbose on")

    cdef numpy.ndarray h01 = numpy.zeros([3,3], dtype = numpy.double)
    for i in range(NUM_HPARAMS):
        h01[i/3,i%3] = h01_[i]

    outliers = []
    for i in range(n_outliers_):
        outliers.append(idx_outliers_[i])

    free(pts0_)
    free(pts1_)
    free(idx_outliers_)

    return h01, outliers 
        

