options( "device" = "quartz" )

setHook(packageEvent("grDevices", "onLoad"),
        function(...) grDevices::quartz.options(width=4, height=4))

options(prompt="R> ", digits=4, show.signif.stars=FALSE)

options(repos=structure(c(CRAN="https://cloud.r-project.org/")))
