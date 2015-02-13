; strings.s
; Collection of messages used in stage 2.

%ifndef __STRINGS_S
%define __STRINGS_S


; First some debug stuff
; Something to print for simple debugging
msg_debug                    db "DEBUG", 0x0a, 0x00
; 20 bytes of data that can be sent to extend
testhash                     db "01234567890123456789"

; Characters to print
char_space                   db " ", 0x00
char_newline                 db 0x0a, 0x00


; Fail messages
msg_fail_pcr_read            db "Failed to read PCR", 0x0a, 0x00
msg_fail_pcr_extend          db "Failed to extend PCR", 0x0a, 0x00
msg_fail_pcr_reset           db "Failed to reset PCR", 0x0a, 0x00
msg_fail_tpm_find            db "No TPM on the system", 0x0a, 0x00
msg_fail_tpm_access          db "Unable to get access to locality", 0x0a, 0x00




; Success messages
msg_succ_tpm_find            db "Found TPM", 0x0a, 0x00




%endif
