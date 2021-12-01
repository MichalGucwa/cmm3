# $Id: strategy.tcl,v 1.13 2012/05/21 13:23:39 ccb Exp $
package provide strategy 1.0

set ::pi 3.1415926535897931

# image create photo ::img::disk_disabled16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMaFS4SkuSBRgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAe0lEQVQ4y8WTwQ4CMRBCwfjfwJfjxU3qmmZtNfHd2syQDnSALyEA2BYAL/TZdsZT26ptbXfS0bYd6wHgNtaQ5MorzgJb/F/gPjNsW8A2D7d3BZpkFj4/GkHS210StO056qmJSZAEfLKcgm1KwpUf27sg6fXnHruwgPALHkEYdWK4H9YqAAAAAElFTkSuQmCC"

# image create photo ::img::disk_disabled16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAgACAAIBEKJNNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMaFgEqqry/7AAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABG0lEQVQ4y62TPU4DQQxGn9ejNW1ugISUYltuQE+ZSFDDNoiSmo3EFWi2oUhBkQtwCsoUuUQ4gB0o9keEBNgIPIWtmfHTN7YH/mgCMB5VE6A4IG+5WlcLgNRuFOPRPQDz1zeSJlJKrVcQAeD8pLm8Ws+KsiwndV0v0ld0eCDvgtDmBaSU9qkoPivozd2bzOgIgoigqnvfsqsgNkjmiICENL5dkA0B+FaSiIB4o4h8AGATSEgvv+uVdPFvgNuz44PmYAdw+fCMmWF5jh0ZuRmWGyklqunpsBo83V0AcPP4QqaBZj68C+6+FasqrhkaQwERTKs5Zka44dpAQuNHwHK1nhUA11fVtwUbj/qzZTeJfW/KsjzoQ9V1PeM/7AMoW09sPn50aQAAAABJRU5ErkJggg=="

# image create photo ::img::anomalous16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMWDiIp1f/URwAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAACAElEQVQ4y5WTP2gTYRjGf40NV+Gkh1yXHBZsg61GcLMHBwHHHBkckkIWh9ChFPRcnMWtS4vYzJas4pqmlGxZEugS8aCUgNIOBupQuJAmhfA6vIaa/lF84eGO557n+9573u+DSxXkKfou4VyCgRFHjDgyl2Dgu4RBniJ/K98ldGxkfRVpbSNnNUVrWznHRnyX8E/PxOjFTXHy+D72h9dw27h+g7MBvHoPX7/xsxEyAzA52jlhYy8/g8RzOO2CZcKnd2pcfnuFs+/eIdxpkCLIU3RspFdDLBMplUrieZ7Mz8+LZV5wURRJqVQSy1StYyNBniK+S7i+ikgdASSKIkmn0+J5noBynudJOp2WKIoEVLu+qnnEDo5IZpa0VcuEcrlMpVKhUChgmcp1Oh2GwyHlchnLVG1mCQ6OSGLENWmpI3sb2jLoc2/jek7q6jHiyIQRR06rMGXwX9UfgJWBmDPD+eGxkl/a/zaONIfH4MxwHlucpV1t/j5Ib2C3Ad9/QLcHw6Gi21Nut6EagGoTFmdpj42xtY0EOeTpQ8SeRiZvKexp5YKcasbGODpIK1kNZ4S1BaSFYm1h/NtKFvFd+mP/5qY4Wcnq6lJH9jeRF45if1O5Xk3Nborhlbsw6qTV5tHLnM75wb2LwKpN2PoMT5IMdhpM3ZjyDddZfJd+kOfjZf0vJkQmTtrbOWYAAAAASUVORK5CYII="
 
# image create photo ::img::toggle -data "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAIAAABLMMCEAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QkdFSUfXlJ2hgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAADElEQVQI12NgGKwAAACaAAGksc0qAAAAAElFTkSuQmCC"

# image create photo ::img::toggle_unfocused -data "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAIAAABLMMCEAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QkdFSUs4YIXkAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAHklEQVQI12NgwAYYGRgY/v//jyLEyMiEVS3lotgBAIBoAwreq+OeAAAAAElFTkSuQmCC"

# image create photo ::img::pointer -data "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QkeEBUC9mxBqQAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAbklEQVRIx+2USw4AIQxCgXj/K+vGJrOzH8e4kDXhNRYLPF2tPlXJ0MpAEhWIPKYKRF5jFqKIOQNRdKIoRJl3jUCUbYcXokrHPZCW/IBub4uEkvxOz207mOG0ybcu2cKPHkAA3W7hry26+ow/ndMAbKhM/HqDhk8AAAAASUVORK5CYII="

# image create photo ::img::add_sector -data "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QkeEBQrrcXohAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAzElEQVRIx93TsWpCQRCF4S8iKdOnsrNMGwhpfYSgL7KQysLGYl9ESJ8ithJIa2eTNr2dCNFGw0XMdYU7hR5Y2FmW+efM7nDputlvMiv8YI5PzDBPLJsCbP6584URpol1BKCqAd4Sv6WA1pkFTfCd6UYBoINFph8F+HOTeY0EwPgUpAiQdqsG0o9yUG1XNxIAH/lIviYBHbwUDVoqzJiPH99WJ75JB3v1qkG7pLJUX/GhhniPdPCYuYsEwEM04Ln2DQp/S52eLr5F965GW+nAJiCh4zESAAAAAElFTkSuQmCC"

# image create photo ::img::red_cross12x12 -data "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIcDw82K8IgvgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABSUlEQVQoz32SvWoUARSFvzP7N1fwZ2ORIv5sUNDKFAqCFlZpAmJvGUR8BB/CJ/ApxIcQsZAgWAgRbtQEI9HCgLPszsyxycqwEG95zncP98AlQw8y9DZDa5wyGXqYodcZGihDX4DLhV210r1J5Z0l+An2SyQB22RoZX/Ejww5S+oMbXbgZ1niDPlowEcAnRijsvGnaU9XsY20DVwEXmBzvub9uOb2v4XF/Oqz87vPBjqRbVbmvDnXcP+0fnwfspchZ8iHQ3aX/WKp4NNpT1ewwaYquJahrS6jDvwI+xUSF+Z+14jyuK9bsueW1ieV97vJd7KkyZB/Dviw0A9GHGTIX0uOMzQGUIbWCnu3lcpo/Hl1xvVO0Jl+6291ofGw9eGs0KUCeNxK5aD1UdXTje69k8p/6kIbhT2diVXg5iLpeYbO/uc17mZoHeAvwV+LZfsIJpkAAAAASUVORK5CYII="

# image create photo ::img::green_tick12x12 -data "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABmJLR0QAAADNAABgNL5sAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIcDRkRkdT0bAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAs0lEQVQoz43SP0oDQRiG8d9KSCcWEmxyiMCkEQTZyuARhIDkGsbaOh4g8QA2gqAHsLD5rhG2sbKwitpMIWHd2YGB+fPMw/t9DH1GOBZuYdADHuIVU+GjKsAVnnGJLdJBwb/M8BdqSdNlr4Vdnuel3COhEX6Em79X/0Va4wRvuGszPgnXeX2VzZ/CeB+thBle8v4RFzjEQrJpe1Bhjnsc5fN3yWmp0DPhO3dloucXWAkPXcgvKkYws7tmlewAAAAASUVORK5CYII="

# image create photo ::img::import_sectors16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIQDxgRwZ2u+wAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAACa0lEQVQ4y5WT3UuTYRjGf+/77n3nNp0fqavYsplLNyjoQ6GITAlJMjowooPoDyiJIpYnFkSHk8AkkgiyoM6WdeBBmdBBooS2ilAxZX4MZabty83p3NbJtkol8j55Dp7nvh5+F9clsIUxNjqOAu1AtcdpXwIQ1705CbiAOPANuAAoxkaHwdjo6AQ+CJJ8EGhOL0ipU5Y0Uoup1nT/VEf9rsqWSkGuV4pDy8FjcvJApSDK7aKsrczdf0ZQZRcR881UBEd6Wv8UOLyjemfzics1poq8ckpLzIiFAoH8YPbC3JhtKTSksCixvfYGKl0BkalBnd5W9yU40jOaRtgrqUT9wIP+4c4rT5fmvs+BAGqLgnQ1QbIhhsZsA0BU61AXlaVxMx70z7zx3Jp2+ZSsqpxsd8LN7MosAVWAtbw1GAa9uS5jlLKtBOAQgCrlbjlw2/+1qyzknWYiPIE/4se76iW2FEMJmMmylmcEVHoDwB4A0djouAd0K4VmS8mlZ2hKHzJ2J4n7sZtwIAzjkJN7HEmT/1tAmweQn0a4DqzGwz8RBNBbGzCff49h8i7StQJ4DlpdFaKi3TQbosdpFwBbfDnQ7Xd14fv0kkQsiqHuJtZzHzHvfkGe+SyirM4srUX8AD4AYV3STgMdiJKxuKYJAEGSN/wamXYRGu0d8DjtR/5Kosdp7wYsJOLM97YtL/Q9ITo/vkFgdXEKYGizKONx2qMpLGsiGnwd+PwK79tW1sI+ABIrYVZ+jAO824DwjxKNIUiW4tomwpODhCf65j1OuyGTg/+YfSTj0fnetoggyVrgUfpC2GKdTak6X0zX+Redc9igByk8KQAAAABJRU5ErkJggg=="

# image create photo ::img::import_sectors_disabled16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gQMDSUka83rjwAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAACeUlEQVQ4y5WTu09TARSHv/uk3Na2tLWKbQPlpWHwFUlAEhESUQyTHR3dDI7d/A9wISbqYnTUoSauNkQx0UTFMBBTDBpByqvQUu6l73tbF0oIGCNnPI/vnJz8fgJHiGBkPASMAM+TsWgZQD7Q0wZcA04Am8B7IBGMjNt28+cESaFmVfqBtwDS7qAoNUpXQkOhkRtPRlw993sEZUS1GwWjpUG+3CWIckSUGwOus6Om7DhOZWvJpyfiH/cDTjUPnOq/enfQdcZ9mraWMGVZcWWrx3p2jO0LpqQH5KrX7u25vS7bPeQXp1Vn9/C6nohv1gFhd5e7Y+3TqjET+2a3BcPd6Vy1w9BMpXTeLeLSBFuhO+0I9mYEWcXUU1j5TEFPxOfFXcDS0puVt8vfxZPyuc7+pULWv2O3Yfp81JwiJEHzn8/UH6V6WwCa954YjIz7gIGdH1Pt5bKibB3TyAs5ts0sVtFC2nEVVX9roQ6QnScAPAByMDJ+HehVfWECF279MvWF9MqL1+HymZSjesmCFKhqa1ZqdFf2AJobwFa/oBewrFxGEqhVHO1DaS3Um818eREwZt+Fas6i0tDUboiqVv2bNiQ9EZ9ydg/P1sySp7g2561sr6G4A4KjrW9ba7q4oZSadUeob0vW3GZ9qGJsUFyeLeiJ+EfhgNI6gVFEyekfHANAkJRDW/O/ZzDmJpPJWPSpuL+QjEXngYdULVKTE+bmh2cUUz8OAcrpRYBVAOEfunft6v40gLf/DrK9iWopx8bUY4CXyVh0TvhPE91DkDz+oTFyC9Pkfn7IJWPRBwDifxrxETWL1OREJb/wGeBrvSAc0c5O4Cbwqm7nPzbv79tOSFLSAAAAAElFTkSuQmCC"

# image create photo ::img::add_matrix16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIQDxkTNoj+lgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAApklEQVQ4y72SwRGEIAxFf5wtI17cdqhFa5FaKMQG5EQf2QOGAUTX1Zn9XODxSUKAcEE8s+TrMAXS+QsAzCCFwXminC3oEcYQg1lOfueJunRoJbiViswtpryooKVl6sGW21eyHPfBkgKYt+yMWvYRY8uxAueJcFOHTdQMdebmtcwggm1osJzxzLu5+jo81GkTldUv0vLeFl35iWfs559Ys/808Rt7pA9pb2s3hAci2QAAAABJRU5ErkJggg=="

# image create photo ::img::add_matrix16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIQDy8ZX0GG/QAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAv0lEQVQ4y72S4Q2DIBCF3x1OYscpvx2BGXSDzuAaxQk6h47i6w8qBS2GpkmPkBxfHnA8TlAR7JXpWm6rbHkDALZlJvCLSM4McF1DOmnU+0VE46ZZ4OdwsHOOe5ZdkOiaUtn3zgCDfn7SoEBn3k8AAHvhUbmVXWKThgP8IrKV/W1IycS986mJh7AtidewLemcY8rYK/lAmL1mOsWPcWpiZJ3JSk+18ZP3Jo7jKDVM6jqxzKo7scT+ZOIJK3ZiLXsC276Ov7Hr5usAAAAASUVORK5CYII="

# image create photo ::img::autocomplete_strategy16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIQDzIMzfAOCgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABd0lEQVQ4y7WSPSyDURSGn3vzoSgV6RclEikDTYRQg4QYjV2kZekmaumks8lGYmARi8RWMwmDv0EMDEJiQCJEq6n4/KR+UnEsKpVUdeDZbu553nNycuA/8c6Jf3xd/PlqdD4ZiALRfCH6FznDjyFGATIAvsnhaKS69rjiNp4EnEAcODYKkQGqY2cAnpeySoft6eER8ABaFyIDLExvkKoysT091AHNQBFg14XIGe5cbiyXm5TDBDCBmAGQWJv6UVomgud8j56jFdLxBMa9xaXTTct9EgAFILC+YzYlB/tGA9lym3WJt6GLzpNteg+XedMGobFNrszGwF5IDQFWJuAAcMZKHclzu7MdQImQMkroSN1S/vrIVpuPieA8zzZ7YD+klr66CCiBToEpgZtnbVixUoeklZZTuylr3oCEwyvinRP53NU3VPZDwAUUj3QHfat1rTPvSlPTH8l8f++c6xIVXCu4mN9dnH1XOnsfOeVfqR+Y9Oca+0/5AA0IkM4up0GuAAAAAElFTkSuQmCC"

# image create photo ::img::embedded_radio_off -data "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIBDjYSuvSsoAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAARklEQVQoz7VRMRIAIAiS/v9nGhoKLe8YYuQQRCNM4MKx0yALSdUDEO0Qa7LGZYPNs999JWG4pf8PQPux3b8kHCd8cvbjbExi2xQQ/uBGagAAAABJRU5ErkJggg=="

# image create photo ::img::embedded_radio_on -data "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gIBDjYatC8kkgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAUElEQVQoz5WRwQoAMAhCZ///z+6yEZYEeRryMGvnLAXjcWJQQVJ5AMKGRJN9XA1Iny3VeIi2VFaQ91dsrxRTZ7cTlKW//evfJrjO1Vt/3FoX0cYdELBlkyEAAAAASUVORK5CYII="

class StrategyWidget {
    inherit itk::Widget

    # member variables

    # circle position
    private variable circle_x0 "150"
    private variable circle_x1 "50"
    private variable circle_x2 "250"
    private variable circle_y0 "150"
    private variable circle_y1 "50"
    private variable circle_y2 "250"
    private variable circle_r "100"
    
    # selection
    private variable selected_sector ""

    # sector sets
    private variable sector_sets {}
    private variable current_sector_set ""

    # tree items
    private variable items_by_sector ; # array
    private variable sectors_by_item ; # array

    # strategy variables
    private variable matrix ""
    private variable strategy "Auto"
    private variable rotation "Auto"
    private variable segments "1"
    private variable anomalous "0"
    private variable saved "0"

    # results
    private variable results ""

    # Alignment results
    private variable items_by_axis ; # array
    private variable axes_by_item ; # array

    # Breakdown results
    private variable sector_breakdown_data_by_name ; # array
    private variable resolution_breakdown_data_by_name ; # array
    #private variable breakdown_option ""

    # Chart stipple
    private variable stipple @[file join $::env(MOSFLM_GUI) bitmaps check3x3.xbm]

    private variable testgen_result ""

    # methods
    #public method isSaved
    private method getTempStrFilename
    private method forceTestgen
    public method processTestgenResponse
    public method setupTestgen
    public method linkPeakSep
    public method launch
    public method hide
    public method clear
    public method calculate
    public method autoComplete
    public method getMatrices
    public method getCurrentMatrix
    public method getUsedMatrix { } { return $matrix }

    public method disable
    public method enable
    private method toggleAbility

    # Sector creation methods
    public method makeProtoSector
    public method newProtoSector
    public method addProtoSector
    public method findSectorSet
    public method addSectorToTree

    public method deleteSectorSets
    public method syncSession
    private method SaveToFile
    private method LoadFromFile
    private method putSectorInfo
    private method getStrategyFilename

    # toolbar methods
    public method togglePointer
    public method toggleAddSector
    public method addMatrix
    private method toggleSpacegroup
    public method updateSpacegroupCombo

    # canvas methods
    public method resizeChart
    public method refreshChart
    public method displaySectorSet
    public method displayThumbnails
    public method displayThumbnail
    public method updateThumbnail
    public method selectSectorSet
    public method highlightSectorSet
    public method unHighlightSectorSet

    public method plotCircle
    public method placeSector
    public method plotSector
    public method freeSector
    public method flipSector
    public method stretchSector
    public method updateSector
    private method guessNewExtent
    private method roundPhiExt
    public method anchorSector
    private method selectSector
    private method deselectSector
    private method focusChart
    private method unfocusChart
    private method clickChart
    private method clickSector
    public method placeGuide
    public method hideGuide

    # tree callbacks
    private method toggleSectorInclusion
    private method checkSectorInclusion
    private method uncheckSectorInclusion
    private method sectorTreeClick
    private method rightClickSector
    private method saveClickSector
    private method toggleSectorSelection
    private method sectorTreeKey
    public method deleteSector
    private method consolidateSectors
    private method consolidateSector
    private variable ClickParent ""
    private variable ClickItem ""

    # Graphing methods
    public method plotBreakdown
    public method updateBreakdown
    public method displayCompleteness
    public method plotPie

    # conversions
    public method cartesian2polar
    public method polar2cartesian
    public method chart2canvas
    public method canvas2chart
    public method rad2canvasDeg
    public method rad2chartDeg
    public method chartDeg2rad
    public method chartDeg2canvasDeg
    public method canvasDeg2chartDeg

    public method getPerimeterPoint
    public method angle2perimeterPoint
    public method angle2perimeterAnchor

    # feedback handling
    public method processStrategyResponse
    public method processStrategyBreakdownResponse
    public method processStrategyAlignmentResponse

    public method hack

    constructor { args } { }
}

