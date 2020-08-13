when CLIENT_ACCEPTED {
  set peer_name "[IP::remote_addr]:[TCP::remote_port]"
  GENERICMESSAGE::peer name $peer_name
  log local0. "peername: [GENERICMESSAGE::peer name]"

  TCP::collect
}

when CLIENT_DATA {
  log local0. "-"
  GENERICMESSAGE::message create [TCP::payload]
  set lines [split [TCP::payload] "\n"]
  foreach line $lines {
    set line [string trim $line]
    if { [string match *transaction_id* $line] } {
      set tid [lindex [split $line "\""] 3]
      table set $tid $peer_name
      set test_peer_name [table lookup $tid]
      log local0. "tid $tid -> $test_peer_name"
    }
  }
  TCP::release
  TCP::collect
}

when GENERICMESSAGE_INGRESS {
  log local0. "-"
}

when GENERICMESSAGE_EGRESS {
  log local0. "GENERICMESSAGE::message src: [GENERICMESSAGE::message src] ; GENERICMESSAGE::message dst: [GENERICMESSAGE::message dst]"
  TCP::respond [GENERICMESSAGE::message data]
}

when MR_INGRESS {
  MR::message route peer peer-lora
}

when MR_EGRESS {
  log local0. "-"
}

when MR_FAILED {
  log local0. "-"
}


