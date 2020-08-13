when SERVER_CONNECTED {
  set peer_name "[IP::remote_addr]:[TCP::remote_port]"
  GENERICMESSAGE::peer name $peer_name
  log local0. "peername: [GENERICMESSAGE::peer name]"

  TCP::collect
}

when SERVER_DATA {
  log local0. "-"
  set lines [split [TCP::payload] "\n"]
  if { [string match "HTTP/*" [lindex $lines 0]] } {
    set rcs [split [lindex $lines 0] " "]
    if { [lindex $rcs 1] eq "200" } {
      TCP::payload replace 0 [TCP::payload length] ""
    } else {
      GENERICMESSAGE::message create [TCP::payload]
      set route_to ""
      foreach line $lines {
        set line [string trim $line]
        log local0. "line: $line"
        if { [string match *transaction_id* $line] } {
          set tid [lindex [split $line "\""] 3]
          set route_to [table lookup $tid]
          log local0. "tid $tid -> $route_to"
        }
      }
    }
  }
  TCP::release
  TCP::collect
}

#when SERVER_CLOSED { 
#  log local0. "-"
#}

when GENERICMESSAGE_INGRESS {
  log local0. "- route_to: $route_to"
  if { $route_to ne "" } {
    GENERICMESSAGE::message dst $route_to
    log local0. "GENERICMESSAGE::message src: [GENERICMESSAGE::message src] ; GENERICMESSAGE::message dst: [GENERICMESSAGE::message dst]"
  }
}

when GENERICMESSAGE_EGRESS {
  log local0. "-"
  log local0. "GENERICMESSAGE::message src: [GENERICMESSAGE::message src] ; GENERICMESSAGE::message dst: [GENERICMESSAGE::message dst]"
  TCP::respond [GENERICMESSAGE::message data]
}

when MR_INGRESS {
  log local0. "-"
  log local0. "MR::message route: [MR::message route]"
}

when MR_EGRESS {
  log local0. "-"
}

when MR_FAILED {
  log local0. "-"

}


