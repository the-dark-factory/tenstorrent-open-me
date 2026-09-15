#!/usr/bin/env bb
;; probe.bb — THIN SHIM for the Fma_Diff_Main edge. It decides NOTHING.
;; It runs ./fma_diff_main three times (real 20 000 000 random + grid; mutant; no arguments),
;; copies the raw fields it printed, and pipes them to the forged verdict edge over the PROVEN
;; core Fma_Diff_Verdict_Pkg (../wu-bh-fma-diff-verdict-edge/fma_diff_verdict_main).
;; This script's exit status is that edge's exit status — the proven core's verdict.
;; A missing field is passed as "x", which the verdict edge cannot parse, so it fails closed.
(require '[babashka.process :refer [process]]
         '[clojure.string :as str])

(def bin "./fma_diff_main")
(def verdict-bin "../wu-bh-fma-diff-verdict-edge/fma_diff_verdict_main")

(defn run [args timeout-ms]
  @(process (into [bin] args) {:out :string :err :string :timeout timeout-ms}))

(defn field [out prefix]
  (or (some (fn [l] (when (str/starts-with? l (str prefix " "))
                      (str/trim (subs l (inc (count prefix))))))
            (str/split-lines (or out "")))
      "x"))

(defn class-field [out k]
  (let [words (str/split (field out "CLASSES") #"\s+")
        m     (apply hash-map (if (even? (count words)) words []))]
    (get m k "x")))

(defn exit-flag [r want-zero]
  (str (if want-zero
         (if (= 0 (:exit r)) 1 0)
         (if (= 0 (:exit r)) 0 1))))

(let [real (run ["20000000"] 1800000)
      mut  (run ["1000" "mutant"] 300000)
      none (run [] 30000)
      lines [(exit-flag real true)
             (field (:out real) "CHECKED") "20064000" (field (:out real) "MISMATCHES")
             (class-field (:out real) "nan") (class-field (:out real) "inf")
             (class-field (:out real) "zero") (class-field (:out real) "finite")
             (exit-flag mut false)
             (field (:out mut) "CHECKED") "65000" (field (:out mut) "MISMATCHES")
             (exit-flag none false)
             (str (if (str/includes? (or (:out none) "") "usage: fma_diff_main") 1 0))]
      v @(process [verdict-bin] {:in (str (str/join "\n" lines) "\n") :out :string :err :string})]
  (println "fed to verdict core:" (str/join " " lines))
  (print (:out v))
  (flush)
  (when-not (str/blank? (:err v)) (println (:err v)))
  (System/exit (:exit v)))
