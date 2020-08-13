when CLIENT_ACCEPTED {
  set peer_name "[IP::remote_addr]:[TCP::remote_port]"
  GENERICMESSAGE::peer name $peer_name
  log local0. "peername: [GENERICMESSAGE::peer name]"

  TCP::collect
}

when CLIENT_DATA {
  log local0. "-"
  set route_to ""
  set lines [split [TCP::payload] "\n"]
  set postpayload ""
  set postpayload_start 0
  foreach line $lines {
    if { $postpayload_start eq 1 } {
      append postpayload $line
    }
    set line [string trim $line]
    if { [string match *transaction_id* $line] } {
      set tid [lindex [split $line "\""] 3]
      set route_to [table lookup $tid]
    } elseif { $line eq "" } {
      set postpayload_start 1
      log local0. "postpayload_start -> 1"
    }
  }
  if { $route_to ne "" } {
    set msg "HTTP/1.1 200 OK\nContent-Type: application/json\nServer: BIG-IP\nConnection: keep-alive\nContent-Length: "
    append msg [string length $postpayload]
    append msg "\n\n"
    append msg $postpayload
    GENERICMESSAGE::message create $msg
    set payload "HTTP/1.1 200 OK\nContent-Type: application/json\n\n{\"transaction_id\": \"$tid\", \"result\": \"OK\"}\n\n"
  } else {
    set payload "HTTP/1.1 503 Service Unavailable\nContent-Type: application/json\n\n{\"transaction_id\": \"$tid\", \"result\": \"Error Service Unavailable\"}\n\n"
  }
  TCP::respond $payload
  TCP::payload replace 0 [TCP::payload length] ""
  TCP::release
  TCP::collect
}

when GENERICMESSAGE_INGRESS {
  log local0. "-"
  if { $route_to ne "" } {
    GENERICMESSAGE::message dst $route_to
    log local0. "GENERICMESSAGE::message src: [GENERICMESSAGE::message src] ; GENERICMESSAGE::message dst: [GENERICMESSAGE::message dst]"
  }
}

when MR_INGRESS {
  log local0. "-"
}

when MR_FAILED {
  log local0. "-"
}


