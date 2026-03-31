require 'grok-pure'

grok = Grok.new
grok.add_patterns_from_file("/usr/share/logstash/vendor/bundle/jruby/3.1.0/gems/logstash-patterns-core-4.3.4/patterns/grok-patterns") # Just manually compiling the regex for testing.

pattern = "(?:<%{POSINT}>)?%{SYSLOGTIMESTAMP:timestamp} (?:%{SYSLOGHOST:hostname} )?filterlog(?:\[%{POSINT}\])?: %{GREEDYDATA:filter_message}"
log_line = "<134>Mar 27 10:56:39 filterlog[32034]: 4,,,1000000103,vtnet1,match,block,in,4,0x0,,64,4562,0,DF,6,tcp,76,192.168.1.101,87.10.222.251,49062,8123,24,FPA,3193369621:3193369645,4221867066,166,,nop;nop;TS"

# I'll use ruby regex directly to test the grok translation:
# POSINT: \b(?:[1-9][0-9]*)\b
# SYSLOGTIMESTAMP: %{MONTH} +%{MONTHDAY} %{TIME}
