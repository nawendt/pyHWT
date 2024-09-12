cimport cython
import numpy as np
cimport numpy as np

DTYPE = np.int
DTYPE32 = np.float32
DTYPE64 = np.float64
ctypedef np.npy_int DTYPE_t
ctypedef np.npy_float DTYPE32_t
ctypedef np.npy_double DTYPE64_t

cdef extern from 'math.h':
    float sinf(float x)
    float cosf(float x)
    float acosf(float x)

@cython.boundscheck(False)
@cython.cdivision(True)
def point_in_poly(np.ndarray[DTYPE64_t, ndim=1] xverts,
                  np.ndarray[DTYPE64_t, ndim=1] yverts,
                  np.ndarray[DTYPE64_t, ndim=2] xpts,
                  np.ndarray[DTYPE64_t, ndim=2] ypts,
                  np.ndarray[DTYPE64_t, ndim=2] grid,
                  int mini, int maxi, int minj, int maxj):
    '''
    Determine if a point is inside a given polygon or not
    Polygon is a list of (x,y) pairs. This fuction
    returns True or False.  The algorithm is called
    "Ray Casting Method".
    '''

    cdef unsigned int n = xverts.shape[0]
    cdef int inside = 0
    cdef float p2x, p1x = xverts[0]
    cdef float p2y, p1y = yverts[0]
    cdef float x, y, xinters
    cdef unsigned int i, j, k

    if mini < 0: mini = 0
    if maxi >= xpts.shape[1]: maxi = xpts.shape[1]
    if minj < 0: minj = 0
    if maxj >= ypts.shape[0]: maxj = ypts.shape[0]

    for i from minj <= i < maxj:
        for j from mini <= j < maxi:
            x = xpts[i,j]
            y = ypts[i,j]
            inside = 0
            for k in range(n+1):
                p2x = xverts[k % n]
                p2y = yverts[k % n]
                if y > min(p1y, p2y):
                    if y <= max(p1y, p2y):
                        if x <= max(p1x, p2x):
                            if p1y != p2y:
                                xinters = (y-p1y)*(p2x-p1x)/(p2y-p1y)+p1x
                                if p1x == p2x or x <= xinters:
                                    inside += 1
                p1x, p1y = p2x, p2y
            if inside % 2 == 1: grid[i, j] += 1
    return grid





@cython.boundscheck(False)
def geo_grid_data(np.ndarray[DTYPE64_t, ndim=1] ilon,
                  np.ndarray[DTYPE64_t, ndim=1] ilat,
                  np.ndarray[DTYPE64_t, ndim=2] mlons,
                  np.ndarray[DTYPE64_t, ndim=2] mlats,
                  float dx):

    cdef float PI = 3.14159265
    cdef float RADIUS = 3956.0
    cdef float PI_4_DEG2RAD = PI/180.0
    cdef float PI_4_RAD2DEG = 180.0/PI
    cdef float NM2KM = 69.0467669*1.609344

    cdef unsigned int kk = ilon.shape[0]
    cdef unsigned int jj = mlons.shape[1]
    cdef unsigned int ii = mlons.shape[0]
    cdef float min_dist, hdx
    cdef float c, x
    cdef Py_ssize_t i, j, k

    cdef np.ndarray[DTYPE64_t, ndim=2] rlat = np.zeros([ii,jj], dtype=DTYPE64)
    cdef np.ndarray[DTYPE64_t, ndim=2] dist = np.zeros([ii,jj], dtype=DTYPE64)
    cdef np.ndarray[DTYPE64_t, ndim=2] grid = np.zeros([ii,jj], dtype=DTYPE64)
    cdef np.ndarray[DTYPE64_t, ndim=1] rilat = np.zeros([kk], dtype=DTYPE64)
    cdef np.ndarray[DTYPE_t, ndim=1] xinds = np.zeros([kk], dtype=DTYPE)
    cdef np.ndarray[DTYPE_t, ndim=1] yinds = np.zeros([kk], dtype=DTYPE)

    hdx = dx / 2.0
    for k in range(kk):
        rilat[k] = ilat[k] * PI_4_DEG2RAD

    for j in range(jj):
        for i in range(ii):
            rlat[i,j] = mlats[i,j] * PI_4_DEG2RAD

    for k in range(kk):
        min_dist = 99999.0
        for i in range(ii):
            for j in range(jj):
                c = (ilon[k]-mlons[i,j]) * PI_4_DEG2RAD
                x = (sinf(rlat[i,j]) * sinf(rilat[k]) + cosf(rlat[i,j]) *
                        cosf(rilat[k]) * cosf(c))
                dist[i,j] = acosf(x) * PI_4_RAD2DEG * NM2KM
                if dist[i,j] < min_dist:
                    min_dist = dist[i,j]
                    xinds[k] = i
                    yinds[k] = j
                    if min_dist <= hdx:
                        break
            if min_dist <= hdx:
                break
        grid[xinds[k], yinds[k]] += 1

    return (grid, xinds, yinds)


