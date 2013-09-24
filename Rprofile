options( "device" = "quartz" )

setHook(packageEvent("grDevices", "onLoad"),
        function(...) grDevices::quartz.options(width=4, height=4))

options(prompt="R> ", digits=4, show.signif.stars=FALSE)

options(repos=structure(c(CRAN="http://cran.cnr.berkeley.edu/")))
