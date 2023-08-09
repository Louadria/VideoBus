onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/Clk
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/vid_fval_out
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/vid_lval_out
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/vid_dval_out
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/vid_data_out
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/TransRec
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/ModelID
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/TransmitFifo
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/TransmitRequestCount
add wave -noupdate -expand -group VideoBusTx /tbvideobus/VideoBusTx_1/TransmitDoneCount
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/Clk
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/vid_fval_in
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/vid_lval_in
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/vid_dval_in
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/vid_data_in
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/TransRec
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/ModelID
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/ReceiveFifo
add wave -noupdate -expand -group VideoBusRx /tbvideobus/VideoBusRx_1/ReceiveCount
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/nReset
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/VideoBusRxTransRec
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/VideoBusTxTransRec
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/sync1
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/TestDone
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/TbID
add wave -noupdate -expand -group TestCtrl /tbvideobus/TestCtrl_1/TransmitFifo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {117319 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {3874034 ps}