@cython.boundscheck(False)
def grid_data(np.ndarray[DTYPE64_t, ndim=1] xvals,
              np.ndarray[DTYPE64_t, ndim=1] yvals,
              np.ndarray[DTYPE64_t, ndim=2] xpts,
              np.ndarray[DTYPE64_t, ndim=2] ypts,
              float dx=1.):

    cdef unsigned int kk = xvals.shape[0]
    cdef unsigned int jj = xpts.shape[1]
    cdef unsigned int ii = ypts.shape[0]
    cdef float min_dist, hdx
    cdef Py_ssize_t i, j, k

    cdef np.ndarray[DTYPE64_t, ndim=2] dist = np.zeros([ii,jj], dtype=DTYPE64)
    cdef np.ndarray[DTYPE64_t, ndim=2] grid = np.zeros([ii,jj], dtype=DTYPE64)
    cdef np.ndarray[DTYPE_t, ndim=1] xinds = np.zeros([kk], dtype=DTYPE)
    cdef np.ndarray[DTYPE_t, ndim=1] yinds = np.zeros([kk], dtype=DTYPE)

    hdx = dx / 2.0
    for k in range(kk):
        min_dist = 99999.0
        for i in range(ii):
            for j in range(jj):
                dist[i,j] = (xvals[k]-xpts[i,j])**2 + (yvals[k]-ypts[i,j])**2
                dist[i,j] = dist[i,j]**0.5
                if dist[i,j] < min_dist:
                    min_dist = dist[i,j]
                    xinds[k] = i
                    yinds[k] = j
                    if min_dist <= hdx:
                        break
            if min_dist <= hdx:
                break
        grid[xinds[k], yinds[k]] += 1

    return (grid, xinds, yinds)


@cython.boundscheck(False)
def ptype(np.ndarray[DTYPE64_t, ndim=2] rain,
          np.ndarray[DTYPE64_t, ndim=2] snow,
          np.ndarray[DTYPE64_t, ndim=2] graupel,
          np.ndarray[DTYPE64_t, ndim=2] cloud,
          np.ndarray[DTYPE64_t, ndim=2] ice,
          np.ndarray[DTYPE64_t, ndim=2] t2m,
          float minimum_threshold=0.01):

    cdef unsigned int ii = cloud.shape[0]
    cdef unsigned int jj = cloud.shape[1]
    cdef Py_ssize_t i, j

    cdef np.ndarray[DTYPE_t, ndim=2] ptype = np.zeros([ii, jj], dtype=DTYPE)

    for i in range(ii):
        for j in range(jj):
            # Is rain the largest
            if (rain[i,j] > cloud[i,j] and rain[i,j] > snow[i,j] and
                rain[i,j] > ice[i,j] and rain[i,j] > graupel[i,j]):
                    if t2m[i,j] > 273.15:
                        ptype[i,j] = 1
                    # Check for Freezing Rain
                    else:
                        ptype[i,j] = 5
            # Is snow the largest
            elif (snow[i,j] > cloud[i,j] and snow[i,j] > rain[i,j] and
                  snow[i,j] > ice[i,j] and snow[i,j] > graupel[i,j]):
                    ptype[i,j] = 2

            # Is graupel the largest
            elif (graupel[i,j] > cloud[i,j] and graupel[i,j] > rain[i,j] and
                  graupel[i,j] > snow[i,j] and graupel[i,j] > ice[i,j]):
                    ptype[i,j] = 3

            # Is cloud the largest
            elif (cloud[i,j] > rain[i,j] and cloud[i,j] > snow[i,j] and
                  cloud[i,j] > ice[i,j] and cloud[i,j] > graupel[i,j]):
                  if t2m[i,j] > 273.15:
                      ptype[i,j] = 6
                  # Check for Freezing Fog
                  else:
                      ptype[i,j] = 7

            # Is ice the largest
            elif (ice[i,j] > cloud[i,j] and ice[i,j] > rain[i,j] and
                  ice[i,j] > snow[i,j] and ice[i,j] > graupel[i,j]):
                    # If ice is the largest, make sure it's greater than
                    # minimum threshold
                    if ice[i,j] > minimum_threshold:
                        ptype[i,j] = 8
                    else:
                        continue

            # Is any of the rain, snow, grapuel equal
            elif (rain[i,j] == snow[i,j] or rain[i,j] == graupel[i,j] or
                  snow[i,j] == graupel[i,j]):
                    if (rain[i,j] == 0 and snow[i,j] == 0 and
                        graupel[i,j] == 0):
                            ptype[i,j] = 0
                    else:
                            ptype[i,j] = 4

            # Is cloud equal to ice
            elif (cloud[i,j] == ice[i,j]):
                    if (cloud[i,j] == 0 and ice[i,j] == 0):
                        ptype[i,j] = 0
                    else:
                        ptype[i,j] = 9

            # If nothing matches, skip
            else:
                    continue

    return ptype


