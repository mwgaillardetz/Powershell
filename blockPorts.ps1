New-NetFirewallRule -DisplayName "Block these particular ports" `
                    -Direction Inbound `
                    -LocalPort 10944,10945,10946,10947,10948,10949,10950 `
                    -Protocol TCP `
                    -Action Block
				
New-NetFirewallRule -DisplayName "Block these particular ports" `
                    -Direction Inbound `
                    -LocalPort 10944,10945,10946,10947,10948,10949,10950 `
                    -Protocol UDP `
                    -Action Block