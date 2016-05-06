{:user
 {:plugins       [[cider/cider-nrepl                  "0.8.2"]
                  [com.jakemccrary/lein-test-refresh  "0.11.0"]
                  [jonase/eastwood                    "0.2.3"]
                  [lein-ancient                       "0.6.8"]]

  :dependencies  [[clj-stacktrace   "0.2.8"]
                  [spyscope         "0.1.5"]]

  :injections    [(let [orig (ns-resolve (doto 'clojure.stacktrace require)
                                         'print-cause-trace)
                        new (ns-resolve (doto 'clj-stacktrace.repl require)
                                        'pst)]
                    (alter-var-root orig (constantly (deref new))))
                  (require 'spyscope.core)]}}}