@cython.boundscheck(False)
def layer_sum(np.ndarray[DTYPE32_t, ndim=4] uhfull,
              np.ndarray[DTYPE32_t, ndim=4] z,
              float zbot = 2000., float ztop = 5000.):

    cdef unsigned int kk = uhfull.shape[0]
    cdef unsigned int levs = uhfull.shape[1]
    cdef unsigned int jj = uhfull.shape[2]
    cdef unsigned int ii = uhfull.shape[3]

    cdef float btop, bbot, btmp
    cdef float ttop, tbot, ttmp
    cdef float tnm1, tnm2, tnm3
    cdef float bnm1, bnm2, bnm3
    cdef float bval, tval

    cdef np.ndarray[DTYPE32_t, ndim=3] uh = np.zeros([kk,jj,ii], dtype=DTYPE32)
    cdef Py_ssize_t bbptr, btptr
    cdef Py_ssize_t tbptr, ttptr
    cdef Py_ssize_t k, j, i, lev

    for k in range(kk):
        for j in range(jj):
            for i in range(ii):
                # Find nearest indices
                btop = 9999; ttop = 9999
                bbot = -9999; tbot = -9999
                btmp = -9999; ttmp = -9999
                for lev in range(levs):
                    btmp = z[k, lev, j, i] - zbot
                    ttmp = z[k, lev, j, i] - ztop
                    # Find pointers for bottom level
                    if btmp < 0:
                        if btmp > bbot:
                            bbot = btmp
                            bbptr = lev
                    elif btmp > 0:
                        if btmp < btop:
                            btop = btmp
                            btptr = lev
                    else:
                        bbot = btmp
                        btop = btmp
                        bbptr = lev
                        btptr = lev

                    # Find pointers for top level
                    if ttmp < 0:
                        if ttmp > tbot:
                            tbot = ttmp
                            tbptr = lev
                    elif ttmp > 0:
                        if ttmp < ttop:
                            ttop = ttmp
                            ttptr = lev
                    else:
                        tbot = ttmp
                        ttop = ttmp
                        tbptr = lev
                        ttptr = lev

                # Do bottom Interpolations
                if bbptr == btptr:
                    bval = uhfull[k,bbptr,j,i]
                else:
                    bbot = uhfull[k,bbptr,j,i]
                    btop = uhfull[k,btptr,j,i]
                    bnm1 = zbot - z[k,bbptr,j,i]
                    bnm2 = z[k,btptr,j,i] - z[k,bbptr,j,i]
                    bnm3 = bnm1 / bnm2
                    bval = bbot + bnm3 * (btop - bbot)

                # Do top Interpolations
                if tbptr == ttptr:
                    tval = uhfull[k,tbptr,j,i]
                else:
                    tbot = uhfull[k,tbptr,j,i]
                    ttop = uhfull[k,ttptr,j,i]
                    tnm1 = ztop - z[k,tbptr,j,i]
                    tnm2 = z[k,ttptr,j,i] - z[k,tbptr,j,i]
                    tnm3 = tnm1 / tnm2
                    tval = tbot + tnm3 * (ttop - tbot)

                if bbptr != btptr:
                    uh[k,j,i] += (0.5 * (bval + uhfull[k,btptr,j,i]) *
                        (z[k,btptr,j,i] - zbot))

                for lev in range(btptr, tbptr):
                    uh[k,j,i] += (0.5 * (uhfull[k,lev,j,i] +
                        uhfull[k,lev+1,j,i]) * (z[k,lev+1,j,i] - z[k,lev,j,i]))

                if tbptr != ttptr:
                    uh[k,j,i] += (0.5 * (uhfull[k,tbptr,j,i] + tval) * (ztop -
                        z[k,tbptr,j,i]))
    return uh


