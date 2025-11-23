#!/bin/bash
set -e
export PATH=$PATH:/sbin:/usr/sbin

rustdesk --option custom-rendezvous-server wg.bunzserv.com
rustdesk --option key HeyTPFt+SXUJBRYLVmlL7+tLplqlFOUAySpKlx3Fw7E=
rustdesk --get-id