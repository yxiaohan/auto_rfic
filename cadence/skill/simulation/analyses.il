;; analyses.il - Analysis configuration for auto_rfic
;; This file contains functions for configuring and running different types of analyses

;; Initialize the analyses namespace
unless(boundp('autoRficAnalyses)
    autoRficAnalyses = makeTable("analyses" nil)
)

;; Function to configure AC analysis
procedure(autoRficConfigureAcAnalysis(state params)
    prog((result start stop dec)
        start = if(member('start params) params->start 1)  ; Default 1Hz
        stop = if(member('stop params) params->stop 1e9)   ; Default 1GHz
        dec = if(member('dec params) params->dec 20)       ; Default 20 points/decade
        
        ;; Add AC analysis to state
        result = adeAddAnalysis(state "ac"
            ?start start
            ?stop stop
            ?dec dec
            ?oprobe if(member('oprobe params) params->oprobe nil)
            ?iprobe if(member('iprobe params) params->iprobe nil)
            ?detail if(member('detail params) params->detail "conservative")
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured AC analysis: %g Hz to %g Hz" start stop))
        )
        result
    )
)

;; Function to configure DC analysis
procedure(autoRficConfigureDcAnalysis(state params)
    prog((result paramName start stop step)
        paramName = if(member('param params) params->param "v1")
        start = if(member('start params) params->start 0)
        stop = if(member('stop params) params->stop 5)
        step = if(member('step params) params->step 0.1)
        
        ;; Add DC analysis to state
        result = adeAddAnalysis(state "dc"
            ?param paramName
            ?start start
            ?stop stop
            ?step step
            ?detail if(member('detail params) params->detail "conservative")
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured DC sweep of %s: %g to %g" paramName start stop))
        )
        result
    )
)

;; Function to configure transient analysis
procedure(autoRficConfigureTransientAnalysis(state params)
    prog((result stop step)
        stop = if(member('stop params) params->stop 1e-6)   ; Default 1us
        step = if(member('step params) params->step 1e-9)   ; Default 1ns
        
        ;; Add transient analysis to state
        result = adeAddAnalysis(state "tran"
            ?stop stop
            ?step step
            ?errpreset if(member('errpreset params) params->errpreset "conservative")
            ?method if(member('method params) params->method "trap")
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured transient analysis: stop=%g, step=%g" stop step))
        )
        result
    )
)

;; Function to configure S-parameter analysis
procedure(autoRficConfigureSpAnalysis(state params)
    prog((result start stop dec ports)
        start = if(member('start params) params->start 100e6)   ; Default 100MHz
        stop = if(member('stop params) params->stop 10e9)       ; Default 10GHz
        dec = if(member('dec params) params->dec 20)            ; Default 20 points/decade
        ports = if(member('ports params) params->ports 2)       ; Default 2-port
        
        ;; Add SP analysis to state
        result = adeAddAnalysis(state "sp"
            ?start start
            ?stop stop
            ?dec dec
            ?ports ports
            ?osdi t
            ?save t
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured S-parameter analysis: %g Hz to %g Hz" start stop))
        )
        result
    )
)

;; Function to configure noise analysis
procedure(autoRficConfigureNoiseAnalysis(state params)
    prog((result start stop dec output input)
        start = if(member('start params) params->start 100e6)   ; Default 100MHz
        stop = if(member('stop params) params->stop 10e9)       ; Default 10GHz
        dec = if(member('dec params) params->dec 20)            ; Default 20 points/decade
        output = if(member('output params) params->output "out")
        input = if(member('input params) params->input "in")
        
        ;; Add noise analysis to state
        result = adeAddAnalysis(state "noise"
            ?start start
            ?stop stop
            ?dec dec
            ?output output
            ?input input
            ?save t
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured noise analysis: %g Hz to %g Hz" start stop))
        )
        result
    )
)

;; Function to configure harmonic balance analysis
procedure(autoRficConfigureHbAnalysis(state params)
    prog((result fund nharm order)
        fund = if(member('fund params) params->fund 1e9)      ; Default 1GHz
        nharm = if(member('nharm params) params->nharm 10)    ; Default 10 harmonics
        order = if(member('order params) params->order 7)     ; Default 7th order
        
        ;; Add HB analysis to state
        result = adeAddAnalysis(state "hb"
            ?fund fund
            ?nharm nharm
            ?order order
            ?errpreset if(member('errpreset params) params->errpreset "conservative")
            ?save t
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured HB analysis: f=%g Hz, %d harmonics" fund nharm))
        )
        result
    )
)

;; Function to configure PSS analysis
procedure(autoRficConfigurePssAnalysis(state params)
    prog((result fund nharm order tstab)
        fund = if(member('fund params) params->fund 1e9)      ; Default 1GHz
        nharm = if(member('nharm params) params->nharm 10)    ; Default 10 harmonics
        order = if(member('order params) params->order 7)     ; Default 7th order
        tstab = if(member('tstab params) params->tstab 10)   ; Default 10 periods
        
        ;; Add PSS analysis to state
        result = adeAddAnalysis(state "pss"
            ?fund fund
            ?nharm nharm
            ?order order
            ?tstab tstab
            ?errpreset if(member('errpreset params) params->errpreset "moderate")
            ?save t
        )
        
        when(result
            autoRficLogInfo(sprintf(nil "Configured PSS analysis: f=%g Hz, %d harmonics" fund nharm))
        )
        result
    )
)

;; Main function to configure any type of analysis
procedure(autoRficConfigureAnalysis(state analysisType params)
    case(analysisType
        ("ac"
            autoRficConfigureAcAnalysis(state params))
        ("dc"
            autoRficConfigureDcAnalysis(state params))
        ("tran" 
            autoRficConfigureTransientAnalysis(state params))
        ("sp"
            autoRficConfigureSpAnalysis(state params))
        ("noise"
            autoRficConfigureNoiseAnalysis(state params))
        ("hb"
            autoRficConfigureHbAnalysis(state params))
        ("pss"
            autoRficConfigurePssAnalysis(state params))
        (t
            autoRficLogError(sprintf(nil "Unknown analysis type: %s" analysisType))
            nil)
    )
)

;; Add functions to namespace
when(boundp('autoRficAnalyses)
    autoRficAnalyses['configureAc] = 'autoRficConfigureAcAnalysis
    autoRficAnalyses['configureDc] = 'autoRficConfigureDcAnalysis
    autoRficAnalyses['configureTran] = 'autoRficConfigureTransientAnalysis
    autoRficAnalyses['configureSp] = 'autoRficConfigureSpAnalysis
    autoRficAnalyses['configureNoise] = 'autoRficConfigureNoiseAnalysis
    autoRficAnalyses['configureHb] = 'autoRficConfigureHbAnalysis
    autoRficAnalyses['configurePss] = 'autoRficConfigurePssAnalysis
    autoRficAnalyses['configure] = 'autoRficConfigureAnalysis
)

;; Export the analyses namespace
autoRficAnalyses