@cython.boundscheck(False)
def layer_sum_3D(np.ndarray[DTYPE32_t, ndim=3] uhfull,
                 np.ndarray[DTYPE32_t, ndim=3] z,
                 float zbot = 2000., float ztop = 5000.):

    cdef unsigned int levs = uhfull.shape[0]
    cdef unsigned int jj = uhfull.shape[1]
    cdef unsigned int ii = uhfull.shape[2]

    cdef float btop, bbot, btmp
    cdef float ttop, tbot, ttmp
    cdef float tnm1, tnm2, tnm3
    cdef float bnm1, bnm2, bnm3
    cdef float bval, tval, a

    cdef np.ndarray[DTYPE32_t, ndim=2] uh = np.zeros([jj,ii], dtype=DTYPE32)
    cdef Py_ssize_t bbptr, btptr
    cdef Py_ssize_t tbptr, ttptr
    cdef Py_ssize_t j, i, lev

    for j in range(jj):
        for i in range(ii):
            # Find nearest indices
            btop = 9999; ttop = 9999
            bbot = -9999; tbot = -9999
            btmp = -9999; ttmp = -9999
            for lev in range(levs):
                btmp = z[lev, j, i] - zbot
                ttmp = z[lev, j, i] - ztop
                # Find pointers for bottom level
                if btmp < 0:
                    if btmp > bbot:
                        bbot = btmp
                        bbptr = lev
                elif btmp > 0:
                    if btmp < btop:
                        btop = btmp
                        btptr = lev
                else:
                    bbot = btmp
                    btop = btmp
                    bbptr = lev
                    btptr = lev

                # Find pointers for top level
                if ttmp < 0:
                    if ttmp > tbot:
                        tbot = ttmp
                        tbptr = lev
                elif ttmp > 0:
                    if ttmp < ttop:
                        ttop = ttmp
                        ttptr = lev
                else:
                    tbot = ttmp
                    ttop = ttmp
                    tbptr = lev
                    ttptr = lev

            # Do bottom Interpolations
            if bbptr == btptr:
                bval = uhfull[bbptr,j,i]
            else:
                bbot = uhfull[bbptr,j,i]
                btop = uhfull[btptr,j,i]
                bnm1 = zbot - z[bbptr,j,i]
                bnm2 = z[btptr,j,i] - z[bbptr,j,i]
                bnm3 = bnm1 / bnm2
                bval = bbot + bnm3 * (btop - bbot)

            # Do top Interpolations
            if tbptr == ttptr:
                tval = uhfull[tbptr,j,i]
            else:
                tbot = uhfull[tbptr,j,i]
                ttop = uhfull[ttptr,j,i]
                tnm1 = ztop - z[tbptr,j,i]
                tnm2 = z[ttptr,j,i] - z[tbptr,j,i]
                tnm3 = tnm1 / tnm2
                tval = tbot + tnm3 * (ttop - tbot)

            if bbptr != btptr:
                uh[j,i] += (0.5 * (bval + uhfull[btptr,j,i]) *
                    (z[btptr,j,i] - zbot))

            for lev in range(btptr, tbptr):
                uh[j,i] += (0.5 * (uhfull[lev,j,i] + uhfull[lev+1,j,i]) *
                    (z[lev+1,j,i] - z[lev,j,i]))

            if tbptr != ttptr:
                uh[j,i] += (0.5 * (uhfull[tbptr,j,i] + tval) *
                    (ztop - z[tbptr,j,i]))
    return uh






