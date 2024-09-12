# Copyright (c) 2024 Patrick Marsh.
# Distributed under the terms of the BSD 2-Clause License.
"""Plotting functions."""

import matplotlib.pyplot as plt


def createColorBar(ax, CS=None, ticks=None, ticklabels=None):
    pos = ax.get_position()
    l, b, w, h = pos.bounds
    cax = plt.axes([l+w-0.075, h/5., 0.025, h/3.], frameon=True, axisbg='w')
    cax.xaxis.set_major_locator(plt.NullLocator())
    cax.yaxis.set_major_locator(plt.NullLocator())
    cbar = plt.colorbar(CS, drawedges=True, cax=cax, ticks=ticks)
    if ticklabels:
        cbar.ax.set_yticklabels(ticklabels)
    plt.axes(ax)    # Return axes instances back to figure


def createTitle(ax, title='', fsize=14):
    pos = ax.get_position()
    l, b, w, h = pos.bounds
    tax = plt.axes([l, b + h, w, 0.1], frameon=False, axisbg=None)
    tax.xaxis.set_major_locator(plt.NullLocator())
    tax.yaxis.set_major_locator(plt.NullLocator())
    plt.text(0.5, 0.5, title, ha="center", va="center", fontsize=fsize,
             axes=tax)        
    plt.axes(ax)


def createPlotInfo(ax, ptype, pdate, pvalid, pfield, pthresh, proi, psigma,
                   pmembers, pmax, fsize=8):
    pos = ax.get_position()
    l, b, w, h = pos.bounds
    tax = plt.axes([l, b + h, w, 0.1], frameon=False, axisbg=None)
    tax.xaxis.set_major_locator(plt.NullLocator())
    tax.yaxis.set_major_locator(plt.NullLocator())
    plt.text(0, 0.8, r'$\bf{Plot:}$ %s' % (ptype), ha="left", va="center",
             fontsize=fsize, axes=tax)
    plt.text(0, 0.6, r'$\bf{Init:}$ %s UTC' % (pdate), ha="left", va="center",
             fontsize=fsize, axes=tax)
    plt.text(0, 0.4, r'$\bf{Valid:}$ %s UTC' % (pvalid), ha="left",
             va="center", fontsize=fsize, axes=tax)
    plt.text(
        0, 0.2, r'$\bf{Field\//\/Threshold:}$ %s / %s' % (pfield, pthresh),
        ha="left", va="center", fontsize=fsize, axes=tax
    )

    plt.text(1, 0.8, r'$\bf{ROI:}$ %s' % (proi), ha="right", va="center",
             fontsize=fsize, axes=tax)
    plt.text(1, 0.6, r'$\bf{Sigma:}$ %s' % (psigma), ha="right", va="center",
             fontsize=fsize, axes=tax)
    plt.text(1, 0.4, r'$\bf{\# \/ of \/ Members \/ Used:}$ %i' % (pmembers),
             ha="right", va="center", fontsize=fsize, axes=tax)
    plt.text(1, 0.2, r'$\bf{Max \/ Probability:}$ %2.2f%%' % (pmax),
             ha='right', va='center', fontsize=fsize, axes=tax)
    plt.axes(ax)


def get_mainColorList():
    colors = ['#DAD2FF',    # 0.1
              '#BDAEFF',    # 1
              '#635A8B',    # 5
              '#BFFFFF',    # 10
              '#00FFFF',    # 15
              '#0066FF',    # 20
              '#000099',    # 25
              '#C8FFBF',    # 30
              '#5AFF3F',    # 35
              '#00CD00',    # 40
              '#138B00',    # 45
              '#FFDADA',    # 50
              '#CD8592',    # 55
              '#FFBF7F',    # 60
              '#FF7F00',    # 65
              '#FF7F7F',    # 70
              '#FF1919',    # 75
              '#FFBFBF',    # 80
              '#8B0000',    # 85
              '#FFFFFF',    # 90
              '#000000']    # 95

    return colors


def get_colorBarLabels():
    tick_labels = ['0.1', '5', '15', '25', '35', '45', '55', '65', '75',
                   '85', '95']
    ticks = [0.1, 5, 15, 25, 35, 45, 55, 65, 75, 85, 95]

    return (ticks, tick_labels)
