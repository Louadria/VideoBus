--
--  File Name:         TbVideoBus_SendGet.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--  Some basic tests to show how the VideoBusRx and VideoBusTx VCs can be used
--  Based on OSVVM Framework
--
--
--
--  Revision History:
--    Date      Version    Description
--    08/2023   1.00       Initial revision

architecture SendGet of TestCtrl is
    signal sync1, TestDone : integer_barrier := 1;
    signal TbID : AlertLogIDType;

    signal TransmitFifo : ScoreboardIdType;
begin
    --------------------------------------------------
    -- ControlProc
    -- Set up AlertLog and wait for end of test
    --------------------------------------------------
    ControlProc : process
    begin
        -- Initialization of test
        SetTestName("TbVideoBus_SendGet");
        SetLogEnable(PASSED, TRUE);    -- Enable PASSED logs
        SetLogEnable(INFO, TRUE);    -- Enable INFO logs
        TbID <= NewID("Testbench");

        -- Wait for testbench initialization 
        wait for 0 ns ;  wait for 0 ns;
        TranscriptOpen(OSVVM_RESULTS_DIR & "TbVideoBus_SendGet.txt");
        SetTranscriptMirror(TRUE); 

        -- Wait for Design Reset
        wait until nReset = '1';  
        ClearAlerts;

        -- Wait for test to finish
        WaitForBarrier(TestDone, 35 ms);
        AlertIf(now >= 35 ms, "Test finished due to timeout");
        AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
        
        
        TranscriptClose; 

        EndOfTestReports; 
        std.env.stop; 
        wait; 
    end process ControlProc; 
    
    --------------------------------------------------
    -- ManagerProc
    -- Generate transactions for PatterngenManager
    --------------------------------------------------
    VideoBusTxProc : process
        variable ManagerId : AlertLogIDType;
        variable TransactionCount : integer;
        variable TxData : std_logic_vector(PIXEL_DEPTH-1 downto 0);
        variable RV : RandomPType;
    begin
        wait until nReset = '1';
        -- First Alignment to clock
        WaitForClock(VideoBusTxTransRec, 1);
        ManagerId := NewID("VideoBusTransmitter", TbID);

        -- Init TransmitFifo
        TransmitFifo <= NewID("TransmitFifo", TbID, ReportMode => DISABLED, Search => PRIVATE_NAME);

        -- Send red frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                TxData := 24X"FF0000";
                Send(VideoBusTxTransRec, TxData);
            end loop;
        end loop;

        -- Send green frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                TxData := 24X"00FF00";
                Send(VideoBusTxTransRec, TxData);
            end loop;
        end loop;

        -- Send blue frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                TxData := 24X"0000FF";
                Send(VideoBusTxTransRec, TxData);
            end loop;
        end loop;

        -- Send random frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                TxData := RV.RandSlv(24);
                Push(TransmitFifo, TxData);
                Send(VideoBusTxTransRec, TxData);
            end loop;
        end loop;

        GetTransactionCount(VideoBusTxTransRec, TransactionCount);
        AffirmIfEqual(ManagerId, TransactionCount, 4 * VIDEO_HEIGHT * VIDEO_WIDTH, "Transaction Count");

--        WaitForBarrier(sync1);

        -- End of test
        WaitForBarrier(TestDone);
        wait ;
    end process VideoBusTxProc;


    VideoBusRxProc : process
        variable ManagerId : AlertLogIDType;
        variable TransactionCount : integer;
        variable RxData : std_logic_vector(PIXEL_DEPTH-1 downto 0);

        variable TransmitFifoRxData : std_logic_vector(PIXEL_DEPTH-1 downto 0);
    begin
        wait until nReset = '1';
        -- First Alignment to clock
        WaitForClock(VideoBusRxTransRec, 1);
        ManagerId := NewID("VideoBusReceiver", TbID);
        SetLogEnable(PASSED, FALSE);    -- Disable PASSED logs

 --       WaitForBarrier(sync1);

        -- Receive red frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                Get(VideoBusRxTransRec, RxData);
                AffirmIfEqual(ManagerId, RxData, 24X"FF0000", "VideoBus Data");
            end loop;
        end loop;

        -- Receive green frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                Get(VideoBusRxTransRec, RxData);
                AffirmIfEqual(ManagerId, RxData, 24X"00FF00", "VideoBus Data");
            end loop;
        end loop;

        -- Receive blue frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                Get(VideoBusRxTransRec, RxData);
                AffirmIfEqual(ManagerId, RxData, 24X"0000FF", "VideoBus Data");
            end loop;
        end loop;

        -- Receive random frame
        for i in 1 to VIDEO_HEIGHT loop
            for j in 1 to VIDEO_WIDTH loop
                Get(VideoBusRxTransRec, RxData);
                TransmitFifoRxData := Pop(TransmitFifo);
                AffirmIfEqual(ManagerId, RxData, TransmitFifoRxData, "VideoBus Data");
            end loop;
        end loop;

        GetTransactionCount(VideoBusRxTransRec, TransactionCount);
        AffirmIfEqual(ManagerId, TransactionCount, 4 * VIDEO_HEIGHT * VIDEO_WIDTH, "Transaction Count");

        WaitForClock(VideoBusRxTransRec, 20);

        -- End of test
        WaitForBarrier(TestDone);
        wait ;
    end process VideoBusRxProc;
end SendGet;

Configuration TbVideoBus_SendGet of TbVideoBus is
    for TestHarness
        for TestCtrl_1 : TestCtrl
            use entity work.TestCtrl(SendGet);
        end for;
    end for;
end TbVideoBus_SendGet;