body StrategyWidget::constructor { args } {

    # Chart toolbar
    itk_component add toolbar {
	frame [.c component toolbar_frame].strategy
    }

    itk_component add divider1 {
	frame $itk_component(toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }
    # Toolbuttons
    
    itk_component add sync_session_tb {
	Toolbutton $itk_component(toolbar).sstb \
	    -type "amodal" \
	    -image ::img::import_sectors16x16 \
	    -disabledimage ::img::import_sectors_disabled16x16 \
	    -command [code $this syncSession] \
	    -balloonhelp "Reload sectors from session"
    }

    itk_component add add_matrix_tb {
	Toolbutton $itk_component(toolbar).amtb \
	    -type "amodal" \
	    -image ::img::add_matrix16x16 \
	    -command [code $this addMatrix] \
	    -balloonhelp "Add matrix"
    }

    itk_component add spacegroupslabel {
	label $itk_component(toolbar).spacegroupslabel \
	    -text "Spacegroup:"
    }

    itk_component add spacegroupcombo {
	combobox::combobox $itk_component(toolbar).spacegroupcombo \
	    -width 8 \
	    -editable 1 \
	    -highlightcolor black \
	    -command [code $this toggleSpacegroup]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }

    itk_component add max_res_e {
	SettingEntry $itk_component(toolbar).maxre high_resolution_limit \
	    -image ::img::max_res16x16 \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -justify right \
	    -balloonhelp "High resolution limit"
    }
    
    itk_component add min_res_e {
	SettingEntry $itk_component(toolbar).minre low_resolution_limit \
	    -image ::img::min_res16x16 \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -justify right \
	    -balloonhelp "Low resolution limit"
    }

    itk_component add mosaicity_e {
	SettingEntry $itk_component(toolbar).me mosaicity \
	    -image ::img::mosaicity \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -minimum 0 \
	    -maximum 10 \
	    -justify right \
	    -textbackground white \
		-balloonhelp "Mosaicity estimate"
    }

    itk_component add peak_sep_x_e {
        SettingEntry $itk_component(toolbar).psxe spot_separation_x \
	    -image ::img::spot_sep_x16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 5 \
	    -justify right \
	    -balloonhelp "Min spot separation in x" \
	    -linkcommand [code $this linkPeakSep x y]
    }

    itk_component add peak_sep_y_e {
        SettingEntry $itk_component(toolbar).psye spot_separation_y \
	    -image ::img::spot_sep_y16x16 \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right \
	    -balloonhelp "Min spot separation in y" \
	    -linkcommand [code $this linkPeakSep y x]
    }

    itk_component add save_strat {
	Toolbutton $itk_component(toolbar).save \
	    -balloonhelp "Save to file" \
	    -command [code $this SaveToFile]
    }
    $itk_component(save_strat) component button configure -text "Save"

    itk_component add load_strat {
	Toolbutton $itk_component(toolbar).load \
	    -balloonhelp "Load from file" \
	    -command [code $this LoadFromFile 1 ]
    }
    $itk_component(load_strat) component button configure -text "Load"

    itk_component add add_sect {
	Toolbutton $itk_component(toolbar).addsect \
	    -balloonhelp "Add sector(s) from file" \
	    -command [code $this LoadFromFile 0 ]
    }
    $itk_component(add_sect) component button configure -text "Add"

    # Heading

    itk_component add heading_f {
	frame $itk_interior.hf \
	    -bd 1 \
	    -relief solid
    }

    itk_component add heading_l {
	label $itk_interior.hf.fl \
	    -text "Strategy" \
	    -font title_font
    } {
	usual
	ignore -font
    }

    itk_component add auto_complete_b {
	button $itk_interior.acb \
	    -text "Auto-complete" \
	    -command [code $this autoComplete]
    }

    itk_component add testgen_b {
	button $itk_interior.tstgb \
	    -text "Check for overlaps" \
	    -command [code $this setupTestgen]
    }


    itk_component add completeness_pie {
	canvas $itk_interior.pie \
	    -borderwidth 0 \
	    -relief flat \
	    -width 200 \
	    -height 100 \
	    -highlightthickness 0
    } {
	#rename -background -textbackground textBackground Background
    }

    itk_component add chart_frame {
	frame $itk_interior.cf \
	    -bd 0
    }

    itk_component add menu_frame {
	frame $itk_interior.cf.mf \
	    -bd 0
    }

    itk_component add sector_menu {
	canvas $itk_interior.cf.mf.sector_menu \
	    -width 100 \
	    -relief sunken \
	    -bd 2 \
	    -yscrollincrement 19
    } {	
	rename -background -textbackground textBackground Background
    }
    
    itk_component add sector_menu_scroll {
	scrollbar $itk_interior.cf.mf.sms \
	    -orient vertical \
	    -command [list $itk_component(sector_menu) yview]
    }

    $itk_component(sector_menu) configure \
	-yscrollcommand [list autoscroll $itk_component(sector_menu_scroll)]

	
    bind $itk_component(sector_menu) <4> [list $itk_component(sector_menu) yview scroll -1 units]
    bind $itk_component(sector_menu) <5> [list $itk_component(sector_menu) yview scroll 1 units]

    itk_component add chart {
	canvas $itk_interior.cf.chart \
	    -width 300 \
	    -height 250 \
	    -relief sunken \
	    -bd 2 \
	    -takefocus 1 \
	    -highlightthickness 0
    } {	
	rename -background -textbackground textBackground Background
    }

    bind $itk_component(chart) <Configure> [code $this resizeChart]

    bind $itk_component(chart) <Control-Motion> [code $this placeGuide %x %y 5]
    bind $itk_component(chart) <Control-Shift-Motion> [code $this placeGuide %x %y 1]
    bind $itk_component(chart) <Leave> [code $this toggleAddSector 0]
    bind $itk_component(chart) <Control-ButtonPress-1> [code $this placeSector %x %y 5]
    bind $itk_component(chart) <Control-Shift-ButtonPress-1> [code $this placeSector %x %y 1]
    bind $itk_component(chart) <1> [list focus $itk_component(chart)]
    bind $itk_component(chart) <FocusIn> [code $this focusChart]
    bind $itk_component(chart) <FocusOut> [code $this unfocusChart]
    bind $itk_interior <KeyPress-Control_L> [code $this toggleAddSector 1]
    bind $itk_interior <KeyPress-Control_R> [code $this toggleAddSector 1]
    bind $itk_interior <KeyRelease-Control_L> [code $this toggleAddSector 0]
    bind $itk_interior <KeyRelease-Control_R> [code $this toggleAddSector 0]

    itk_component add sector_frame {
	frame $itk_interior.sf
    }

    # Sector list (tree)
	itk_component add sector_tree {
	treectrl $itk_interior.sf.st \
	    -showroot 0 \
	    -showlines 0 \
	    -showbuttons 0 \
	    -selectmode single \
	    -width 430 \
	    -height 90 \
	    -itemheight 18 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(sector_tree) column create -text "Matrix" -justify left -minwidth 150 -expand 1 -tag matrix
    $itk_component(sector_tree) column create -text "\u03c6 start" -justify center -minwidth 50 -expand 1 -tag phi_start
    $itk_component(sector_tree) column create -text "\u03c6 end" -justify center -minwidth 50 -expand 1 -tag phi_end
    # added column for phi extent
    $itk_component(sector_tree) column create -text "\u03c6 extent" -justify center -minwidth 50 -expand 1 -tag phi_extent
    $itk_component(sector_tree) column create -text "Use" -justify center -minwidth 30 -tag use

    $itk_component(sector_tree) state define CHECKED

    $itk_component(sector_tree) element create e_icon image -image ::img::plain_image
    $itk_component(sector_tree) element create e_text text -fill {white selected}
    $itk_component(sector_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(sector_tree) element create e_check image -image { ::img::embed_check_on {CHECKED} ::img::embed_check_off {!CHECKED} }
	
    $itk_component(sector_tree) style create s1
    $itk_component(sector_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(sector_tree) style layout s1 e_icon -expand ns -padx {6 6} -pady {1 1}
    $itk_component(sector_tree) style layout s1 e_text -expand ns
    $itk_component(sector_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(sector_tree) style create s2
    $itk_component(sector_tree) style elements s2 {e_highlight e_text}
    $itk_component(sector_tree) style layout s2 e_text -expand ns
    $itk_component(sector_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(sector_tree) style create s3
    $itk_component(sector_tree) style elements s3 {e_highlight e_check}
    $itk_component(sector_tree) style layout s3 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(sector_tree) style layout s3 e_check -expand ns -padx {2 2}

    bind $itk_component(sector_tree) <ButtonPress-1> [code $this sectorTreeClick %W %x %y]
    #bind $itk_component(sector_tree) <Double-ButtonPress-1> [code $this sectorTreeDoubleClick %W %x %y]
    bind $itk_component(sector_tree) <ButtonRelease-1> { break }
    $itk_component(sector_tree) notify bind $itk_component(sector_tree) <Selection> [code $this toggleSectorSelection %S %D]

    bind $itk_component(sector_tree) <KeyPress> [code $this sectorTreeKey %K]
    bind $itk_component(chart) <KeyPress> [code $this sectorTreeKey %K]

    # Not sure we need to specify the order of bindtags any more for sector_tree
    #bindtags $itk_component(sector_tree) [list $itk_component(sector_tree) TreeCtrlFileList TreeCtrl [winfo toplevel $itk_component(sector_tree)] all]

    itk_component add contextmenu {
	menu $itk_component(sector_tree).context -tearoff 0
    }
    
    $itk_component(contextmenu) add command -label "Delete" -command [code $this rightClickSector]
    $itk_component(contextmenu) add command -label "Save.." -command [code $this saveClickSector]

    bind $itk_component(sector_tree) <3> [code tk_popup $itk_component(contextmenu) %X %Y]

    # Sector list scrollbar
    itk_component add sector_scroll {
	scrollbar $itk_interior.sf.ss \
	    -command [code $this component sector_tree yview] \
	    -orient vertical
    }
    
    $itk_component(sector_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(sector_scroll)]

    itk_component add alignment_frame {
	frame $itk_interior.af
    }

    itk_component add alignment_tree {
	treectrl $itk_interior.af.at \
	    -showroot 0 \
	    -showrootlines 0 \
	    -showbuttons 1 \
	    -selectmode extended \
	    -width 484 \
	    -height 90 \
	    -itemheight 18 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    # Alignment list scrollbar
    itk_component add alignment_scroll {
	scrollbar $itk_interior.af.as \
	    -command [code $this component alignment_tree yview] \
	    -orient vertical
    }
    
    $itk_component(alignment_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(alignment_scroll)]

    $itk_component(alignment_tree) column create -text "Axis" -justify left -minwidth 40 -expand 1 ;
    $itk_component(alignment_tree) column create -text "x" -justify left -minwidth 30 -expand 1 ;
    $itk_component(alignment_tree) column create -text "y" -justify left -minwidth 30 -expand 1 ;
    $itk_component(alignment_tree) column create -text "z" -justify left -minwidth 30 -expand 1 ;
    $itk_component(alignment_tree) column create -text "Closest to rotation axis" -justify left -minwidth 200 -expand 1 ;
    $itk_component(alignment_tree) column create -text "Unique axis" -justify left -minwidth 150 -expand 1 ;
    $itk_component(alignment_tree) element create e_text text -fill {white selected}
    $itk_component(alignment_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(alignment_tree) element create e_icon image -image {}
	
    $itk_component(alignment_tree) style create s1
    $itk_component(alignment_tree) style elements s1 { e_highlight e_text }
    $itk_component(alignment_tree) style layout s1 e_text -expand ns
    $itk_component(alignment_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2

    $itk_component(alignment_tree) style create s2
    $itk_component(alignment_tree) style elements s2 { e_highlight e_icon e_text }
    $itk_component(alignment_tree) style layout s2 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(alignment_tree) style layout s2 e_text -expand ns
    $itk_component(alignment_tree) style layout s2 e_highlight -union [list e_text e_icon] -iexpand nse -ipadx 2

    foreach i_axis { a b c } {
	# Create 'By segment' breakdown item 
	set l_item [$itk_component(alignment_tree) item create]
	# set the item's style
	$itk_component(alignment_tree) item style set $l_item 0 s1 1 s1 2 s1 3 s1 4 s2 5 s2
	# update the item's text
	$itk_component(alignment_tree) item text $l_item 0 "$i_axis"
	# add the new item to the tree
	$itk_component(alignment_tree) item lastchild root $l_item
	# Store pointer to sector objects and items by bumber, item or object
	set axes_by_item($l_item) $i_axis
	set items_by_axis($i_axis) $l_item
    }

    itk_component add breakdown {
	canvas $itk_interior.breakdown \
	    -width 300 \
	    -height 250 \
	    -relief sunken \
	    -bd 2 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }

    itk_component add breakdown_combo {
	combobox::combobox $itk_interior.bc \
	    -command [code $this updateBreakdown] \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }
    # Build list of breakdown data for combo
    $itk_component(breakdown_combo) insert end "Predicted completeness (percent) by resolution"
    $itk_component(breakdown_combo) list insert end "Predicted completeness (percent) by resolution"
    $itk_component(breakdown_combo) list insert end "Mean multiplicity by segment"
    $itk_component(breakdown_combo) list insert end "Predicted completeness of Bijvoet pairs by resolution"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness (percent) by segment"
    $itk_component(breakdown_combo) list insert end "Percentage unique data with multiplicity 1 by segment"
    $itk_component(breakdown_combo) list insert end "Percentage unique data with multiplicity 2 by segment"
    $itk_component(breakdown_combo) list insert end "Percentage unique data with multiplicity 3 by segment"
    $itk_component(breakdown_combo) list insert end "Percentage unique data with multiplicity 4 by segment"
    $itk_component(breakdown_combo) list insert end "Percentage unique data with multiplicity 5+ by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 1 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 2 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 3 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 4 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 5 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 6 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 7 by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative completeness in resolution bin 8 by segment"
    $itk_component(breakdown_combo) list insert end "Number of unique reflections by resolution"
    $itk_component(breakdown_combo) list insert end "Number of predicted reflections by resolution"
    $itk_component(breakdown_combo) list insert end "Number of unique Bijvoet pairs by resolution"
    $itk_component(breakdown_combo) list insert end "Number of predicted Bijvoet pairs by resolution"
    $itk_component(breakdown_combo) list insert end "Number of reflections by segment"
    $itk_component(breakdown_combo) list insert end "Cumulative unique reflections by segment"
    $itk_component(breakdown_combo) configure -editable 0
    # Build lookup arrays matching combo entry to data
    foreach i_datum [StrategyResolutionBin::getDataList] {
	set l_name [StrategyResolutionBin::getDataName $i_datum]
	set resolution_breakdown_data_by_name($l_name) $i_datum
    }
    foreach i_datum [StrategySector::getDataList] {
	set l_name [StrategySector::getDataName $i_datum]
	set sector_breakdown_data_by_name($l_name) $i_datum
    }

    set margin 7

    # Toolbar
    pack $itk_component(divider1) \
    	-side left \
	-fill y \
	-padx 2 \
	-pady 2

    pack $itk_component(sync_session_tb) $itk_component(add_matrix_tb) $itk_component(spacegroupslabel) $itk_component(spacegroupcombo) \
	$itk_component(max_res_e) $itk_component(min_res_e) $itk_component(mosaicity_e) $itk_component(peak_sep_x_e) \
	$itk_component(peak_sep_y_e) $itk_component(save_strat) $itk_component(load_strat) $itk_component(add_sect) \
 	-side left -padx 2

    # Overall grid
    grid x $itk_component(heading_f) - - - - x -sticky nswe -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5 -fill both -expand 1
    grid $itk_component(auto_complete_b) -row 1 -column 4 -columnspan 2 -pady $margin -sticky nswe
    grid $itk_component(testgen_b) -row 3 -column 4 -columnspan 2 -pady $margin -sticky nwe
    grid $itk_component(sector_frame) -row 1 -column 1 -rowspan 4 -columnspan 3 -pady $margin -sticky nswe
    grid $itk_component(completeness_pie) -row 2 -column 4 -pady [list 0 $margin] -sticky nswe
    grid x $itk_component(alignment_frame) - - - - x -pady [list 0 $margin] -sticky nswe
    grid x $itk_component(chart_frame) x $itk_component(breakdown_combo) - - x -sticky nsew
    grid x ^ x $itk_component(breakdown) - - x -sticky nswe
    grid columnconfigure $itk_interior { 0 4 6 } -minsize $margin
    grid columnconfigure $itk_interior { 1 3 } -weight 1
    grid rowconfigure $itk_interior { 6 } -minsize $margin
    grid rowconfigure $itk_interior { 2 5 } -weight 1

    # Sector frame
    grid $itk_component(sector_tree) $itk_component(sector_scroll) -sticky nsew
    grid columnconfigure $itk_component(sector_frame) 0 -weight 1
    grid rowconfigure $itk_component(sector_frame) 0 -weight 1

    # Alignment frame
    grid $itk_component(alignment_tree) $itk_component(alignment_scroll) -sticky nsew
    grid columnconfigure $itk_component(alignment_frame) 0 -weight 1
    grid rowconfigure $itk_component(alignment_frame) 0 -weight 1

    # Chart frame
    pack $itk_component(menu_frame) -side left -fill y
    pack $itk_component(chart) -side right -fill both -expand 1

    # Menu frame
    grid $itk_component(sector_menu) $itk_component(sector_menu_scroll) -sticky nsew
    grid rowconfigure $itk_component(menu_frame) 0 -weight 1

    #puts "[list $itk_component(sector_tree) TreeCtrlFileList TreeCtrl [winfo toplevel $itk_component(sector_tree)] all]"

    eval itk_initialize $args
}

body StrategyWidget::forceTestgen {} {
	$::mosflm sendCommand "testgen start 0 end 84"	
	$::mosflm sendCommand "go"
#	puts "just performed testgen"
}

body StrategyWidget::processTestgenResponse { a_dom } {

    set testgen_result [namespace current]::[TestgenResult \#auto] 
    set local_testgen_type [$testgen_result parseTestgenDom $a_dom]

    if {[$itk_component(breakdown_combo) list size] == 24} {
	$itk_component(breakdown_combo) list delete 23	
    }
    
    if {[$itk_component(breakdown_combo) list size] < 24} {
	if {$local_testgen_type == "variable"} {
	    $itk_component(breakdown_combo) list insert end "Max Oscillation by Phi Segment for 0% overlaps"
	    updateBreakdown itk_component(breakdown_combo) "Max Oscillation by Phi Segment for 0% overlaps"
	} else {
	    $itk_component(breakdown_combo) list insert end "Percentage of overlaps every 5 degrees"			
	    updateBreakdown itk_component(breakdown_combo) "Percentage of overlaps every 5 degrees"
	}
    }

    ::combobox::Select $itk_component(breakdown_combo) 23
}

body StrategyWidget::launch { } {

    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # create sectors afresh from session
    syncSession

    # show spacegroups for session lattice in combo
    set l_lattice [$::session getLattice]
    #puts "SW lattice $l_lattice"
    set l_space_group [[$::session getSpacegroup] reportSpacegroup]
    #puts "SW spacegroup $l_space_group"

    updateSpacegroupCombo $l_lattice $l_space_group
    
    # show toolbar
    pack $itk_component(toolbar) -in [.c component toolbar_frame] -side left

    if {[.c existsTempStrFilename]} {
	# Read from temporary file if present and not empty
	LoadFromFile 0 [.c getTempStrFilename]
	#calculate -calculating here gives the 'double' breakdown plot
    }

}

body StrategyWidget::updateSpacegroupCombo { lattice space_group } {
    $itk_component(spacegroupcombo) list delete 0 end
    if { $lattice != "" } {
        eval $itk_component(spacegroupcombo) list insert 0 $::spacegroup($lattice)
        if { $space_group != "Unknown" } {
	    # select the same one chosen in the indexing pane
	    $itk_component(spacegroupcombo) select [lsearch -exact $::spacegroup($lattice) $space_group]
	}
    }
}

body StrategyWidget::hide { } {
    # Hide dialog
    grid forget $itk_component(hull)

    # Hide toolbar
    pack forget $itk_component(toolbar)
}

body StrategyWidget::clear { } {
    # Undo <configure> bindings
    bind $itk_component(breakdown) <Configure> {}
    bind $itk_component(completeness_pie) <Configure> {}
}

body StrategyWidget::deleteSectorSets { } {
    foreach i_sector_set $sector_sets {
	delete object $i_sector_set
    }
    set sector_sets {}
}

body StrategyWidget::syncSession { } {
    # delete existing sector sets
    deleteSectorSets
    
    # Loop through session's sectors
    foreach i_sector [$::session getSectors] {
	if {[[$i_sector getMatrix] isValid]} {
	    makeProtoSector $i_sector
	}
    }

    # Clear pie canvas in case of previous results
    $itk_component(completeness_pie) delete all

    refreshChart
    
    # if mosflm is not busy,calculate completeness for existing data
    if {![$::mosflm busy]} {
	calculate
    }
}    

body StrategyWidget::LoadFromFile { {refresh 1} {a_file ""} } {
    # Load the sectors from a file (temporary or saved)
    if { $a_file == "" } {
        set a_file [getStrategyFilename open]
    } else {
	#puts "Reading [.c getTempStrFilename]"
    }
    if { ($a_file != "") } {
	if { [file exists $a_file] && ([expr int([file size $a_file])] > 0) } {
	    # open the file and read the entire content
	    set in_file [::open $a_file r]
	    set content [::read $in_file]
	    ::close $in_file
	    # parse the xml into a DOM tree
	    if {[catch {set dom [dom parse $content]} result]} {
		puts "Error creating dom tree: $result"
		puts "Bad xml: $content"
		.m confirm \
		    -type "1button" \
		    -title "Error" \
		    -text "Could not parse file:\n\"$a_file\"" \
		    -button1of1 "Dismiss"
		return 0
	    }
	    
	    # delete existing sector sets if refreshing
	    if { $refresh } {
		deleteSectorSets
	    } else {
		set l_sectors {}
		foreach i_item [$itk_component(sector_tree) item children root] {
		    lappend l_sectors [[$sectors_by_item($i_item) getMatrix] getName]
		}
	    }
    
	    # Get the strategy element
	    set strategy_node [$dom selectNodes strategy]
	
	    # Loop through sectors to create sector_tree
	    foreach i_sector_node [$strategy_node selectNodes sector] {
		set num [$i_sector_node getAttribute number]
		set phi_start [$i_sector_node getAttribute phi_start]
		set phi_extent [$i_sector_node getAttribute phi_extent]
		set phi_end [$i_sector_node getAttribute phi_end]
		set use [$i_sector_node getAttribute use]
		#puts "Loading sector $num $phi_start $phi_extent $phi_end $use"
		set l_matrix_node [$i_sector_node selectNodes matrix]
		set name [$l_matrix_node getAttribute name]
    
		if { $refresh == 0 } {
		    # Check if matrix of the same name already exists if attempting to Add
		    set sect_old [lsearch $l_sectors $name]
		    if { $sect_old >= 0 } {
			set item_no [expr $sect_old + 1]
			if {[info exists sectors_by_item($item_no)]} {
			    deleteSector $sectors_by_item($item_no) 1
			    set l_sectors [lreplace $l_sectors $sect_old $sect_old " "]
			}
		    }
		}
    
		set matrix [namespace current]::[Matrix \#auto "xml" $l_matrix_node]
		if { [$matrix isValid] } {
		    newProtoSector $matrix $phi_start $phi_extent $phi_end
		}
		if { ($refresh == 1) && ($use == 0) } {
		    # Only honour the Use setting if reloading from a list
		    $itk_component(sector_tree) item state set $num !CHECKED
		}
	    }

	    # Update chart but leave current sector displayed?
	    #puts "current_sector_set $current_sector_set should it be passed to refreshChart here?"
	    refreshChart
	    
	    calculate
	}
    }
    # Save temporary strategy file here
    if { [SaveToFile [.c getTempStrFilename]] } {
	.c wroteTempStrFile
    }
}

body StrategyWidget::getStrategyFilename { type } {
    # Recreate Strategy file dialog of correct $type (open or save)
    catch {destroy .fileStrategy}
    Fileopen .fileStrategy  \
	-title "Choose strategy file" \
	-type $type \
	-initialdir [pwd] \
	-filtertypes {{"Strategy files" {.str}} {"All Files" {.*}}}
    # Get the user to pick a new filename and location (as full path)
    return [.fileStrategy get]
}

# Method to determine whether strategy has been saved
#body StrategyWidget::isSaved { } {
#    return $saved
#}

body StrategyWidget::SaveToFile { {a_file ""} } {
    # Save the sectors in the sector_tree to a file
    if { $a_file == "" } {
	set response [getStrategyFilename save]
	if { $response == "" } {
	    return
	} else {
	    set a_file $response
	}
    } else {
	#puts "Writing $a_file"
    }
    if { $a_file != "" } {
	set temp [::open $a_file w]
	::close  $temp
    }

    # Open the file for writing to
    if {[catch {::open $a_file w} result]} {
	.m confirm \
	    -type "1button" -title "Error" -button1of1 "Dismiss" \
	    -text "Could not open file:\n\"$a_file\"\nError message: $result"
	return 0
    } else {
	set outfile $result
    }

    puts $outfile "<?xml version='1.0'?><!DOCTYPE strategy><strategy>"

    foreach i_item [$itk_component(sector_tree) item children root] {
	set i_sector $sectors_by_item($i_item)
	# Write sector information to file
	putSectorInfo $i_sector $i_item $outfile
    }

    puts $outfile "</strategy>"
    
    # Close the file
    if {[catch {::close $outfile} result]} {
	.m confirm \
	    -type "1button" -title "Error" -button1of1 "Dismiss" \
	    -text "Could not close file:\n\"$a_file\"\nError message: $result"
	return 0
    } else {
	return 1
    }
}

body StrategyWidget::putSectorInfo { i_sector i_item a_file } {
    set flag [$itk_component(sector_tree) item state get $i_item CHECKED]
    foreach { start extent } [$i_sector getPhi] break
    set end [expr ($start + $extent) % 360]
    #foreach { phi_start phi_end phi_extent } [roundPhiExt $phi_start $phi_end ] break
    puts $a_file "<sector number=\"$i_item\" phi_start=\"$start\" phi_end=\"$end\" phi_extent=\"$extent\" use=\"$flag\">"
    if {[[$i_sector getMatrix] isValid]} {
	puts $a_file "[[$i_sector getMatrix] serialize]"
    }
    puts $a_file "</sector>"
}

body StrategyWidget::roundPhiExt { l_start l_end } {

    # Round sector start (down) and end (up) to nearest integers
    set l_start [expr int(floor($l_start))]
    set l_end [expr int(ceil($l_end))]

    # Make any negative values positive and any greater than 360 less
    if { $l_start < 0 } {
	set l_start [expr {$l_start + 360}]
    }
    if { $l_start > 360 } {
	set l_start [expr {$l_start % 360}]
    }
    if { $l_end < 0 } {
	set l_end [expr {$l_end + 360}]
    }
    if { $l_end > 360 } {
	set l_end [expr {$l_end % 360}]
    }

    # Check for equal start & end values - a 360 degree sector
    if {$l_start == $l_end} {
	set l_start [expr int($l_start)]
	set l_end $l_start
	set l_extent 0
    } else {
        # Round phi_start & phi_end to nearest integers and return with the calculated phi_extent
	if {$l_start < $l_end} {
	    set l_extent [expr $l_end - $l_start]
	} elseif {$l_start > $l_end} {
	    set l_extent [expr $l_start - $l_end]
	} else {
	    set l_extent 0
	}
    }
    return [list $l_start $l_end $l_extent]
}

body StrategyWidget::makeProtoSector { a_sector } {
    set l_images [$a_sector getImages]
    foreach {l_start junk} [[lindex $l_images 0] getPhi] break
    foreach {junk l_end} [[lindex $l_images end] getPhi] break
    #puts "makeProtoSector:- start $l_start end $l_end"
    foreach { l_start l_end l_extent } [roundPhiExt $l_start $l_end] break
    if { [llength $l_images] > 2 } {
        # not just two sighting images - need to check for a contiguous range of images really!
        #puts "from roundPhiExt:- start $l_start end $l_end extent $l_extent"
        return [newProtoSector [$a_sector getMatrix] $l_start $l_extent $l_end]
    } else {
        return [newProtoSector [$a_sector getMatrix] 0 0 0]
    }
}

body StrategyWidget::newProtoSector { a_matrix a_start a_extent {a_end 0} } {
    # create protosector
    set l_proto_sector [namespace current]::[ProtoSector \#auto $a_start $a_extent $a_end]
    # set protosector matrix
    $l_proto_sector copyMatrix $a_matrix
    # Add sector to appropriate set and tree
    addProtoSector $l_proto_sector
    return $l_proto_sector    
}

body StrategyWidget::addProtoSector { a_sector } {
    # Find which SectorSet to put it in
    set l_sector_set [findSectorSet $a_sector]
    # Create a new one if there was none with matching matrix
    if {$l_sector_set == ""} {
	set l_sector_set [namespace current]::[SectorSet \#auto [$a_sector getMatrix]]
	lappend sector_sets $l_sector_set
    }

    # Add a check that an identical sector does not exist before addition (e.g. from session then reading strategy file)
    
    # Add the sector to the set
    $l_sector_set addSector $a_sector
    # and to the tree
    addSectorToTree $a_sector
}

body StrategyWidget::findSectorSet { a_sector } {
    set l_sector_matrix [$a_sector getMatrix]
    set l_sector_set ""
    foreach i_sector_set $sector_sets {
	set l_set_matrix [$i_sector_set getMatrix]
	if {[$l_sector_matrix equals $l_set_matrix]} {
	    set l_sector_set $i_sector_set
	    break
	}
    }
    return $l_sector_set
}

body StrategyWidget::addSectorToTree { a_sector } {
    # create a new item
    set l_item [$itk_component(sector_tree) item create]
    # set the item's style
    $itk_component(sector_tree) item style set $l_item 0 s1 1 s2 2 s2 3 s2 4 s3
    # update the item's icon
    $itk_component(sector_tree) item element configure $l_item 0 e_icon -image ::img::matrix
    # update the item's text
    foreach { l_start l_extent l_end } [$a_sector getPhi] break
    if { $l_start < 0 } {
	set l_start [expr {$l_start + 360}]
    }
    set l_start [expr {$l_start % 360}]
    if { $l_end < 0 } {
	set l_end [expr {$l_end + 360}]
    }
    set l_end [expr {$l_end % 360}]
    $itk_component(sector_tree) item text $l_item 0 [[$a_sector getMatrix] getName] 1 $l_start 2 $l_end 3 $l_extent
    # add the new item to the tree
    $itk_component(sector_tree) item lastchild root $l_item
    # make the item checked except if a new matrix in which start, end & extent are set to zero
    if { $l_extent == 0 } {
	# do not check as it screws any subsequent Auto-complete
    } else {
	$itk_component(sector_tree) item state set $l_item CHECKED
    }
    # Store pointer to sector objects and items by number, item or object
    set sectors_by_item($l_item) $a_sector
    set items_by_sector($a_sector) $l_item

}

body StrategyWidget::toggleSectorInclusion { an_item } {
    if {[$itk_component(sector_tree) item state get $an_item CHECKED]} {
	uncheckSectorInclusion $an_item
    } else {
	checkSectorInclusion $an_item
    }
}

body StrategyWidget::checkSectorInclusion { an_item } {
    # if the item is checked don't bother!
    if {[$itk_component(sector_tree) item state get $an_item CHECKED]} {
	return
    }
    # make the item checked
    $itk_component(sector_tree) item state set $an_item CHECKED
    # get the item's label
    set l_label [$itk_component(sector_tree) item text $an_item 0]
}

body StrategyWidget::uncheckSectorInclusion { an_item } {
    # if the item is not checked don't bother!
    if {![$itk_component(sector_tree) item state get $an_item CHECKED]} {
	return
    }
    # get the item's label
    set l_label [$itk_component(sector_tree) item text $an_item 0]
    # make the item uncheked...
    $itk_component(sector_tree) item state set $an_item !CHECKED
}
body StrategyWidget::setupTestgen { } {
    foreach i_item [$itk_component(sector_tree) item children root] {
	lappend l_sectors $sectors_by_item($i_item)
    }

    if {[llength $l_sectors] > 0} {
	# Work out how many parts
	set l_parts [llength $l_sectors]
	#puts $l_parts
    }

    foreach i_sector $l_sectors {
	set phi_limits [$i_sector getPhiLimits]
	#puts $phi_limits
	foreach { i_phi_start i_phi_end } [$i_sector getPhiLimits] {
	    set i_phi_end [expr $i_phi_end % 360]
	    #if {$i_phi_start > $i_phi_end} {
	    #	set i_phi_start "-[expr 360 % $i_phi_start]"
	    #}
	    lappend sectors_phi "$i_phi_start-$i_phi_end"
	    #puts $l_phi_start 
	    #puts $l_phi_end
	}
    }

    if {![winfo exists .testgen]} {
	TestgenCalcDialog .testgen	
    }
    .testgen confirm $sectors_phi

}

body StrategyWidget::autoComplete { } {
    if {![winfo exists .scd]} {
	StrategyCalcDialog .scd
    }
    set l_matrix ""

    foreach { l_matrix l_rotation l_segments l_include_existing_sectors l_anomalous } [.scd confirm] break
    if {$l_matrix != ""} {
	calculate $l_matrix $l_rotation $l_segments $l_include_existing_sectors $l_anomalous
    }
}

body StrategyWidget::calculate { { a_matrix "" } { a_rotation "" } { a_segments "" } { a_include_existing_sectors "1" } { a_anomalous 0 } } {
    #$itk_component(calculate) configure -state disabled

    if {$a_matrix != ""} {
	set l_mode "complete"
	set matrix $a_matrix
	#puts "SW::calculate complete mode"
    } else {
	set l_mode "measure"
	set matrix [$current_sector_set getMatrix] 
	#puts "SW::calculate measure mode"
    }

    set l_sectors {}
    # Inclusion of existing sectors now determined by checkbox added to sector_tree
    # Loop through sector tree items
    foreach i_item [$itk_component(sector_tree) item children root] {
	foreach { l_start l_extent } [$sectors_by_item($i_item) getPhi] break
	#puts "Item $i_item phi_start $l_start phi_end $l_extent"
	if {[$itk_component(sector_tree) item state get $i_item CHECKED]} {
	    # use it - for the calculation but skip if a new matrix line with an extent of zero which will crash Mosflm
	    if { $l_extent != 0 } {
		lappend l_sectors $sectors_by_item($i_item)
	    } else {
		toggleSectorInclusion $i_item
	    }
	    #puts "Include item $i_item sector [[[findSectorSet $sectors_by_item($i_item)] getMatrix] getName]"
	} else {
	    # lose it - lest we end up with one line for a matrix and one for a sector
	    #puts " Delete item $i_item sector [[[findSectorSet $sectors_by_item($i_item)] getMatrix] getName]"
	    deleteSector $sectors_by_item($i_item)
	}
    }

    # Create results object
    if {$results != ""} {
	delete object $results
    }
    set results [namespace current]::[StrategyResult \#auto]

    # Get the spacegroup from the editable combo
    set a_space_group [$itk_component(spacegroupcombo) get]

    if {$l_mode == "measure"} {
	set anomalous 0
	if {[llength $l_sectors] > 0} {
	    disable
	    $::mosflm calcStrategy "measure" $l_sectors "" "" "" $anomalous $a_space_group
	}
    } else {
	set anomalous $a_anomalous
	disable
	$::mosflm calcStrategy "complete" $l_sectors $a_matrix $a_rotation $a_segments $anomalous $a_space_group
    }

}

body StrategyWidget::getMatrices { } {
    set l_matrices {}
    foreach i_sector_set $sector_sets {
	lappend l_matrices [$i_sector_set getMatrix]
    }
    return $l_matrices
}

body StrategyWidget::getCurrentMatrix { } {
    return [$current_sector_set getMatrix]
}

body StrategyWidget::hack { } {
    $itk_component(chart) configure -state normal
}

# disabling / enabling

body StrategyWidget::disable { } {
    toggleAbility "disabled"
}

body StrategyWidget::enable { } {
    toggleAbility "normal"
}

body StrategyWidget::toggleAbility { a_state } {
    $itk_component(sync_session_tb) configure -state $a_state
    $itk_component(auto_complete_b) configure -state $a_state
    $itk_component(chart) configure -state $a_state
    $itk_component(testgen_b) configure -state $a_state
}

body StrategyWidget::toggleAddSector { on } {
    if {$on} {
	foreach {l_root_x l_root_y} [winfo pointerxy $itk_component(chart)] break
	set l_mouse_window [winfo containing $l_root_x $l_root_y]
	if {[string compare $l_mouse_window $itk_component(chart)] == 0} {
	    Cursor add_sector $itk_component(chart)
	    set l_chart_x [expr $l_root_x - [winfo rootx $itk_component(chart)]]
	    set l_chart_y [expr $l_root_y - [winfo rooty $itk_component(chart)]]
	    placeGuide $l_chart_x $l_chart_y 5
	}
    } else {
	hideGuide
	Cursor left_ptr $itk_component(chart)
    }
}

body StrategyWidget::addMatrix { args } {
    if {![winfo exists .newMatrix]} {
	MatrixDialog .newMatrix -title "New Matrix..."
    }
    # Clear the dialog
    .newMatrix clear
    # Get a matrix from the user
    set l_new_matrix [.newMatrix get]
    if {$l_new_matrix != ""} {
	#puts "Checking [$l_new_matrix getName]"
	#puts [$l_new_matrix listMatrix]
	foreach i_sector [$::session getSectors] {
	    set l_old_matrix [$i_sector getMatrix]
	    #puts "against [$l_old_matrix getName]"
	    if {[$l_old_matrix equals $l_new_matrix]} {
		#puts [$l_old_matrix listMatrix]
		#puts "Matrix found in $i_sector"
		.m confirm \
		    -type "1button" -title "Warning" -button1of1 "Dismiss" \
		    -text "Matrix [$l_old_matrix getName] is identical to that being read now"
		delete object $l_new_matrix
		return
	    }
	}
	# Add to sector_tree which should add to sector set
	set l_new_sector [newProtoSector $l_new_matrix 0 0 0]
	#set l_sector_set [namespace current]::[SectorSet \#auto $l_new_matrix]
	#lappend sector_sets $l_sector_set
	delete object $l_new_matrix
	refreshChart
    }
}

# Guidelines methods #######################################

body StrategyWidget::plotCircle { } {

    $itk_component(chart) create oval \
	$circle_x1 $circle_y1 $circle_x2 $circle_y2 \
	-tags [list type(frame) circle]

}

body StrategyWidget::placeGuide { a_x a_y a_step} {
    foreach { l_x l_y l_deg } [getPerimeterPoint $a_x $a_y $a_step] break
    $itk_component(chart) delete type(guide)
    $itk_component(chart) create line \
	$circle_x0 $circle_y0 $l_x $l_y \
	-tags [list type(guide) guideline]
    $itk_component(chart) create text $l_x $l_y \
	-text " $l_deg " \
	-anchor [angle2perimeterAnchor $l_deg] \
	-tags [list type(guide) guidelabel]
}

body StrategyWidget::hideGuide { } {
    $itk_component(chart) delete type(guide)
}

# SectorSet display methods ################################

body StrategyWidget::resizeChart { } {
    # Calculate circle position
    set l_width [winfo width $itk_component(chart)]
    set l_height [winfo height $itk_component(chart)]
    if {$l_width <= 1} {
	set l_width [winfo reqwidth $itk_component(chart)]
    }
    if {$l_height <= 1} {
	set l_height [winfo reqheight $itk_component(chart)]
    }
    set l_max_height [expr $l_height - 80]
    set l_max_width [expr $l_width - 40]
    set l_min_dim [expr $l_max_width <= $l_max_height ? $l_max_width : $l_max_height]
    set circle_r [expr $l_min_dim / 2]
    set circle_x0 [expr $l_width / 2]
    set circle_y0 [expr ($l_height / 2) - 20 ]
    set circle_x1 [expr $circle_x0 - $circle_r]
    set circle_y1 [expr $circle_y0 - $circle_r]
    set circle_x2 [expr $circle_x0 + $circle_r]
    set circle_y2 [expr $circle_y0 + $circle_r]
    
    # refresh the chart plot
    #puts "resizeChart calling refreshChart"
    refreshChart $current_sector_set
}

body StrategyWidget::refreshChart { {a_sector_set ""}} {
    # see if menu is required
    set num_sectsets [llength $sector_sets]
    if { $a_sector_set == "" } {
	set current_sector_set [lindex $sector_sets [ expr $num_sectsets - 1]]
	#puts "::refreshChart no a_sector_set passed - set current_sector_set to $current_sector_set"
    } else {
	set current_sector_set $a_sector_set
	#puts "::refreshChart current_sector_set to $current_sector_set"
    }
    #puts "refreshChart sector sets: $num_sectsets"
    #puts "current_sector_set: $current_sector_set"
    # Hide the thumbnails by resetting num_sectsets to 1
    #set num_sectsets 1 ;#comment this line to get the thumbnails
    if {$num_sectsets > 1} {
	#puts "List of sector sets: $sector_sets"
	# Show menu
	pack $itk_component(menu_frame) -side left -fill y
	# Autoscroll menu
	eval autoscroll $itk_component(sector_menu_scroll) [$itk_component(sector_menu) yview]
	# Show thumbnails in menu
	displayThumbnails
	# Show the current thumbnail
	displaySectorSet $current_sector_set
    } else {
	# Remove the menu
	pack forget $itk_component(menu_frame)
	if {$num_sectsets == 1} {
	    displaySectorSet $current_sector_set
	} else {
	    $itk_component(chart) delete all
	}
    }
}

body StrategyWidget::displaySectorSet { a_sector_set } {
    # Clear existing display
    $itk_component(chart) delete all

    # Plot the circle
    plotCircle

    # Plot all sectors in set
    foreach i_sector [$a_sector_set getSectors] {
	#puts "displaySectorSet for i_sector $i_sector"
	plotSector $i_sector
    }
    # Plot set label
    $itk_component(chart) create image -2 0 \
	-image ::img::matrix \
	-anchor e \
	-tags matrix_label
    $itk_component(chart) create text 2 0 \
	-text [[$a_sector_set getMatrix] getName] \
	-anchor w \
	-tags matrix_label
    set l_bbox [$itk_component(chart) bbox matrix_label]
    set l_start [lindex $l_bbox 0]
    set l_end [lindex $l_bbox 2]
    set l_width [expr [lindex $l_bbox 2] - $l_start]
    set l_x_shift [expr -($l_start + $l_end) / 2]
    $itk_component(chart) move matrix_label \
	[expr $circle_x0 + $l_x_shift] [expr $circle_y0 + $circle_r + 20]
}

body StrategyWidget::displayThumbnails { } {
    $itk_component(sector_menu) delete all
    # Set position for first thumbnail
    set l_x 60
    set l_y 0
    # Loop through sector sets
    foreach i_sector_set $sector_sets {
	# display thumbnail
	set tn [displayThumbnail $i_sector_set $l_y]
	incr l_y 76
    }
    set l_bbox [$itk_component(sector_menu) bbox label]
    set l_width [expr [lindex $l_bbox 2] + 8]
    $itk_component(sector_menu) configure -width $l_width
    foreach i_sector_set $sector_sets {
	$itk_component(sector_menu) move thumbnail($i_sector_set) [expr $l_width / 2] 0
	foreach {l_x1 l_y1 l_x2 l_y2} [$itk_component(sector_menu) coords overlay($i_sector_set)] break
	$itk_component(sector_menu) coords box($i_sector_set) [list 4 $l_y1 [expr $l_width - 4] $l_y2]
	$itk_component(sector_menu) coords border($i_sector_set) [list 4 $l_y1 [expr $l_width - 4] $l_y2]
	$itk_component(sector_menu) coords overlay($i_sector_set) [list 4 $l_y1 [expr $l_width - 4] $l_y2]
    }

    # Shade current sector
    if {$current_sector_set == ""} {
	set current_sector_set [lindex $sector_sets 0]
    }
    $itk_component(sector_menu) itemconfigure box($current_sector_set) \
	-fill \#dcdcdc \
	-outline \#a9a9a9

    # Update scroll region
    set l_bbox [$itk_component(sector_menu) bbox all]
    set l_limit [expr [llength $sector_sets] * 76]
    set l_margin [expr [$itk_component(sector_menu) cget -bd] + \
		      [$itk_component(sector_menu) cget -highlightthickness]]
    set l_height [expr [winfo height $itk_component(sector_menu)] - \
		      (2 * $l_margin)]
    set l_scrollregion [list 0 0 $l_width [expr $l_limit > $l_height ? $l_limit : $l_height]]
     $itk_component(sector_menu) configure \
 	-scrollregion $l_scrollregion
}

body StrategyWidget::displayThumbnail { a_sector_set a_y } {
    set l_spacing 5
    set r 20
    set l_x1 [expr -$r]
    set l_x2 $r
    set l_y1 [expr $a_y + (2 * $l_spacing)]
    set l_y2 [expr $l_y1 + (2 * $r)]

    # Create boxes
    $itk_component(sector_menu) create rectangle \
	0 [expr $a_y + $l_spacing] 0 [expr $l_y2 + 16 + ($l_spacing * 2)] \
	-fill {} \
	-outline {} \
	-width 3 \
	-tags [list thumbnail($a_sector_set) box($a_sector_set)]
    $itk_component(sector_menu) create rectangle \
	0 [expr $a_y + $l_spacing] 0 [expr $l_y2 + 16 + ($l_spacing * 2)] \
	-fill {} \
	-outline {} \
	-width 3 \
	-tags [list thumbnail($a_sector_set) border($a_sector_set)]

    # plot circle
    $itk_component(sector_menu) create oval $l_x1 $l_y1 $l_x2 $l_y2 \
	-tags [list thumbnail($a_sector_set) circle($a_sector_set)]
    
    # plot sectors
    foreach i_sector [$a_sector_set getSectors] {
	foreach { l_start l_extent } [$i_sector getPhi] break
	# Calculate canvas extent
	set l_extent [expr -$l_extent]
	if {$l_extent == -360} {
	    set l_extent -359.999
	}
	if { $l_extent != 0 } {
	    # do not draw a sector of zero size on thumbnail
	    $itk_component(sector_menu) create arc $l_x1 $l_y1 $l_x2 $l_y2 \
		-start [expr 90 - $l_start] \
		-extent $l_extent \
		-fill "\#bb0000" \
		-tags [list thumbnail($a_sector_set) sector($a_sector_set)]
	}
    }
    
    # add label
    $itk_component(sector_menu) create image 24 [expr $l_y2 + $l_spacing + 8] \
	-image ::img::matrix \
	-anchor e \
	-tags [list label($a_sector_set) icon($a_sector_set)]
    set l_text [[$a_sector_set getMatrix] getName]
    $itk_component(sector_menu) create text 28 [expr $l_y2 + $l_spacing + 8] \
	-text $l_text \
	-anchor w \
	-tags [list label($a_sector_set) text($a_sector_set) label]

    # Create overlay
    $itk_component(sector_menu) create rectangle \
	0 [expr $a_y + $l_spacing] 0 [expr $l_y2 + 16 + ($l_spacing * 2)] \
	-fill {} \
	-outline {} \
	-width 3 \
	-tags [list thumbnail($a_sector_set) overlay($a_sector_set)]
    
    # Set up bindings
    $itk_component(sector_menu) bind overlay($a_sector_set) <Enter> [code $this highlightSectorSet $a_sector_set]
    $itk_component(sector_menu) bind overlay($a_sector_set) <Leave> [code $this unHighlightSectorSet $a_sector_set]
    $itk_component(sector_menu) bind overlay($a_sector_set) <1> [code $this selectSectorSet $a_sector_set]

    return thumbnail($a_sector_set)
}

body StrategyWidget::updateThumbnail { a_sector_set } {
    $itk_component(sector_menu) delete sector($a_sector_set)
    foreach { l_x1 l_y1 l_x2 l_y2 } [$itk_component(sector_menu) coords circle($a_sector_set)] break
    if {[info exists l_x1]} {
	foreach i_sector [$a_sector_set getSectors] {
	    foreach { l_start l_extent } [$i_sector getPhi] break
	    # Calculate extent
	    set l_extent [expr -$l_extent]
	    if {$l_extent == -360} {
		set l_extent -359.999
	    }
	    if { $l_extent != 0 } {
		# do not draw a sector of zero size on thumbnail
		$itk_component(sector_menu) create arc $l_x1 $l_y1 $l_x2 $l_y2 \
		    -start [expr 90 - $l_start] \
		    -extent $l_extent \
		    -fill "\#bb0000" \
		    -tags [list thumbnail($a_sector_set) sector($a_sector_set)]
	    }
	}
    }
}

body StrategyWidget::selectSectorSet { a_sector_set } {
    #puts "Selecting $a_sector_set"
    set current_sector_set $a_sector_set
    refreshChart $a_sector_set
}

body StrategyWidget::highlightSectorSet { a_sector_set } {
    $itk_component(sector_menu) itemconfigure border($a_sector_set) \
	-outline \#3399ff
}

body StrategyWidget::unHighlightSectorSet { a_sector_set } {
    $itk_component(sector_menu) itemconfigure border($a_sector_set) \
	-outline {}
}

# Sector editing methods ###################################

body StrategyWidget::plotSector { a_sector } {
    set a_name $a_sector
    # Get phi range and size
    foreach { l_start l_extent } [$a_sector getPhi] break
    set l_canvas_extent [expr -$l_extent]
    if {$l_canvas_extent == -360} {
	set l_canvas_extent 359.999
    }
    # Pick colour and stipple
    if { [$a_sector getType] == "normal" } {
	set l_colour "\#bb0000"
	set l_stipple ""
    } else {
	set l_colour "\#ffcc00"
	set l_stipple $stipple
    }

    # remove any pre-existing sector with same name
    $itk_component(chart) delete name($a_sector)

    $itk_component(chart) create arc \
	$circle_x1 $circle_y1 $circle_x2 $circle_y2 \
	-start [chartDeg2canvasDeg $l_start] \
	-extent $l_canvas_extent \
	-fill $l_colour \
	-stipple $l_stipple \
	-tags [list type(arc) subtype(proto) name($a_sector) arc($a_sector)]
    # get vertices
    set l_end [expr ($l_start + $l_extent) % 360]
    set l_mid [expr round($l_start + (0.5 * $l_extent)) % 360]
    foreach { l_start_x l_start_y } [angle2perimeterPoint $l_start] break
    foreach { l_end_x l_end_y } [angle2perimeterPoint $l_end] break
    foreach { l_mid_x l_mid_y } [angle2perimeterPoint $l_mid [expr $circle_r * 0.66]] break
    # create toggles
    $itk_component(chart) create image $l_start_x $l_start_y\
	-image {} \
	-tags [list type(toggle) subtype(start) name($a_sector) toggle($a_sector) start_toggle($a_sector)]
    $itk_component(chart) create image $l_end_x $l_end_y\
	-image {} \
	-tags [list type(toggle) subtype(end) name($a_sector) toggle($a_sector) end_toggle($a_sector)]
    # create labels
    $itk_component(chart) create text $l_start_x $l_start_y\
	-text " $l_start " \
	-fill $l_colour \
	-anchor [angle2perimeterAnchor $l_start] \
	-tags [list type(label) subtype(start) name($a_sector) label($a_sector) start_label($a_sector)]
    $itk_component(chart) create text $l_end_x $l_end_y\
	-text " $l_end " \
	-fill $l_colour \
	-anchor [angle2perimeterAnchor $l_end] \
	-tags [list type(label) subtype(end) name($a_sector) label($a_sector) end_label($a_sector)]
    # Raise all mid labels and their boxes
    foreach i_sector [array names items_by_sector] {
	$itk_component(chart) raise label_box($i_sector)
	$itk_component(chart) raise mid_label($i_sector)
    }
    # Add mid label with size and box
    $itk_component(chart) create text $l_mid_x $l_mid_y\
	-text " $l_extent " \
	-anchor c \
	-fill $l_colour \
	-tags [list type(label) subtype(mid) name($a_sector) label($a_sector) mid_label($a_sector)]
    $itk_component(chart) create rectangle [$itk_component(chart) bbox mid_label($a_sector)] \
	-outline $l_colour \
	-fill white \
	-tags [list type(label_box) name($a_sector) label_box($a_sector)]
    $itk_component(chart) raise mid_label($a_sector) label_box($a_sector)

    # Set up selection binding
    $itk_component(chart) bind name($a_sector) <1> [code $this clickSector $a_sector]
	
}

body StrategyWidget::placeSector { a_x a_y a_step} {
    
    # Deselect any previously selected sector
    if {$selected_sector != ""} {
	deselectSector $selected_sector
    }

    hideGuide

    foreach { l_x l_y l_deg } [getPerimeterPoint $a_x $a_y $a_step] break

    # Create new ProtoSector
    set l_new_sector [newProtoSector [$current_sector_set getMatrix] $l_deg 0 0]
    # plot sector
    plotSector $l_new_sector

    # select the sector
    selectSector $l_new_sector

    # free sector for stretching
    freeSector $l_new_sector
}

body StrategyWidget::freeSector { a_name { a_flip "" } } {
    if {$a_flip == "flip"} {
	flipSector $a_name
    }
    # setup bindings for stretching
    bind $itk_component(chart) <Motion> [code $this stretchSector $a_name %x %y 1]
    bind $itk_component(chart) <ButtonRelease-1> [code $this anchorSector $a_name]
    bind $itk_component(chart) <Shift-Motion> [code $this stretchSector $a_name %x %y 1]
    bind $itk_component(chart) <Shift-ButtonRelease-1> [code $this anchorSector $a_name]
    bind $itk_component(chart) <Control-Motion> [code $this stretchSector $a_name %x %y 1]
    bind $itk_component(chart) <Control-ButtonRelease-1> [code $this anchorSector $a_name]
    bind $itk_component(chart) <Control-Shift-Motion> [code $this stretchSector $a_name %x %y 1]
    bind $itk_component(chart) <Control-Shift-ButtonRelease-1> [code $this anchorSector $a_name]
}

body StrategyWidget::guessNewExtent { a_start a_end a_old_extent } {
    set l_extent1 [expr $a_start - $a_end]
    set l_extent2 [expr $l_extent1 + 360]
    set l_extent3 [expr $l_extent1 + 720]
    set l_extent4 [expr $l_extent1 - 360]
    set l_prob1 [expr abs($l_extent1 - $a_old_extent)]
    set l_prob2 [expr abs($l_extent2 - $a_old_extent)]
    set l_prob3 [expr abs($l_extent3 - $a_old_extent)]
    set l_prob4 [expr abs($l_extent4 - $a_old_extent)]
    if {($l_prob1 <= $l_prob4) && ($l_prob1 <= $l_prob3) && ($l_prob1 <= $l_prob2)} {
	set l_new_extent $l_extent1
    } elseif {($l_prob2 <= $l_prob4) && ($l_prob2 <= $l_prob3)} {
	set l_new_extent $l_extent2
    } elseif {($l_prob3 <= $l_prob4)} {
	set l_new_extent $l_extent3
    } else {
	set l_new_extent $l_extent4
    }
    if {$l_new_extent <= -360} {
	set l_new_extent -359.99
    } elseif {$l_new_extent >= 360} {
	set l_new_extent 359.99
    }
    return $l_new_extent
}

body StrategyWidget::stretchSector { a_name a_x a_y a_step } {
    # Get start point
    set l_start_canvas [$itk_component(chart) itemcget arc($a_name) -start]
    set l_start_chart [canvasDeg2chartDeg $l_start_canvas]
    # Get old extent
    set l_old_extent [$itk_component(chart) itemcget arc($a_name) -extent]
    # Calculate new end point
    foreach { l_end_x l_end_y l_end_deg } [getPerimeterPoint $a_x $a_y $a_step] break
    # Calulate extent
    set l_extent [guessNewExtent $l_start_chart $l_end_deg $l_old_extent]
    # update chart
    updateSector $a_name $l_start_chart $l_end_deg $l_extent
}

body StrategyWidget::updateSector { a_name a_start a_end a_extent } {

    # calculate end coordinates
    foreach { l_end_x l_end_y } [eval chart2canvas [polar2cartesian [chartDeg2rad $a_end] $circle_r]] break

    # update arc
    $itk_component(chart) itemconfigure arc($a_name) \
	-extent $a_extent
    if {(round($a_extent) == 360) || (round($a_extent) == -360)} {
	# move toggle to start
	$itk_component(chart) coords end_toggle($a_name) [$itk_component(chart) coords start_toggle($a_name)]
	# move end label to start and update value
	$itk_component(chart) coords end_label($a_name) [$itk_component(chart) coords start_label($a_name)]
	$itk_component(chart) itemconfigure end_label($a_name) \
	    -anchor [angle2perimeterAnchor $a_start] \
	    -text [$itk_component(chart) itemcget start_label($a_name) -text]
    } else {
	# update toggle
	$itk_component(chart) coords end_toggle($a_name) $l_end_x $l_end_y
	$itk_component(chart) itemconfigure end_toggle($a_name) \
	    -image ::img::toggle
	# update end label
	$itk_component(chart) coords end_label($a_name) $l_end_x $l_end_y
	$itk_component(chart) itemconfigure end_label($a_name) \
	    -anchor [angle2perimeterAnchor $a_end] \
	    -text " $a_end "
    }
    # update mid label
    set l_mid_deg [expr round($a_start - (0.5 * $a_extent))]
    foreach { l_mid_x l_mid_y } [angle2perimeterPoint $l_mid_deg [expr $circle_r * 0.66]] break
    $itk_component(chart) coords mid_label($a_name) $l_mid_x $l_mid_y
    $itk_component(chart) itemconfigure mid_label($a_name) \
	-anchor c \
	-text " [expr abs(round($a_extent))] "
    $itk_component(chart) coords label_box($a_name) [$itk_component(chart) bbox mid_label($a_name)]
    # Update tree
    if {$a_extent <= 0} {
	set l_item_start $a_start
	set l_item_extent [expr -int(round($a_extent))]
    } else {
	set l_item_start $a_end
	set l_item_extent [expr int(round($a_extent))]
    }
    set l_item_end [expr ($l_item_start + $l_item_extent) % 360]

    # Make sure the sector item is checked for inclusion the calculation as we may have stretched
    # a zero-sized sector resulting from reading a matrix or two perpendicular 'sighting' images.
    checkSectorInclusion $items_by_sector($a_name)

    $itk_component(sector_tree) item text $items_by_sector($a_name) \
	1 $l_item_start \
	2 $l_item_end \
	3 $l_item_extent
    # update sector
    $a_name setPhi $l_item_start $l_item_extent
    # update thumbnail
    set l_set [findSectorSet $a_name]
    updateThumbnail $l_set
}

body StrategyWidget::anchorSector { a_name } {

    # if sector's extent is now zero, delete it
    if {[$itk_component(chart) itemcget arc($a_name) -extent] == 0} {
	deleteSector $a_name
    } else {
	# if necessary, flip item to extend clockwise
	if {[$itk_component(chart) itemcget arc($a_name) -extent] > 0} {
	    #puts "Need to flip sector to extend clockwise"
	    flipSector $a_name
	} else {
	    #puts "No need to flip sector extent [$itk_component(chart) itemcget arc($a_name) -extent] is clockwise"
	}

	# sort the sector tree
	$itk_component(sector_tree) item sort root \
	    -dictionary \
	    -column 0 \
	    -column 1 \
	    -column 2

	# Find the sector's set
	set l_sector_set [findSectorSet $a_name]

	# Sort the sector set
	$l_sector_set sortSectors

	# consolidate the sectors in that set
	if {![consolidateSectors $l_sector_set]} {
	    # re-select Sector if no consolidation (for tree's benefit)
	    selectSector "$a_name"
	}
    }

    # restore bindings
    bind $itk_component(chart) <Motion> {}
    bind $itk_component(chart) <Control-Motion> [code $this placeGuide %x %y 5]
    bind $itk_component(chart) <ButtonRelease-1> {}
    bind $itk_component(chart) <Control-ButtonRelease-1> {}
    bind $itk_component(chart) <Shift-Motion> {}
    bind $itk_component(chart) <Control-Shift-Motion> [code $this placeGuide $a_name %x %y 1]
    bind $itk_component(chart) <Shift-ButtonRelease-1> {}
    bind $itk_component(chart) <Control-Shift-ButtonRelease-1> {}

    # recalculate strategy
    calculate

    # Save temporary strategy file here
    if { [SaveToFile [.c getTempStrFilename]] } {
	.c wroteTempStrFile
    }

}

body StrategyWidget::selectSector { a_name } {
    if {$selected_sector != ""} {
	deselectSector $selected_sector
    }
    set selected_sector $a_name
    # embolden sector
    $itk_component(chart) itemconfigure arc($a_name) \
	-width 2
    # show toggles
    if {[focus] == $itk_component(chart)} {
	$itk_component(chart) itemconfigure toggle($a_name) \
	    -image ::img::toggle
    } else {
	$itk_component(chart) itemconfigure toggle($a_name) \
	    -image ::img::toggle_unfocused
    }
    # embolden labels
    $itk_component(chart) itemconfigure label($a_name) \
	-font font_b
    # Raise mid-label and box
    $itk_component(chart) raise label_box($a_name)
    $itk_component(chart) raise mid_label($a_name)
    # raise toggles
    $itk_component(chart) raise toggle($a_name)
    # set up toggle bindings
    $itk_component(chart) bind start_toggle($a_name) <1> [code $this freeSector $a_name "flip"]
    $itk_component(chart) bind end_toggle($a_name) <1> [code $this freeSector $a_name]

}

body StrategyWidget::deselectSector { a_name } {
    # unembolden sector
    $itk_component(chart) itemconfigure arc($a_name) \
	-width 1
    # show toggles
    $itk_component(chart) itemconfigure toggle($a_name) \
	-image {}
    # enbolden labels
    $itk_component(chart) itemconfigure label($a_name) \
	-font font_l
    # deselect corresponding tree item
    $itk_component(sector_tree) selection clear $items_by_sector($a_name)
}

body StrategyWidget::focusChart { } {
    if {$selected_sector != ""} {
	$itk_component(chart) itemconfigure toggle($selected_sector) \
	    -image ::img::toggle
    }
}

body StrategyWidget::unfocusChart { } {
    if {$selected_sector != ""} {
	$itk_component(chart) itemconfigure toggle($selected_sector) \
	    -image ::img::toggle_unfocused
    }
}

body StrategyWidget::clickSector { a_name } {
    $itk_component(sector_tree) selection modify [list $items_by_sector($a_name)] all
}

body StrategyWidget::clickChart { a_x a_y } {

    # deselect any selected sector
    if {$selected_sector != ""} {
	set l_old_selection $selected_sector
	deselectSector $selected_sector
	set setlected_sector ""
    } else {
	set l_old_selection ""
    }
    
    # get items clicked on
    set l_items [$itk_component(chart) find overlapping $a_x $a_y $a_x $a_y]
    if {[llength $l_items] == 0} {
	
	foreach  i_item $l_items {
	    # get item type and name
	    regexp {type\(([^\)]+)\)} [$itk_component(chart) gettags $l_item] match l_type
	    regexp {name\(([^\)]+)\)} [$itk_component(chart) gettags $l_item] match l_name
	    if {($l_type == "arc") || ($l_type == "label")} {
		# if clicked on an arc or label toggle
		selectSector $l_name
	    } elseif {$l_type == "toggle"} {
		# if clicked on toggle free for stretchign
		regexp {subtype\([^\)+]\)} [$itk_component(chart) gettags $l_item] match l_subtype
		if {$l_subtype == "start"} {
		    flipSector $l_name
		}
		freeSector $l_name
	    }
	}
    }
}

body StrategyWidget::flipSector { a_name } {
    # flip arc
    set l_start [$itk_component(chart) itemcget arc($a_name) -start]
    #puts "flipSector arc $a_name start $l_start"
    set l_extent [$itk_component(chart) itemcget arc($a_name) -extent]
    $itk_component(chart) itemconfigure arc($a_name) -start [expr $l_start + $l_extent] -extent [expr - $l_extent]
    
    # swap start and end toggles
    $itk_component(chart) itemconfigure end_toggle($a_name) \
	-tags temp_toggle($a_name)
    $itk_component(chart) itemconfigure start_toggle($a_name) \
 	-tags [list type(toggle) subtype(end) name($a_name) toggle($a_name) end_toggle($a_name)]
    $itk_component(chart) itemconfigure temp_toggle($a_name) \
	-tags [list type(toggle) subtype(start) name($a_name) toggle($a_name) start_toggle($a_name)]
    $itk_component(chart) itemconfigure end_label($a_name) \
	-tags temp_label($a_name)
    $itk_component(chart) itemconfigure start_label($a_name) \
 	-tags [list type(label) subtype(end) name($a_name) label($a_name) end_label($a_name)]
    $itk_component(chart) itemconfigure temp_label($a_name) \
 	-tags [list type(label) subtype(start) name($a_name) label($a_name) start_label($a_name)]
}

# Tree item methods

body StrategyWidget::sectorTreeClick { w x y } {
    # callback for single click on sector treectrl as for Controller::singleClickSession
    set ClickParent $w
    set ClickItem [$w identify $x $y]
    set id $ClickItem
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id {}
	# Add specific element interactions here as required
	if {[lindex $id 5] == "e_check"} {
	    toggleSectorInclusion $item
	} else {
	    set psector $sectors_by_item($item)
	    #puts "Selecting $psector found in [findSectorSet $psector] set"
	    #puts "current_sector_set $current_sector_set"
	    if { $current_sector_set != [findSectorSet $psector] } {
		# If we have picked on a new line in the sector_tree
		selectSectorSet [findSectorSet $psector]
		# Send the following to ask Mosflm to update the alignment results section
		if {![$::mosflm busy]} {
		    $::mosflm sendCommand "matrix [$psector listMatrix]"
		    foreach { l_start l_extent } [$psector getPhi] break
		    if { ($l_start == 0) && ($l_extent == 0) } {
			# probably dealing with a matrix so fudge phi_end so as not to crash Mosflm
			set l_end 1
		    } else {
			set l_end [expr ($l_start + $l_extent) % 360]
		    }
		    $::mosflm sendCommand "strategy start $l_start end $l_end"
		    $::mosflm sendCommand "run $item"
		    $::mosflm sendCommand "exit"
		}
	    }
	}
	#puts "ClickParent: $ClickParent ClickItem:$ClickItem"
    }
}

body StrategyWidget::rightClickSector { } {
    # callback for single click on session treectrl
    set id $ClickItem
    #puts "ClickItem $id"
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	sectorTreeKey Delete
    }
}

body StrategyWidget::saveClickSector { } {
    # Save a sector line in the sector_tree to a file
    set a_file [getStrategyFilename save]
    if { $a_file != "" } {
	set temp [::open $a_file w]
	::close  $temp
	
	# Open the file for writing to
	if {[catch {::open $a_file w} result]} {
	    .m confirm \
		-type "1button" -title "Error" -button1of1 "Dismiss" \
		-text "Could not open file:\n\"$a_file\"\nError message: $result"
	} else {
	    set outfile $result
	}
    	puts $outfile "<?xml version='1.0'?><!DOCTYPE strategy><strategy>"

	# callback for right-click on sector_tree treectrl
	set id $ClickItem
	#puts "ClickItem $id"
	if {$id eq ""} {
	} elseif {[lindex $id 0] eq "header"} {
	} else {
	    foreach {what item where arg1 arg2 arg3} $id {}
	    if {$selected_sector != ""} {
		putSectorInfo $selected_sector $item $outfile
	    }
	}

    	puts $outfile "</strategy>"
	# Close the file
	if {[catch {::close $outfile} result]} {
	    .m confirm \
		-type "1button" -title "Error" -button1of1 "Dismiss" \
		-text "Could not close file:\n\"$a_file\"\nError message: $result"
	}
    }
}

body StrategyWidget::sectorTreeKey { a_keysim } {
    if {$a_keysim == "Delete"} {
	if {$selected_sector != ""} {
	    deleteSector $selected_sector
	}
    }
}

body StrategyWidget::toggleSectorSelection { a_selected { a_deselected "" } } {
    #puts "$a_selected $a_deselected"
    if {$a_deselected != ""} { 
	deselectSector $sectors_by_item($a_deselected)
	#puts "deselectSector $sectors_by_item($a_deselected)"
    }
    if {$a_selected != ""} {
	selectSector $sectors_by_item($a_selected)
	#puts "  selectSector $sectors_by_item($a_selected)"
    }
}

body StrategyWidget::toggleSpacegroup { a_widget a_value } {

    set l_prev_lattice [$::session getLattice]
    set l_current_spacegroup [[$::session getSpacegroup] reportSpacegroup]
    # Needs to be editable see bug 269
    #set trim_value [string trim $a_value " "]
    regsub -all " " $a_value "" trim_value
    if { [string length $trim_value] == 0 } { return }
    if { [string index $trim_value 0] != "h" } {
	set trim_value [string toupper $trim_value]
    }
    if { [string index $trim_value 0] == "H" } {
	set trim_value [string tolower $trim_value]
    }
    if {[lsearch $::spacegroups $trim_value] > -1} {
	# Known to iMosflm
	if {$trim_value != $l_current_spacegroup} {
	    # & different
	    if {[[$::session getCell] reportCell] != "Unknown"} {
		# I think cell is Unknown when first space group value is inserted from chosen solution
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value
	    }
	    set l_curr_lattice [$::session getLattice]
	    if { $l_curr_lattice != "" } {
		#puts "Space group $trim_value chosen in lattice $l_curr_lattice"
		# if mosflm is not busy, calculate completeness for existing data in chosen space group
		if {![$::mosflm busy]} {
		    calculate
		}
	    }
        }
    } else {
	# Forbidden
	if { ($l_prev_lattice != "") && ($l_current_spacegroup != "Unknown") } {
	    if {[[$::session getCell] reportCell] != "Unknown"} {
		# I think cell is Unknown when first space group value is inserted from chosen solution
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value
	    }
	}
    }
    #puts "leaving StrategyWidget::toggleSpacegroup a_widget a_value $a_widget $a_value"
}

body StrategyWidget::deleteSector { a_sector { a_delete_from_set 1 } } {
    # Delete on chart
    $itk_component(chart) delete name($a_sector)
    # Delete from tree
    $itk_component(sector_tree) item delete $items_by_sector($a_sector)
    # Delete from set
    if {$a_delete_from_set} {
	set l_set [findSectorSet $a_sector]
	$l_set deleteSector $a_sector
	# update thumbnail
	updateThumbnail $l_set
    }
    # Delete object
    delete object $a_sector
    # unset pointers
    array unset sectors_by_item $items_by_sector($a_sector)
    array unset items_by_sector $a_sector
    # if the deleted sector was the current selection, clear current selection
    if {$selected_sector == $a_sector} {
	set selected_sector ""
    }
}

body StrategyWidget::consolidateSectors { a_sector_set } {
    # Change all sector types to "normal"
    foreach i_sector [$a_sector_set getSectors] {
	$i_sector setType "normal"
    }
    # sending the sector_set to refreshChart keeps adjusted sector displayed
    refreshChart $a_sector_set

    set l_consolidated 0
    # While there are sectors to consolidate, loop
    while {[consolidateSector $a_sector_set]} {
	set l_consolidated 1
    }

    # Deselect any selected sector, if a consolidation was made
    if {$l_consolidated} {
	foreach i_sector [array names items_by_sector] {
	    deselectSector $i_sector
	}
    }

    return $l_consolidated
}

body StrategyWidget::consolidateSector { a_sector_set } {
    # get list of sectors in order
    set l_sector_list [$a_sector_set getSectors]

    foreach i_sector $l_sector_list {
	foreach { l_start l_extent } [$i_sector getPhi] break
	set l_end [expr ($l_start + $l_extent) % 360]
	#puts "Phi: start $l_start extents: $l_extent end: $l_end $i_sector"
    }
    if {[llength $l_sector_list] < 2} {
	return 0
    }

    set l_last [lindex $l_sector_list end]
    foreach { l_last_start l_last_extent } [$l_last getPhi] break
    set l_last_end [expr ($l_last_start + $l_last_extent) % 360]
    # if last wraps-around
    if {$l_last_start >= $l_last_end} {
	# add first to end of list
	lappend l_sector_list [lindex $l_sector_list 0]
    }
    
    # initialize prev to un-overlappable values
    set l_prev "none"
    set l_prev_start -99999
    set l_prev_end -99998
    # loop through sectors
    foreach i_sector $l_sector_list {
	foreach { l_current_start l_current_extent } [$i_sector getPhi] break
	set l_current_end [expr ($l_current_start + $l_current_extent) % 360]
	set l_prev_wraps [expr $l_prev_start >= $l_prev_end]
	set l_current_wraps [expr $l_current_start >= $l_current_end]

	if {!$l_prev_wraps && !$l_current_wraps} {
	    # check to see if current starts before end of previous
	    if {$l_current_start <= $l_prev_end} {
		# see if current extends previous
		if {($l_current_end > $l_prev_end)} {
		    set l_new_extent [expr $l_prev_start - $l_current_end]
		    updateSector $l_prev $l_prev_start $l_current_end $l_new_extent
		}
		# delete current sector
		deleteSector $i_sector
		return 1
	    } else {
		# no overlap
		set l_prev $i_sector
		set l_prev_start $l_current_start
		set l_prev_end $l_current_end
	    }
	} elseif {$l_prev_wraps && !$l_current_wraps} {
	    # if it's a post-0 overlap...
	    if {($l_current_start <= $l_prev_end)} {
		# see if current extends previous
		if {($l_current_end > $l_prev_end)} {
		    set l_new_extent [expr ($l_prev_start - 360) - $l_current_end]
		    updateSector $l_prev $l_prev_start $l_current_end $l_new_extent
		}
		# delete current sector
		deleteSector $i_sector
		return 1
	    } elseif {$l_current_start >= $l_prev_start} {
		# must be pre-0 overlap
		# current cannot extend previous
		deleteSector $i_sector
		return 1
	    } else {
		# no overlap
		set l_prev $i_sector
		set l_prev_start $l_current_start
		set l_prev_end $l_current_end
	    }
	} elseif {!$l_prev_wraps && $l_current_wraps} {
	    if {$l_current_start <= $l_prev_end} {
		# truncate if combined gives > 360
		if {$l_current_end >= $l_prev_start} {
		    set l_current_end $l_prev_start
		    set l_new_extent 359.99
		} else {
		    set l_new_extent [expr ($l_prev_start - 360) - $l_current_end]
		}
		updateSector $l_prev $l_prev_start $l_current_end $l_new_extent
		deleteSector $i_sector
		return 1
	    } else {
		# no overlap
		set l_prev $i_sector
		set l_prev_start $l_current_start
		set l_prev_end $l_current_end
	    }
	} elseif {$l_prev_wraps && $l_current_wraps} {
	    # must overlap
	    if {$l_current_end > $l_prev_end} {
		# truncate if combined gives > 360
		if {$l_current_end >= $l_prev_start} {
		    set l_current_end $l_prev_start
		    set l_new_extent 359.99
		} else {
		    set l_new_extent [expr ($l_prev_start - 360) - $l_current_end]
		}
		updateSector $l_prev $l_prev_start $l_current_end $l_new_extent
	    }
	    deleteSector $i_sector
	    return 1
	}
    }
    return 0
}

# Graphing mehtods #########################################

body StrategyWidget::plotBreakdown { a_segment_data a_resolution_data } {

    if {$results != ""} {
	# Calculate how many graphs are required
	set l_plot_segment_graph 0
	set l_plot_resolution_graph 0
	if {[llength $a_segment_data] != 0} {
	    # Get datasets for graphing
	    foreach { l_segment_bins l_segment_datasets } [$results getSectorBreakdown $a_segment_data] break
	    set l_plot_segment_graph 1
	}
	if {[llength $a_resolution_data] != 0} {
	    # Get datasets for graphing
	    foreach { l_resolution_bins l_resolution_datasets } [$results getResolutionBreakdown $a_resolution_data] break
	    set l_plot_resolution_graph 1
	}

	if {$l_plot_segment_graph && $l_plot_resolution_graph} {
	    Histogram \#auto $itk_component(breakdown) { 10 10 450 140 } "by_segment" $l_segment_bins $l_segment_datasets
	    Histogram \#auto $itk_component(breakdown) { 10 160 450 290 } "by_resolution" $l_resolution_bins $l_resolution_datasets
	} elseif {$l_plot_segment_graph} {
	    $itk_component(breakdown) delete graph(by_resolution)
	    Histogram \#auto $itk_component(breakdown) { 10 10 450 290 } "by_segment" $l_segment_bins $l_segment_datasets
	} elseif {$l_plot_resolution_graph} {
	    $itk_component(breakdown) delete graph(by_segment)
	    Histogram \#auto $itk_component(breakdown) { 10 10 450 290 } "by_resolution" $l_resolution_bins $l_resolution_datasets
	} else {
	    $itk_component(breakdown) delete all
	}
    }
}

body StrategyWidget::updateBreakdown { a_combo a_option } {
#	puts "in the updateBreakdown method"
    $itk_component(breakdown) delete all 
    set l_bins ""
    if {$results != ""} {
	if {[info exists resolution_breakdown_data_by_name($a_option)]} {
	    foreach { l_bins l_datasets } [$results getResolutionBreakdown $resolution_breakdown_data_by_name($a_option)] break
	} elseif {[info exists sector_breakdown_data_by_name($a_option)]} {
	    foreach { l_bins l_datasets } [$results getSectorBreakdown $sector_breakdown_data_by_name($a_option)] break
	}	
	set l_window [list 10 10]
	lappend l_window [expr [winfo width $itk_component(breakdown)] - 10]
	lappend l_window [expr [winfo height $itk_component(breakdown)] - 10]
    }
    if {$l_bins != ""} {
	Histogram \#auto $itk_component(breakdown) $l_window "tag" $l_bins $l_datasets
    }
	
	if {$a_option == "Max Oscillation by Phi Segment for 0% overlaps" || $a_option == "Percentage of overlaps every 5 degrees" } {
		ScatterGraph \#auto $itk_component(breakdown) $l_window testgenid [$testgen_result getXDataset] [$testgen_result getYDataset] 	
	}
    bind $itk_component(breakdown) <Configure> [code $this updateBreakdown junk $a_option]
}

# Coordinate and angle conversion ##########################

body StrategyWidget::cartesian2polar { a_x a_y } {
    
    # Convert cartesian coords to polar
    set l_phi [expr atan2($a_y,$a_x)]
    set l_r [expr sqrt(pow($a_x,2)+pow($a_y,2))]

    return [list $l_phi $l_r]
}

body StrategyWidget::polar2cartesian { a_phi a_r } {
    
    # Convert polar coordinates to cartesian
    set l_x [expr $a_r * cos($a_phi)]
    set l_y [expr $a_r * sin($a_phi)]

    return [list $l_x $l_y]
}

body StrategyWidget::canvas2chart { a_x a_y } {
    # Convert canvas coords to chart coords
    set l_x [expr $a_x - $circle_x0]
    set l_y [expr $circle_y0 - $a_y]
    return [list $l_x $l_y]
}    
    
body StrategyWidget::chart2canvas { a_x a_y } {
    # Convert chart coords to canvas coords
    set l_x [expr $a_x + $circle_x0]
    set l_y [expr $circle_y0 - $a_y]
    return [list $l_x $l_y]
}    
    
body StrategyWidget::rad2canvasDeg { a_phi } {
    return [expr $a_phi * 180.0 / $::pi]
}

body StrategyWidget::rad2chartDeg { a_phi } {
    return [expr round(90 - ($a_phi * 180.0 / $::pi)) % 360]
}

body StrategyWidget::chartDeg2rad { a_deg } {
    set l_canvas_deg [chartDeg2canvasDeg $a_deg]
    if {$l_canvas_deg <= 180} {
	set l_rad [expr $l_canvas_deg * $::pi / 180.0]
    } else {
	set l_rad [expr - (360 - $l_canvas_deg) * $::pi / 180.0]
    } 
    return $l_rad
}

body StrategyWidget::chartDeg2canvasDeg { a_deg } {
    return [expr round(-270 - $a_deg) % 360]
}

body StrategyWidget::canvasDeg2chartDeg { a_deg } {
    return [expr round(90 - $a_deg) % 360]
}

body StrategyWidget::getPerimeterPoint { a_x a_y { a_step 1 } } {
    # Convert canvas coords to chart coords
    foreach { l_x l_y } [canvas2chart $a_x $a_y] break
    # Convert cartesian coords to polar coords
    foreach { l_phi l_r } [cartesian2polar $l_x $l_y] break
    # Change radius to circle radius
    set l_r $circle_r
    # Round angle (in rad) nearest step (in deg)
    set l_rad_step [expr ($a_step / 180.0) * $::pi]
    set l_phi [expr round(double($l_phi) / $l_rad_step) * $l_rad_step]
    # Convert polar coords to cartesian coords
    foreach { l_x l_y } [polar2cartesian $l_phi $l_r] break
    # Convert chart coords to canvas coords
    foreach { l_x l_y } [chart2canvas $l_x $l_y] break
    # Get angle label in chart degrees
    set l_deg [rad2chartDeg $l_phi]
    # Return new coordinates and phi label
    return [list $l_x $l_y $l_deg]
}

body StrategyWidget::angle2perimeterPoint { a_deg { a_r "" } } {
    if {$a_r == ""} {
	set l_r $circle_r
    } else {
	set l_r $a_r
    }
    # convert angle to radians
    set l_rad [chartDeg2rad $a_deg]
    # convert polar coords to cartesian
    foreach { l_x l_y } [polar2cartesian $l_rad $l_r] break
    # convert chart coords to canvas
    foreach { l_x l_y } [chart2canvas $l_x $l_y] break
    # return new coordinates
    return [list $l_x $l_y]
} 

body StrategyWidget::angle2perimeterAnchor { a_deg } {
    # Calculates anchor point for text label at perimeter point
    if {$a_deg == 0} {
	set l_anchor s
    } elseif {$a_deg == 90} {
	set l_anchor w
    } elseif {$a_deg == 180} {
	set l_anchor n
    } elseif {$a_deg == 270} {
	set l_anchor e
    } elseif {$a_deg > 270} {
	set l_anchor se
    } elseif {$a_deg > 180} {
	set l_anchor ne
    } elseif {$a_deg > 90} {
	set l_anchor nw
    } else {
	set l_anchor sw
    }
    return $l_anchor
}

# Feedback methods ##################################################

body StrategyWidget::processStrategyResponse { a_dom } {
    $results parseStrategyResult $a_dom

    $results display $itk_component(chart)

    displayCompleteness

    # Save temporary strategy file here
    if { [SaveToFile [.c getTempStrFilename]] } {
	.c wroteTempStrFile
    }

}

body StrategyWidget::displayCompleteness { } {
    # Clear pie canvas
    $itk_component(completeness_pie) delete all

   # Calc circle coords
    set l_width [winfo width $itk_component(completeness_pie)]
    set l_height [winfo height $itk_component(completeness_pie)]
    set l_centre_x [expr $l_width / 2]
    set l_centre_y [expr $l_height / 2]
    set l_unique_xc [expr $l_centre_x  - ($l_width / 4)]
    set l_anomalous_xc [expr $l_centre_x  + ($l_width / 4)]
    set l_radius 40 ; #[expr (($l_width / 2) - 12) / 2]

    # plot pies
    plotPie $l_unique_xc $l_centre_y $l_radius [$results getCompleteness] "Unique data"
    plotPie $l_anomalous_xc $l_centre_y $l_radius [$results getAnomalousCompleteness] "Anomalous data"

    # Add multiplicity label
    $itk_component(completeness_pie) create text \
	$l_centre_x [expr $l_centre_y + $l_radius + 5] \
	-text "Mean multiplicity: [$results getMeanMultiplicity]" \
	-anchor n

    # Bind to redraw on window configuration
    bind $itk_component(completeness_pie) <Configure> [code $this displayCompleteness]
}

body StrategyWidget::plotPie { a_x a_y a_r a_value { a_title "" } } {
    #puts "plotPie: $a_title $a_x $a_y $a_r $a_value"
    set l_x1 [expr $a_x - $a_r]
    set l_y1 [expr $a_y - $a_r]
    set l_x2 [expr $a_x + $a_r]
    set l_y2 [expr $a_y + $a_r]

    # create pie
    $itk_component(completeness_pie) create oval $l_x1 $l_y1 $l_x2 $l_y2 \
	-fill grey50 \
	-outline grey30
    $itk_component(completeness_pie) create arc $l_x1 $l_y1 $l_x2 $l_y2 \
	-start 90 \
	-extent [expr (0 - $a_value) * 3.6] \
	-fill "\#bb0000" \
	-outline "\#ff0000"
    $itk_component(completeness_pie) create text $a_x $a_y \
	-text "${a_value}%" \
	-font huge_font \
	-fill "gold"

    $itk_component(completeness_pie) create text $a_x [expr $a_y - $a_r - 5] \
	-text $a_title \
	-anchor s
}

body StrategyWidget::processStrategyBreakdownResponse { a_dom } {
    # Parse breakdown
    $results parseBreakdown $a_dom

    # Update breakdown trees
    #$itk_component(breakdown_palette) updateMultiplicityItems [$results cget -max_multiplicity]
    #$itk_component(breakdown_palette) updateResolutionItems [$results getResolutionBinLimits]

    set l_breakdown [$itk_component(breakdown_combo) get]
    if {$anomalous} {
	if {$l_breakdown == "Predicted completeness (percent) by resolution"} {
	    $itk_component(breakdown_combo) select 2
	} else {
	    updateBreakdown "combo" $l_breakdown
	}
    } else {
	if {$l_breakdown == "Predicted completeness of Bijvoet pairs by resolution"} {
	    $itk_component(breakdown_combo) select 0
	} else {
	    updateBreakdown "combo" $l_breakdown
	}	
    }	
    enable
    .c idle
}


body StrategyWidget::processStrategyAlignmentResponse { a_dom } {
    # Parse xml into results object
    $results parseAlignment $a_dom

    # Display crystal alignment
    foreach i_axis { a b c } {
	$itk_component(alignment_tree) item text $items_by_axis($i_axis) \
	    1 "[format %5.1f [$results getAlignment $i_axis "x"]]\u00b0 " \
	    2 "[format %5.1f [$results getAlignment $i_axis "y"]]\u00b0 "\
	    3 "[format %5.1f [$results getAlignment $i_axis "z"]]\u00b0 "
    }
    # Show closest axis
    foreach { l_axis l_angle } [$results getClosestAxis] break
    $itk_component(alignment_tree) item text $items_by_axis($l_axis) \
	4 "[format %5.1f $l_angle]\u00b0 to \u03c6 axis"
    $itk_component(alignment_tree) item element configure $items_by_axis($l_axis) 4 e_icon -image ::img::green_tick12x12

    # Show rotation of other axes
    foreach { l_axes l_angles } [$results getAxisRotations] break
    
    foreach i_index { 0 1 } {
	$itk_component(alignment_tree) item text $items_by_axis([lindex $l_axes $i_index]) \
	    4 "[format %5.1f [lindex $l_angles $i_index]]\u00b0 to XZ plane"
	$itk_component(alignment_tree) item element configure $items_by_axis([lindex $l_axes $i_index]) 4 e_icon -image ::img::red_cross12x12

    }
    # Show unique axis
    foreach { l_axis l_angle } [$results getUniqueAxis] break
    if {$l_axis != ""} {
	$itk_component(alignment_tree) item text $items_by_axis($l_axis) \
	    5 "[format %.1f $l_angle]\u00b0 to YZ plane"
	$itk_component(alignment_tree) item element configure $items_by_axis($l_axis) 5 e_icon -image ::img::green_tick12x12
    }
    foreach i_axis { a b c } {
	if {$i_axis != $l_axis} {
	    $itk_component(alignment_tree) item text $items_by_axis($i_axis) \
		5 ""
	    $itk_component(alignment_tree) item element configure $items_by_axis($i_axis) 5 e_icon -image {}
	}
    }
}

body StrategyWidget::linkPeakSep {dim1 dim2} {
    if {[[[.ats component spotfinding] component peak_sep_prop_linker] query]} {
        $itk_component(peak_sep_${dim2}_e) update [$itk_component(peak_sep_${dim1}_e) getValue]
    }
}

usual StrategyWidget { } 

# Breakdown palette class #####################################

class BreakdownPalette {
    inherit Palette

    # Breakdown graphing
    private variable data_by_item ; # array
    private variable items_by_datum ; # array

    public method updateBreakdown
#    public method updateMultiplicityItems
#    public method updateResolutionItems

    constructor { args } {}
}

body BreakdownPalette::constructor { args } {

    itk_component add border {
	frame $itk_interior.b \
	    -relief raised \
	    -bd 1 \
	    -highlightthickness 0 \
	    -bg white	    
    }

    itk_component add graph_tree {
	treectrl $itk_interior.b.gt \
	    -showroot 0 \
	    -showrootlines 0 \
	    -showbuttons 1 \
	    -selectmode extended \
	    -width 430 \
	    -height 430 \
	    -itemheight 18 \
	    -highlightthickness 0
    }

    $itk_component(graph_tree) column create -text "Data" -justify left -minwidth 100 -expand 1 ;
    $itk_component(graph_tree) element create e_text text -fill {white selected}
    $itk_component(graph_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(graph_tree) style create s1
    $itk_component(graph_tree) style elements s1 { e_highlight e_text }
    $itk_component(graph_tree) style layout s1 e_text -expand ns
    $itk_component(graph_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(graph_tree) notify bind $itk_component(graph_tree) <Selection> [code $this updateBreakdown %S %D]

    # Create 'By segment' breakdown item 
    set l_item [$itk_component(graph_tree) item create -button 1]
    # set the item's style
    $itk_component(graph_tree) item style set $l_item 0 s1
    # update the item's text
    $itk_component(graph_tree) item text $l_item 0 "Breakdown by segment"
    # add the new item to the tree
    $itk_component(graph_tree) item lastchild root $l_item
    # Store pointer to sector objects and items by bumber, item or object
    set data_by_item($l_item) by_segment
    set items_by_datum(by_segment) $l_item

    # Create 'By resolution' breakdown item 
    set l_item [$itk_component(graph_tree) item create -button 1]
    # set the item's style
    $itk_component(graph_tree) item style set $l_item 0 s1
    # update the item's text
    $itk_component(graph_tree) item text $l_item 0 "Breakdown by resolution"
    # add the new item to the tree
    $itk_component(graph_tree) item lastchild root $l_item
    # Store pointer to sector objects and items by bumber, item or object
    set data_by_item($l_item) by_resolution
    set items_by_datum(by_resolution) $l_item

    # Create segment data items
    foreach i_datum [StrategySector::getDataList] {
	# create a new item
	set l_item [$itk_component(graph_tree) item create]
	# set the item's style
	$itk_component(graph_tree) item style set $l_item 0 s1
	# update the item's text
	$itk_component(graph_tree) item text $l_item 0 [StrategySector::getDataName $i_datum]
	# add the new item to the tree
	$itk_component(graph_tree) item lastchild $items_by_datum(by_segment) $l_item
	# Store pointer to sector objects and items by bumber, item or object
	set data_by_item($l_item) $i_datum
	set items_by_datum($i_datum) $l_item
    }
    set items_by_datum(multiplicities) {}
    set items_by_datum(resolutions) {}

    # Multiplicity item
    set l_item [$itk_component(graph_tree) item create -button 1]
    # set the item's style
    $itk_component(graph_tree) item style set $l_item 0 s1
    # update the item's text
    $itk_component(graph_tree) item text $l_item 0 "Reflections by multiplicity"
    # add the new item to the tree
    $itk_component(graph_tree) item lastchild $items_by_datum(by_segment) $l_item
    # Store pointer to sector objects and items by bumber, item or object
    set items_by_datum(multiplicity) $l_item

    # Resolution item
    set l_item [$itk_component(graph_tree) item create -button 1]
    # set the  component item's style
    $itk_component(graph_tree) item style set $l_item 0 s1
    # update the item's text
    $itk_component(graph_tree) item text $l_item 0 "New unique reflections by resolution"
    # add the new item to the tree
    $itk_component(graph_tree) item lastchild $items_by_datum(by_segment) $l_item
    # Store pointer to sector objects and items by bumber, item or object
    set items_by_datum(resolution) $l_item

    # Create resolution data items
    foreach i_datum [StrategyResolutionBin::getDataList] {
	# create a new item
	set l_item [$itk_component(graph_tree) item create]
	# set the item's style
	$itk_component(graph_tree) item style set $l_item 0 s1
	# update the item's text
	$itk_component(graph_tree) item text $l_item 0 [StrategyResolutionBin::getDataName $i_datum]
	# add the new item to the tree
	$itk_component(graph_tree) item lastchild $items_by_datum(by_resolution) $l_item
	# Store pointer to sector objects and items by bumber, item or object
	set data_by_item($l_item) $i_datum
	set items_by_datum($i_datum) $l_item
    }
    # Sector list scrollbar
    itk_component add graph_scroll {
	scrollbar $itk_interior.b.gs \
	    -borderwidth 1 \
	    -orient vertical \
	    -width 12 \
	    -command [code $this component graph_tree yview]
    }
    
    $itk_component(graph_tree) configure \
	-treecolumn 0 \
	-yscrollcommand [list autoscroll $itk_component(graph_scroll)]

    pack $itk_component(border)
    grid $itk_component(graph_tree) $itk_component(graph_scroll) -sticky nsew

}

body BreakdownPalette::updateBreakdown { a_newly_selected_items a_newly_deselected_items } {

    # Take care of category item selection/deselection ########################

    # Turn off selection bindings
    $itk_component(graph_tree) notify bind $itk_component(graph_tree) <Selection> {}

    # Deselect any root nodes
    $itk_component(graph_tree) selection modify {} [list $items_by_datum(by_segment) $items_by_datum(by_resolution)]

    # If a multiplicity item is deselected, deselect parent item
    foreach i_item $items_by_datum(multiplicities) {
	if {[$itk_component(graph_tree) selection includes $i_item]} {
	    $itk_component(graph_tree) selection modify {} $items_by_datum(multiplicity)
	    break
	}
    }
    # if the multiplicity item is selected, select all children
    if {[$itk_component(graph_tree) selection includes $items_by_datum(multiplicity)]} {
	$itk_component(graph_tree) selection modify  [$itk_component(graph_tree) item children $items_by_datum(multiplicity)] {}
    } elseif {[lsearch $a_newly_deselected_items $items_by_datum(multiplicity)] > -1} {
	$itk_component(graph_tree) selection modify {} [$itk_component(graph_tree) item children $items_by_datum(multiplicity)]
    }

    # If a resolution item is deselected, deselect parent item
    foreach i_item $items_by_datum(resolutions) {
	if {[$itk_component(graph_tree) selection includes $i_item]} {
	    $itk_component(graph_tree) selection modify {} $items_by_datum(resolution)
	    break
	}
    }
    # if the multiplicity item is selected, select all children
    if {[$itk_component(graph_tree) selection includes $items_by_datum(resolution)]} {
	$itk_component(graph_tree) selection modify  [$itk_component(graph_tree) item children $items_by_datum(resolution)] {}
    } elseif {[lsearch $a_newly_deselected_items $items_by_datum(resolution)] > -1} {
	$itk_component(graph_tree) selection modify {} [$itk_component(graph_tree) item children $items_by_datum(resolution)]
    }

    # Turn on selection bindings
    $itk_component(graph_tree) notify bind $itk_component(graph_tree) <Selection> [code $this updateBreakdown %S %D]


    # Plot graphs for selected items ######################################

    # See how many graphs are needed
	set l_segment_data_to_graph {}
	# build list of segment data to graph
	foreach i_datum [StrategySector::getDataList] {
	    if {[$itk_component(graph_tree) selection includes $items_by_datum($i_datum)]} {
		lappend l_segment_data_to_graph $i_datum
	    }
	}
	# Add multiplicities to list if required
	if {[$itk_component(graph_tree) selection includes $items_by_datum(multiplicity)]} {
	    foreach i_item $items_by_datum(multiplicities) {
		lappend l_segment_data_to_graph $data_by_item($i_item)
	    }
	} else {
	    foreach i_item $items_by_datum(multiplicities) {
		if {[$itk_component(graph_tree) selection includes $i_item]} {
		    lappend l_segment_data_to_graph $data_by_item($i_item)
		}
	    }
	}

	# Add resolutions to list if required
	if {[$itk_component(graph_tree) selection includes $items_by_datum(resolution)]} {
	    foreach i_item $items_by_datum(resolutions) {
		lappend l_segment_data_to_graph $data_by_item($i_item)
	    }
	} else {
	    foreach i_item $items_by_datum(resolutions) {
		if {[$itk_component(graph_tree) selection includes $i_item]} {
		    lappend l_segment_data_to_graph $data_by_item($i_item)
		}
	    }
	}

	set l_resolution_data_to_graph {}
	# build list of resolutiondata to graph
	foreach i_datum [StrategyResolutionBin::getDataList] {
	    if {[$itk_component(graph_tree) selection includes $items_by_datum($i_datum)]} {
		lappend l_resolution_data_to_graph $i_datum
	    }
	}

    [.c component strategy] plotBreakdown $l_segment_data_to_graph $l_resolution_data_to_graph
}

#body BreakdownPalette::updateMultiplicityItems { a_max_multiplicity } {
#
#    # Delete multiplicity items
#    set l_items_to_delete [$itk_component(graph_tree) item children $items_by_datum(multiplicity)]
#    if {[llength $l_items_to_delete] != 0} {
#	eval $itk_component(graph_tree) item delete [lindex $l_items_to_delete 0] [lindex $l_items_to_delete end]
#    }
#    set items_by_datum(multiplicities) {}
#
#    # Create new multiplicity items
#    set i_multiplicity 1
#    while {$i_multiplicity < $a_max_multiplicity} {
#	# create a new item
#	set l_item [$itk_component(graph_tree) item create]
#	# set the item's style
#	$itk_component(graph_tree) item style set $l_item 0 s1
#	# update the item's text
#	$itk_component(graph_tree) item text $l_item 0 "Reflections with multiplicity $i_multiplicity"
#	# add the new item to the tree
#	$itk_component(graph_tree) item lastchild $items_by_datum(multiplicity) $l_item
#	# Store pointer to sector objects and items by bumber, item or object
#	set data_by_item($l_item) multiplicity$i_multiplicity
#	lappend items_by_datum(multiplicities) $l_item
#	incr i_multiplicity
#    }
#
#}
#
#body BreakdownPalette::updateResolutionItems { a_limits } {
#    # Delete resolution items
#    foreach i_item $items_by_datum(resolutions) {
#	$itk_component(graph_tree) item delete $i_item
#    }
#    set items_by_datum(resolutions) {}
#
#    # Create new resolution items
#    set i_bin 0
#    set l_low_res "\u221e"
#    while {$i_bin < 8} {
#	# create a new item
#	set l_item [$itk_component(graph_tree) item create]
#	# set the item's style
#	$itk_component(graph_tree) item style set $l_item 0 s1
#	# update the item's text
#	if {$i_bin > 0} {
#	    set l_low_res [lindex $a_limits [expr $i_bin - 1]]
#	}
#	set l_hi_res [lindex $a_limits $i_bin]
#	$itk_component(graph_tree) item text $l_item 0 "Resolution between $l_low_res and $l_hi_res"
#	# add the new item to the tree
#	$itk_component(graph_tree) item lastchild $items_by_datum(resolution) $l_item
#	# Store pointer to sector objects and items by bumber, item or object
#	set data_by_item($l_item) resolution$i_bin
#	lappend items_by_datum(resolutions) $l_item
#	incr i_bin
#    }
#}

usual BreakdownPalette {
    keep -textbackground -borderwidth
}

# SectorSet class #############################################

class SectorSet {

    private variable matrix ""
    private variable sectors {}

    public method copyMatrix
    public method getMatrix
    public method addSector
    public method getSectors { } { return $sectors }
    public method deleteSector
    public method sortSectors
    public proc sortSectorPair

    constructor { args } { }

    destructor {
	delete object $matrix
	foreach i_sector $sectors {
	    [.c component strategy] deleteSector $i_sector 0
	}
    }
}

body SectorSet::constructor { a_matrix } {
    set matrix [namespace current]::[Matrix \#auto "copy" $a_matrix]
    
}

body SectorSet::copyMatrix { a_matrix } {
    $matrix copyFrom $a_matrix
}

body SectorSet::getMatrix { } {
    return $matrix 
}

body SectorSet::addSector { a_sector } {
    lappend sectors $a_sector
    [$a_sector getMatrix] setName [$matrix getName]
}

body SectorSet::deleteSector { a_sector } {
    set l_index [lsearch $sectors $a_sector]
    if {$l_index != -1} {
	set sectors [lreplace $sectors $l_index $l_index]
    }
    #delete object $a_sector
}

body SectorSet::sortSectors { } {
    set sectors [lsort -command SectorSet::sortSectorPair $sectors]
}

body SectorSet::sortSectorPair { a b } {
    foreach { a_start a_extent } [$a getPhi] break
    foreach { b_start b_extent } [$b getPhi] break
    if { $a_start < $b_start } {
	return -1
    } elseif {$a_start > $b_start} {
	return 1
    } elseif {$a_extent < $b_extent} {
	return -1
    } elseif {$a_extent > $b_extent} {
	return 1
    } else {
	return 0
    }
}

# ProtoSector class ###########################################

class ProtoSector {
    
    # member variables
    private variable start ""
    private variable extent ""
    private variable end ""
    private variable size ""
    private variable matrix ""
    private variable type "normal"

    # methods
    public method getPhi
    public method setPhi
    public method getPhiLimits
    public method getMatrix { } { return $matrix }
    public method copyMatrix
    public method listMatrix { } {return [$matrix listMatrix]}
    public method setMatrix { args } {eval $matrix setMatrix $args}

    public method getType { } { return $type }
    public method setType { a_type } { set type $a_type }

    constructor { a_start a_extent a_end } {
	set matrix [namespace current]::[Matrix \#auto "blank" "Unknown"]
	set start $a_start
	set extent $a_extent
	set end $a_end
    }
}

body ProtoSector::copyMatrix  { a_matrix } { 
    $matrix copyFrom $a_matrix
} 

body ProtoSector::getPhi { } {
    return [list $start $extent $end]
}

body ProtoSector::setPhi { a_start a_extent } {
    set start [expr int(ceil($a_start)) % 360]
    set extent $a_extent
}

body ProtoSector::getPhiLimits { } {
    return [list $start [expr ($start + $extent)]]
}

# New matrix dialog ############################################

class MatrixDialog {
    inherit Dialog

    private variable name ""
    private variable a11 ""
    private variable a12 ""
    private variable a13 ""
    private variable a21 ""
    private variable a22 ""
    private variable a23 ""
    private variable a31 ""
    private variable a32 ""
    private variable a33 ""

    public method load
    public method get
    private method cancel
    private method ok
    public method clear
    private method openMatrixFile
    private method saveMatrixFile
    private method validateMatrix

    constructor { args } { }
}

body MatrixDialog::constructor { args } {

    itk_component add name_l {
	label $itk_interior.nl \
	    -text "Name: "
    }

    itk_component add name_e {
	gEntry $itk_interior.e \
	    -textvariable [scope name]
    }

    itk_component add open_button {
	Toolbutton $itk_interior.ob \
	    -type "amodal" \
	    -image ::img::folder16x16 \
	    -command [code $this openMatrixFile] \
	    -balloonhelp " Open matrix file... "
    }

    itk_component add save_button {
	Toolbutton $itk_interior.sb \
	    -type "amodal" \
	    -image ::img::disk16x16 \
	    -disabledimage ::img::disk_disabled16x16 \
	    -command [code $this saveMatrixFile] \
	    -balloonhelp " Save matrix file... "
    }

    itk_component add matrix_l {
	label $itk_interior.ml \
	    -text "Matrix: "
    }

    foreach i_element { 11 12 13 21 22 23 31 32 33 } {
	itk_component add a${i_element}_e {
	    gEntry $itk_interior.a${i_element}e \
		-type real \
		-precision 8 \
		-width 12 \
		-textvariable [scope a$i_element] \
		-justify right \
		-command [code $this validateMatrix]
	}
    }

    itk_component add button_frame {
	frame $itk_interior.bf
    }

    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -command [code $this cancel]
    }

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "OK" \
	    -width 7 \
	    -command [code $this ok]
    }

    grid $itk_component(name_l) $itk_component(name_e) - $itk_component(open_button) $itk_component(save_button) x -sticky w -padx 7 -pady 7
    grid configure  $itk_component(name_e) -sticky we
    grid configure $itk_component(open_button) $itk_component(save_button) -padx [list 7 0]
    grid $itk_component(matrix_l) $itk_component(a11_e) $itk_component(a12_e) $itk_component(a13_e) - - -padx 7
    grid x $itk_component(a21_e) $itk_component(a22_e) $itk_component(a23_e) - - -padx 7 -pady 7
    grid x $itk_component(a31_e) $itk_component(a32_e) $itk_component(a33_e) - - -padx 7
    grid $itk_component(button_frame) - - - - - -sticky we
    grid columnconfigure $itk_interior { 5 } -weight 1

    pack $itk_component(ok) $itk_component(cancel) -side right -pady 7 -padx { 0 7 }

    eval itk_initialize $args
}

body MatrixDialog::load { a_matrix } {
    set name [$a_matrix getName]
    foreach { a11 a12 a13 a21 a22 a23 a31 a32 a33 } [$a_matrix listMatrix] break
}

body MatrixDialog::cancel { } {
    dismiss ""
}
	
body MatrixDialog::ok { } {
    set l_matrix [namespace current]::[Matrix \#auto "initialize" $name $a11 $a12 $a13 $a21 $a22 $a23 $a31 $a32 $a33]
    dismiss $l_matrix
}

body MatrixDialog::get { } {
    return [confirm]
}

body MatrixDialog::openMatrixFile { } {
    # Create open matrix dialog if it doesn't exist
    if {![winfo exists .openMatrix]} {
	Fileopen .openMatrix \
	    -title "Open matrix file" \
	    -type open \
	    -initialdir [pwd] \
	    -filtertypes {{"Matrix files" {.mat}} {"All Files" {.*}}}
    }
    # Get a filename from the user
    set l_matrix_file [.openMatrix get]
    # If the user picked a file
    if {$l_matrix_file != ""} {
	# Set the matrix name from the filename
	set name [file tail [file rootname $l_matrix_file]]

	# Open the file
	set l_channel [open $l_matrix_file]

	# Read three lines..
	foreach i_row { 1 2 3 } {
	    # Read the file's line
	    if {[catch {gets $l_channel} line]} {
		puts "Error reading from file"
		clear
		break
	    }
	    # initialize success flag to zero
	    set l_success 0
	    # Read the three numbers
	    if {[regexp {^\s*(\-?0\.\d+)\s+(\-?0\.\d+)\s+(\-?0\.\d+)\s*$} $line match c1 c2 c3]} {
		foreach i_column { 1 2 3 } {
		    set a${i_row}${i_column} [set c$i_column]
		}
	    } else {
		puts "File $l_matrix_file is not a properly formatted matrix file."
		clear
		break
	    }

	}
	# Close the file
	close $l_channel
    }
    validateMatrix
}

body MatrixDialog::saveMatrixFile { } {
    # Create save matrix dialog if it doesn't exist
    if {![winfo exists .saveMatrix]} {
	Fileopen .saveMatrix \
	    -title "Save matrix file" \
	    -type save \
	    -initialdir [pwd] \
	    -filtertypes {{"Matrix files" {.mat}} {"All Files" {.*}}}
    }
    # Get a filename from the user
    set l_matrix_file [.saveMatrix get]
    # If the user picked a file
    if {$l_matrix_file != ""} {
	# Set the matrix name from the filename
	set name [file tail [file rootname $l_matrix_file]]
	# Use Mosflm command to write the full matrix file with A, U, missets & cell
	$::mosflm sendCommand "wmat $l_matrix_file"
    }
}

body MatrixDialog::clear { } {
    set name ""
    foreach i_row { 1 2 3 } {
	foreach i_column { 1 2 3 } {
	    set a${i_row}${i_column} ""
	}
    }
    $itk_component(ok) configure -state disabled
    $itk_component(save_button) configure -state disabled
}

body MatrixDialog::validateMatrix { args } {
    set l_valid_matrix 1
    foreach i_row { 1 2 3 } {
	foreach i_column { 1 2 3 } {
	    set l_element [set a${i_row}${i_column}]
	    if {$l_element == "" || (![string is double $l_element])} {
		set l_valid_matrix 0
		break
	    }
	}
	if {!$l_valid_matrix} {
	    break
	}
    }
    if {$l_valid_matrix} {
	$itk_component(ok) configure -state normal
	$itk_component(save_button) configure -state normal
    } else {
	$itk_component(ok) configure -state disabled
	$itk_component(save_button) configure -state disabled
    }
}

# Auto-calculate dialog ########################################

class StrategyCalcDialog {
    inherit Dialog

    private variable rotation "Auto"
    private variable segments "1"
    private variable matrix_name ""
    private variable matrices_by_name ; # array
    private variable include_existing_sectors "1" ; # turn on always now 'Use' column added to sector_tree
    private variable optimize_anomalous "0"
    private method ok
    private method cancel
    public method confirm

    constructor { args } { }
}

body StrategyCalcDialog::constructor { args } {

    .scd configure -title "Auto-complete..."

    # Matrix combo + label
    itk_component add matrix_label {
	label $itk_interior.ml \
	    -text "Matrix: "
    }
    itk_component add matrix_combo {
	Combo $itk_interior.mc \
	    -textvariable [scope matrix_name] \
	    -width 16 \
	    -items {} \
	    -editable 0 \
	    -highlightcolor black
    }

    # Rotation combo + label
    itk_component add rotation_label {
	label $itk_interior.rl \
	    -text "Rotation: "
    }
    itk_component add rotation_combo {
	Combo $itk_interior.rc \
	    -textvariable [scope rotation] \
	    -width 4 \
	    -items {Auto 5 10 20 30 40 50 60 70 80 90} \
	    -editable 1 \
	    -highlightcolor black
    }

    # Segments combo + label
    itk_component add segments_label {
	label $itk_interior.sgl \
	    -text "Segments: "
    }
    itk_component add segments_combo {
	Combo $itk_interior.sgc \
	    -textvariable [scope segments] \
	    -width 2 \
	    -items {1 2 3} \
	    -editable 0 \
	    -highlightcolor black
    }
    
    # Anomalous option
    itk_component add anomalous_cb {
	gcheckbutton $itk_interior.ac \
	    -variable [scope optimize_anomalous] \
	    -text "Optimize for anomalous data"
    }

    # Buttons
    itk_component add button_frame {
	frame $itk_interior.bf
    }

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "Ok" \
	    -width 7 \
	    -highlightbackground "#dcdcdc" \
	    -command [code $this ok]
    }

    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -highlightbackground "#dcdcdc" \
	    -command [code $this cancel]
    }

    grid $itk_component(matrix_label) $itk_component(matrix_combo) -stick w
    grid $itk_component(rotation_label) $itk_component(rotation_combo) -stick w
    grid $itk_component(segments_label) $itk_component(segments_combo) -sticky w
    grid $itk_component(anomalous_cb) - -sticky w
    grid $itk_component(button_frame) - -sticky we
    pack $itk_component(ok) $itk_component(cancel) \
	-side right \
	-padx {0 7} \
	-pady 7
}

body StrategyCalcDialog::ok { } {
    set l_matrix $matrices_by_name($matrix_name)
    dismiss [list $l_matrix $rotation $segments $include_existing_sectors $optimize_anomalous]
}

body StrategyCalcDialog::cancel { } {
    dismiss ""
}

body StrategyCalcDialog::confirm { } {
    array unset matrices_by_name *
    set l_matrices [[.c component strategy] getMatrices]
    set l_current_matrix [[.c component strategy] getCurrentMatrix]
    set l_matrix_names {}
    foreach i_matrix $l_matrices {
	set l_sector [$::session getSectorByMatrix $i_matrix]

	lappend l_matrix_names [$i_matrix getName]
	set matrices_by_name([$i_matrix getName]) $i_matrix
    }
    $itk_component(matrix_combo) configure -items $l_matrix_names
    set matrix_name [$l_current_matrix getName]
    Dialog::confirm
}

# StrategyResult ###############################################

class StrategyResult {

    # stratgey results
    private variable completeness ""
    private variable anomalous_completeness ""
    private variable mean_multiplicity ""
    private variable stepsize ""
    private variable sector_list {}

    # alignment results
    private variable crystal_orientation ; # array
    private variable closest_axis_to_rotation_axis ""
    private variable closest_angle_to_rotation_axis ""
    private variable plane_crystal_rotation_axes {}
    private variable plane_crystal_rotation_angles {}
    private variable crystal_unique_axis ""
    private variable crystal_unique_axis_offset ""
    private variable cusp_avoidance_start_angle ""
    private variable cusp_avoidance_end_angle ""

    # stragey results breakdown
    public variable max_multiplicity ""
    private variable sector_breakdown {}
    private variable resolution_breakdown {}
    private variable sectors_by_phi_start ; # array
    private variable resolution_bin_limits [list "Inf"]

    public method addSegment

    public method getCompleteness { } { return $completeness }
    public method getAnomalousCompleteness { } { return $anomalous_completeness }
    public method getMeanMultiplicity { } { return $mean_multiplicity }
    public method getAlignment
    public method getClosestAxis
    public method getAxisRotations
    public method getUniqueAxis

    public method parseStrategyResult
    public method parseAlignment
    public method parseBreakdown

    public method getSectorBreakdown
    public method getResolutionBreakdown
    public method getResolutionBinLimit
    public method getResolutionBinLimits

    public method display
    public method serialize

    #public method hack
    
}

body StrategyResult::addSegment { a_start a_end } {
    if {$a_start < $a_end} {
	set l_extent [expr $a_end - $a_start]
    } else {
	set l_extent [expr 360 - $a_start + $a_end]
    }
    set l_start [expr int(ceil($a_start)) % 360]
    set l_segment [namespace current]::[ProtoSector \#auto $l_start $l_extent $a_end]
    $l_segment setType "proposed" 
    $l_segment copyMatrix [[.c component strategy] getUsedMatrix]
    lappend sector_list $l_segment
}

body StrategyResult::getAlignment { a_cell_axis a_frame_axis } {
    return $crystal_orientation($a_cell_axis,$a_frame_axis)
}

body StrategyResult::getClosestAxis { } {
    return [list $closest_axis_to_rotation_axis $closest_angle_to_rotation_axis]
}

body StrategyResult::getAxisRotations { } {
    return [list $plane_crystal_rotation_axes $plane_crystal_rotation_angles]
}

body StrategyResult::getUniqueAxis { } {
    return [list $crystal_unique_axis $crystal_unique_axis_offset]
}

body StrategyResult::parseStrategyResult { a_dom } {
    # pass xml data to results object
    set "completeness" [$a_dom selectNodes normalize-space(//completeness)]
    set "anomalous_completeness" [$a_dom selectNodes normalize-space(//anomalous_completeness)]
    set "mean_multiplicity" [$a_dom selectNodes normalize-space(//mean_multiplicity)]
    set "stepsize" [$a_dom selectNodes normalize-space(//stepsize)]
    foreach i_segment_node [$a_dom selectNodes //proposed] {
	addSegment \
	    [expr int([$i_segment_node selectNodes normalize-space(start)])] \
	    [expr int([$i_segment_node selectNodes normalize-space(end)])] \
    }
}

body StrategyResult::parseAlignment { a_dom } {
    foreach i_cell_dim { a b c } {
	foreach i_frame_dim { x y z } {
	    set crystal_orientation($i_cell_dim,$i_frame_dim) \
		[$a_dom selectNodes normalize-space(//angle_${i_cell_dim}_${i_frame_dim})]
	}
    }
    set closest_axis_to_rotation_axis [$a_dom selectNodes normalize-space(//axis_crystal_rotation_axis)]
    set closest_angle_to_rotation_axis [$a_dom selectNodes normalize-space(//axis_crystal_rotation_angle)]
    set plane_crystal_rotation_axes {}
    foreach i_node [$a_dom selectNodes {//plane_crystal_rotation_axis}] {
	lappend plane_crystal_rotation_axes [$i_node text]
    }
    set plane_crystal_rotation_angles {}
    foreach i_node [$a_dom selectNodes {//plane_crystal_rotation_angle}] {
	lappend plane_crystal_rotation_angles [$i_node text]
    }
    set crystal_unique_axis [$a_dom selectNodes normalize-space(//crystal_unique_axis)]
    set crystal_unique_axis_offset [$a_dom selectNodes normalize-space(//crystal_unique_axis_offset)]
    set crystal_unique_minimum_offset [$a_dom selectNodes normalize-space(//crystal_unique_axis_minimum_offset)]
}

body StrategyResult::parseBreakdown { a_dom } {
    # Delete any existing breakdown objects
	# --variable genealogy-- sector_breakdown is a StrategyResult variable
    if {$sector_breakdown != {}} {
	eval delete object $sector_breakdown
	set sector_breakdown {}
    }
    # Get the max multiplicity
	# --variable genealogy-- l_rotation_node is a holder variable
    set l_rotation_node [$a_dom selectNodes {strategy_response_breakdown/by_rotation_range}]
	# --variable genealogy-- max_multiplicity is a StrategyResult variable
    set max_multiplicity [$l_rotation_node selectNodes normalize-space(maximum_multiplicity)]
    # Parse the segment nodes into objects
	# --variable genealogy-- i_segment_node and l_new_sector are holder variables
    foreach i_segment_node [$l_rotation_node selectNodes segment] {
	set l_new_sector [namespace current]::[StrategySector \#auto "mosflm" $i_segment_node]
	# --variable genealogy-- sector_breakdown is a StrategyResult variable
	lappend sector_breakdown $l_new_sector
	# --variable genealogy-- sectors_by_phi_start is a StrategyResult variable
	set sectors_by_phi_start([$l_new_sector getPhiStart]) $l_new_sector
    }
    # Parse the resolution nodes into objects
	# --variable genealogy-- l_by_resolution_node and i_segment_node are holder variables
    set l_by_resolution_node [$a_dom selectNodes {strategy_response_breakdown/by_resolution}]
    # Sector resolution breakdowns
	# Parse resolution data from StrategySector objects
    foreach i_segment_node [$l_by_resolution_node selectNodes {segment}] {
	$sectors_by_phi_start([$i_segment_node selectNodes normalize-space(angle_start)]) parseResolutionData $i_segment_node
    }
    # Total resolution breakdowns
	# --variable genealogy-- i_bin_node is a holder variable
    foreach i_bin_node [$l_by_resolution_node selectNodes {resolution_bin}] {
	# --variable genealogy-- resolution breakdown and resolution_bin_limits are StrategyResult variable
	lappend resolution_breakdown [namespace current]::[StrategyResolutionBin \#auto "mosflm" $i_bin_node]
	# Resolution bin limits
	lappend resolution_bin_limits [$i_bin_node selectNodes normalize-space(high_resolution_limit)]
    }
}

body StrategyResult::getSectorBreakdown { a_parameter_list } {
    # Initialize tick and bin labels
    set x_tick_labels [[lindex $sector_breakdown 0] cget -phi_start]
    set x_bin_labels {}
    set y_i 0
    # Initialize y-data lists
    foreach i_parameter $a_parameter_list {
	set y_data($i_parameter) {}
	if {[StrategySector::isDatum $i_parameter]} {
	    set l_data_name($i_parameter) [StrategySector::getDataName $i_parameter]
	} elseif {[regexp {multiplicity(\d)} $i_parameter l_match l_number]} {
	    set l_data_name($i_parameter) "Reflections with multiplicity $l_number"
	} elseif {[regexp {resolution(\d)} $i_parameter l_match l_number]} {
	    if {$l_number == 0} {
		set l_low_limit "\u221e"
	    } else {
		set l_low_limit [getResolutionBinLimit [expr $l_number - 1]]
	    }
	    set l_hi_limit [getResolutionBinLimit $l_number]
	    set l_data_name($i_parameter) "New unique relections with resolution between $l_low_limit and $l_hi_limit"
	} else {
	    lappend y_data($i_parameter) ""
	}
	
    }
    # Loop through segments
    foreach i_sector $sector_breakdown {
	set l_new_bin_start [$i_sector cget -phi_start]
	# Add breaks if the segments are not contiguous
	if {$l_new_bin_start != [lindex $x_tick_labels end]} {
	    foreach i_parameter $a_parameter_list {
		lappend y_data($i_parameter) {}
	    }
	    lappend x_bin_label {}
	    lappend x_tick_labels $l_new_bin_start
	}
	# Loop through requestsed data
	foreach i_parameter $a_parameter_list {
	    # depending on data type
	    if {[StrategySector::isDatum $i_parameter]} {
		# Get simple data
		lappend y_data($i_parameter) [$i_sector cget -$i_parameter]
	    } elseif {[regexp {multiplicity(\d)} $i_parameter l_match l_number]} {
		# get multiplicity data
		lappend y_data($i_parameter) [$i_sector getCumSpotsByMulti $l_number]
	    } elseif {[regexp {resolution(\d)} $i_parameter l_match l_number]} {
		# get resolution data
		lappend y_data($i_parameter) [$i_sector getNewUniqueByResolution $l_number]
	    } else {
		lappend y_data($i_parameter) ""
	    }
	}
	lappend x_bin_labels {}
	lappend x_tick_labels [$i_sector cget -phi_end]
    }
    set l_x_binset [namespace current]::[Binset \#auto "Segment" $x_tick_labels $x_bin_labels [Unit::getUnit "\u00b0"]]
    set l_y_datasets {}
    foreach i_parameter $a_parameter_list {
	lappend l_y_datasets [namespace current]::[Dataset \#auto $y_data($i_parameter) [Unit::getUnit ""] $l_data_name($i_parameter) ""]
    }
    return [list $l_x_binset $l_y_datasets]
}

body StrategyResult::getResolutionBreakdown { a_parameter_list } {
    # Initialize tick and bin labels
    set x_tick_labels "\u221e"
    set x_bin_labels {}
    set y_i 0
    # Initialize y-data lists
    foreach i_parameter $a_parameter_list {
	set y_data($i_parameter) {}
	set l_data_name($i_parameter) [StrategyResolutionBin::getDataName $i_parameter]
    }
    # Loop through bins
    foreach i_bin $resolution_breakdown {
	# Loop through requestsed data
	foreach i_parameter $a_parameter_list {
	    # Get simple data
	    lappend y_data($i_parameter) [$i_bin cget -$i_parameter]
	}
	lappend x_bin_labels {}
	lappend x_tick_labels [$i_bin cget -high_resolution_limit]
    }
    set l_x_binset [namespace current]::[Binset \#auto "Bin" $x_tick_labels $x_bin_labels [Unit::getUnit ""]]
    set l_y_datasets {}
    foreach i_parameter $a_parameter_list {
	lappend l_y_datasets [namespace current]::[Dataset \#auto $y_data($i_parameter) [Unit::getUnit ""] $l_data_name($i_parameter) ""]
    }
    return [list $l_x_binset $l_y_datasets]
}

body StrategyResult::getResolutionBinLimit { a_bin } {
    return [[lindex $sector_breakdown 0] getResolutionBinLimit "$a_bin"]
}

body StrategyResult::getResolutionBinLimits { } {
    return $resolution_bin_limits
}

body StrategyResult::display { a_canvas } {
    foreach i_sector $sector_list {
	[.c component strategy] addProtoSector $i_sector
	[.c component strategy] plotSector $i_sector
    }
}

body StrategyResult::serialize { } {
    set xml "<strategy_result completeness=\"$completeness\" stepsize=\"$stepsize\" crystal_orientation=\"$crystal_orientation\" closest_axis_to_rotation_axis=\"$closest_axis_to_rotation_axis\" closest_axis_to_rotation_angle=\"$closest_axis_to_rotation_angle\" plane_crystal_rotation_axes=\"$plane_crystal_rotation_axes\" plane_crystal_rotation_angles=\"$plane_crystal_rotation_angles\" crystal_unique_axis=\"$crystal_unique_axis\" crystal_unique_axis_offset=\"$crystal_unique_axis_offset\" cusp_avoidance_start_angle=\"$cusp_avoidance_start_angle\" cusp_avoidance_end_angle=\"$cusp_avoidance_end_angle\">"
    foreach i_sector $sector_list {
	append xml [$i_sector serialize]
    }
    foreach i_sector $sector_breakdown {
	append xml [$i_sector serialize]
    }
    append xml "</strategy_result>"
    return $xml
}

# ###########################################################################

# Strategy breakdown classes

class StrategySector {

    common names ; # array
    common data_list {}
    proc initializeNames
    proc getDataList
    proc isDatum
    proc getDataName

    public variable phi_start ""
    public variable phi_end ""
    public variable num_reflections ""
    public variable cumulative_unique ""
    public variable percent_cum_unique ""
    public variable mean_multiplicity ""
    public variable multiplicity_1 "0"
    public variable multiplicity_2 "0"
    public variable multiplicity_3 "0"
    public variable multiplicity_4 "0"
    public variable multiplicity_5+ "0"
    public variable resolution_1 ""
    public variable resolution_2 ""
    public variable resolution_3 ""
    public variable resolution_4 ""
    public variable resolution_5 ""
    public variable resolution_6 ""
    public variable resolution_7 ""
    public variable resolution_8 ""

    public method getPhiStart { } {return $phi_start}
    public method getCumSpotsByMulti
    public method getNewUniqueByResolution
    public method getResolutionBinLimit
    public method getResolutionBinLimits
    public method parseResolutionData

    public method hack

    constructor { a_method a_node } { }
}

body StrategySector::hack { } {
}

body StrategySector::initializeNames { args } {
    foreach { token name } $args {
	set names($token) $name
	lappend data_list $token
    }
}

body StrategySector::getDataList { } {
    return $data_list
}

body StrategySector::getDataName { a_datum } {
    return $names($a_datum)
}


body StrategySector::isDatum { a_datum } {
    return [expr [lsearch $data_list $a_datum] > -1]
}

StrategySector::initializeNames \
    mean_multiplicity "Mean multiplicity by segment" \
    percent_cum_unique "Cumulative completeness (percent) by segment" \
    multiplicity_1 "Percentage unique data with multiplicity 1 by segment" \
    multiplicity_2 "Percentage unique data with multiplicity 2 by segment" \
    multiplicity_3 "Percentage unique data with multiplicity 3 by segment" \
    multiplicity_4 "Percentage unique data with multiplicity 4 by segment" \
    multiplicity_5+ "Percentage unique data with multiplicity 5+ by segment" \
    resolution_1 "Cumulative completeness in resolution bin 1 by segment" \
    resolution_2 "Cumulative completeness in resolution bin 2 by segment" \
    resolution_3 "Cumulative completeness in resolution bin 3 by segment" \
    resolution_4 "Cumulative completeness in resolution bin 4 by segment" \
    resolution_5 "Cumulative completeness in resolution bin 5 by segment" \
    resolution_6 "Cumulative completeness in resolution bin 6 by segment" \
    resolution_7 "Cumulative completeness in resolution bin 7 by segment" \
    resolution_8 "Cumulative completeness in resolution bin 8 by segment" \
    num_reflections "Number of reflections by segment" \
    cumulative_unique "Cumulative unique reflections by segment"

body StrategySector::constructor { a_method a_node } {
    if { $a_method == "mosflm" } {
	set phi_start [$a_node selectNodes normalize-space(angle_start)]
	set phi_end [$a_node selectNodes normalize-space(angle_end)]
	set num_reflections [$a_node selectNodes normalize-space(number_in_range)]
	set cumulative_unique [$a_node selectNodes normalize-space(cumulative_unique)]
	set percent_cum_unique [$a_node selectNodes normalize-space(percent_cumulative_unique)]
	set mean_multiplicity [$a_node selectNodes normalize-space(mean_multiplicity)]
	foreach i_node [$a_node selectNodes {statistics}] {
	    set multiplicity_[$i_node selectNodes normalize-space(multiplicity)] [$i_node selectNodes normalize-space(percent_unique)]
	}
    }
}

body StrategySector::getCumSpotsByMulti { a_multi } {
    return [set multiplicities_$a_multi]
}

body StrategySector::getNewUniqueByResolution { a_bin } {
    return [set resolution_$a_bin]
}

body StrategySector::parseResolutionData { a_node } {
    set i_bin 1
    foreach i_node [$a_node selectNodes {resolution}] {
	set resolution_$i_bin [$i_node selectNodes normalize-space(percent_cumulative)]
	incr i_bin
    }
}

# ###########################################################################

class StrategyResolutionBin {

    common names ; # array
    common data_list {}
    proc initializeNames
    proc getDataList
    proc isDatum
    proc getDataName

    public variable high_resolution_limit ""
    public variable standard_unique ""
    public variable predicted ""
    public variable percent_predicted ""
    public variable acentric_unique ""
    public variable generated_bijvoets ""
    public variable percent_bijvoets ""

    constructor { a_method args } { }
}

body StrategyResolutionBin::initializeNames { args } {
    foreach { token name } $args {
	set names($token) $name
	lappend data_list $token
    }
}

body StrategyResolutionBin::getDataList { } {
    return $data_list
}

body StrategyResolutionBin::getDataName { a_datum } {
    return $names($a_datum)
}


body StrategyResolutionBin::isDatum { a_datum } {
    return [expr [lsearch $data_list $a_datum] > -1]
}

StrategyResolutionBin::initializeNames \
    percent_predicted "Predicted completeness (percent) by resolution" \
    standard_unique "Number of unique reflections by resolution" \
    predicted "Number of predicted reflections by resolution" \
    acentric_unique "Number of unique Bijvoet pairs by resolution" \
    generated_bijvoets "Number of predicted Bijvoet pairs by resolution" \
    percent_bijvoets "Predicted completeness of Bijvoet pairs by resolution"

body StrategyResolutionBin::constructor { a_method args } {
    if {$a_method == "mosflm"} {
	set high_resolution_limit [$args selectNodes normalize-space(high_resolution_limit)]
	set standard_unique [$args selectNodes normalize-space(standard_unique)]
	set predicted [$args selectNodes normalize-space(predicted)]
	set percent_predicted [$args selectNodes normalize-space(percent_predicted)]
	set acentric_unique [$args selectNodes normalize-space(acentric_unique)]
	set generated_bijvoets [$args selectNodes normalize-space(generated_bijvoets)]
	set percent_bijvoets [$args selectNodes normalize-space(percent_bijvoets)]
    }
}

class TestgenCalcDialog {
    inherit Dialog

    private variable osc_angle "Variable"
    private variable segment_phi ""
    private variable l_segment_phi
    private variable fixed_angle "0"
    private method ok
    private method cancel
    public method confirm

    constructor { args } { }
}

body TestgenCalcDialog::constructor { args } {

    .testgen configure -title "Check for Overlaps..."

    # Segment combo + label
    itk_component add segment_label {
	label $itk_interior.sl \
	    -text "Segment: "
    }

    itk_component add segment_combo {
	Combo $itk_interior.sc \
 		-textvariable [scope segment_phi] \
	    -width 16 \
	    -items {} \
	    -editable 0 \
	    -highlightcolor black
    }

    # Rotation combo + label
    itk_component add osc_angle_label {
	label $itk_interior.oscl \
	    -text "Osc. Angle: "
    }

    itk_component add osc_angle_combo {
	Combo $itk_interior.oscc \
	    -textvariable [scope osc_angle] \
	    -width 16 \
	    -items {Variable 0.1 0.2 0.3 0.4 0.5 1 2 3 4 5 6 7 8 9 10} \
	    -editable 1 \
	    -highlightcolor black
   }

    # Buttons
    itk_component add button_frame {
	frame $itk_interior.bf
    }

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "Ok" \
	    -width 7 \
	    -highlightbackground "#dcdcdc" \
	    -command [code $this ok]
    }

    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -highlightbackground "#dcdcdc" \
	    -command [code $this cancel] 
    }

    grid $itk_component(segment_label) $itk_component(segment_combo) -stick w
    grid $itk_component(osc_angle_label) $itk_component(osc_angle_combo) -stick w
    grid $itk_component(button_frame) - -sticky we
    pack $itk_component(ok) $itk_component(cancel) \
	-side right \
	-padx {0 7} \
	-pady 7
}

body TestgenCalcDialog::ok { } {
    $::mosflm runningTestgen
    $::mosflm sendCommand "[$::session getSeparationCommand]"

    set extract $segment_phi
    regsub {\-} $extract { } extract
    #puts $extract
    foreach {extract_start extract_end} $extract {
	if {$extract_start > $extract_end} {
		set extract_start "-[expr 360 % $extract_start]"
	}
    }
    if {$osc_angle == "Variable"} {
	$::mosflm sendCommand "testgen start $extract_start end $extract_end"		
	$::mosflm sendCommand "go"
	dismiss ""
    } else {
	$::mosflm sendCommand "testgen start $extract_start end $extract_end angle $osc_angle"	
	$::mosflm sendCommand "go"		
	dismiss ""
    }
}

body TestgenCalcDialog::cancel { } {
	dismiss ""
}

body TestgenCalcDialog::confirm { list_segment_phi } {
    set l_segment_phi $list_segment_phi
    $itk_component(segment_combo) configure -items $l_segment_phi
    set segment_phi [lindex $l_segment_phi 0]
    Dialog::confirm
}


class TestgenResult {

    # stratgey results
    private variable x_testgen_dataset {}
    private variable y_testgen_dataset {}
    private variable l_phi {}
    private variable l_range {}
    private variable testgendom ""
    public method parseTestgenDom
    public method getXDataset
    public method getYDataset

}

body TestgenResult::parseTestgenDom {a_dom} {
    set testgen_type [[$a_dom selectNodes {//range}] text]
    if {[[$a_dom selectNodes {//range}] text] == "fixed"} {
	foreach i_node [$a_dom selectNodes {//segment}] {
	    set phi_start [$i_node selectNodes normalize-space(oscillation_sequence/start)]
	    lappend l_phi $phi_start
	    set total_spots [$i_node selectNodes normalize-space(predicted_spots/total)]
	    set overlap_number [$i_node selectNodes normalize-space(predicted_spots/overlap/number)]
	    set overlap_percent [expr round((double($overlap_number)/$total_spots) * 100)]
	    lappend l_percent $overlap_percent
	}
	set x_testgen_dataset [namespace current]::[Dataset \#auto $l_phi [Unit::getUnit "\u00b0"] "Phi" "Phi"]
	set y_testgen_dataset [namespace current]::[Dataset \#auto $l_percent [Unit::getUnit ""] "Perc. Overlap" "Overlaps %"]
    } elseif {[[$a_dom selectNodes {//range}] text] == "variable"} {
	foreach i_node [$a_dom selectNodes {//oscillation_sequence}] {
	    set no_of_im [$i_node selectNodes normalize-space(number_of_images)]
	    set phi_start [$i_node selectNodes normalize-space(start)]
	    set phi_end [$i_node selectNodes normalize-space(end)]
	    set phi_osc [expr ($phi_end - $phi_start)/$no_of_im]
	    lappend l_phi $phi_start
	    lappend l_range $phi_osc
	    set testgen_i 1
	    while {$testgen_i < $no_of_im} {
		set phi_start [expr $phi_start + $phi_osc]
		lappend l_phi $phi_start
		lappend l_range $phi_osc
		incr testgen_i
	    }
	    set x_testgen_dataset [namespace current]::[Dataset \#auto $l_phi [Unit::getUnit "\u00b0"] "Phi segment" "Phi"]
	    set y_testgen_dataset [namespace current]::[Dataset \#auto $l_range [Unit::getUnit "\u00b0"] "\nMax Oscillation Angle" "Max Angle"]
	}
    } else {
	#
    }
    
    $::mosflm finishedTestgen
    
    return $testgen_type
}

body TestgenResult::getXDataset {} {
	return $x_testgen_dataset
}
body TestgenResult::getYDataset {} {
	return $y_testgen_dataset
}