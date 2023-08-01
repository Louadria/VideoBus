--
--  File Name:         VideoBusTx.vhd
--
--  Maintainer:        Louis Adriaens      email:  louisadriaens@outlook.com
--  Contributor(s):
--     Louis Adriaens      louisadriaens@outlook.com
--
--
--  Description:
--  Verification Component to transmit on a VideoBus interface 
--  Based on OSVVM Framework
--
--
--
--  Revision History:
--    Date      Version    Description
--    08/2023   1.00       Initial revision

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.numeric_std_unsigned.all;
    use ieee.math_real.all;

library osvvm;
    context osvvm.OsvvmContext;
    use osvvm.ScoreboardPkg_slv.all;

library osvvm_common;
    context osvvm_common.OsvvmCommonContext;

library work;
    use work.VideoBusTxPkg.all;

entity VideoBusTx is
    generic (
        MODEL_ID_NAME    : string := "";
        DEFAULT_DELAY    : time := 1 ns; -- used for tpd (Total Propagation Delay)
        VIDEO_HEIGHT     : natural := 64;  -- number of lines in a frame
        VIDEO_WIDTH      : natural := 64;  -- number of pixels in a line
        PIXEL_DEPTH      : natural := 24;    -- number of bits in a pixel
        NUM_DATA_STREAMS : natural := 1
    );
    port (
        -- Globals
        Clk     : in std_logic;

        -- VideoBus Functional Interface
        -- VideoBus Receiver: input
        vid_fval_out    : out  std_logic;
        vid_lval_out    : out  std_logic;
        vid_dval_out    : out  std_logic;
        vid_data_out    : out  VideoDataArray(0 to NUM_DATA_STREAMS-1)(PIXEL_DEPTH-1 downto 0);

        -- Testbench Transaction Interface
        TransRec    : InOut StreamRecType
    );

    -- Derive ModelInstance label from path_name
    constant MODEL_INSTANCE_NAME : string :=
        -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
        IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, to_lower(PathTail(VideoBusTx'PATH_NAME)));

    -- Model Configuration
    -- Access via transactions or external name
    shared variable Params : ModelParametersPType;

end entity VideoBusTx;
architecture SimpleBlockingReceive of VideoBusTx is
    signal ModelID : AlertLogIDType;

    signal TransmitFifo : ScoreboardIdType;

    signal TransmitRequestCount, TransmitDoneCount : integer := 0;
begin

    --------------------------------------------------------------------
    -- Initialize alerts
    --------------------------------------------------------------------
    Initialize : process
        variable ID : AlertLogIDType;
    begin
        -- Init options
        Params.Init(VideoBusOptionsType'pos(OPTIONS_MARKER));
        Params.Set(VideoBusOptionsType'pos(FVAL_GUARD_CYCLES), 1);
        Params.Set(VideoBusOptionsType'pos(LVAL_GUARD_CYCLES), 1);
        Params.Set(VideoBusOptionsType'pos(DVAL_GUARD_CYCLES), 1);

        -- Alerts
        ID := NewID(MODEL_INSTANCE_NAME);
        ModelID <= ID;
        TransmitFifo <= NewID("TransmitFifo", ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
        wait;
    end process Initialize;

    --------------------------------------------------------------------
    -- Transaction Handler
    -- Decodes transactions and Handlers DUT interface
    --------------------------------------------------------------------
    TransactionHandler : process
        alias operation : StreamOperationType is TransRec.Operation;

        variable TxData : std_logic_vector(TransRec.DataFromModel'range);

        variable VideoBusOption : VideoBusOptionsType;
    begin
        wait for 0 ns; -- Allow ModelID to become valid

        loop
            WaitForTransaction(
                Clk => Clk,
                Rdy => TransRec.Rdy,
                Ack => TransRec.Ack
            );
        
            case operation is
                -- Model Transaction Dispatch
                when SEND =>
                    TxData := SafeResize(TransRec.DataToModel, TxData'length);
                    Push(TransmitFifo, TxData);
                    Log(ModelID,
                        "SEND Queueing Transaction: " & to_hxstring(TxData) &
                        "  Operation # " & to_string(TransmitRequestCount + 1),
                        DEBUG, 
                        Enable => TransRec.BoolToModel
                    );
                    Increment(TransmitRequestCount);
                    wait until TransmitRequestCount = TransmitDoneCount;

                -- Execute Standard Directive Transactions
                when WAIT_FOR_TRANSACTION =>
                    if TransmitRequestCount /= TransmitDoneCount then 
                        wait until TransmitRequestCount = TransmitDoneCount;
                    end if; 

                when WAIT_FOR_CLOCK =>
                    WaitForClock(Clk, TransRec.IntToModel); --WaitForClock stops the VC for the specified number of clocks
                
                when GET_ALERTLOG_ID =>
                    TransRec.IntFromModel <= integer(ModelID); -- GetAlertLogID looks up the AlertLogID of the VC and returns it
                
                when GET_TRANSACTION_COUNT =>
                    TransRec.IntFromModel <= TransmitDoneCount;

                when SET_MODEL_OPTIONS =>
                    VideoBusOption := VideoBusOptionsType'val(TransRec.Options);
                    case VideoBusOption is
                        when FVAL_GUARD_CYCLES =>
                            Params.Set(VideoBusOptionsType'pos(FVAL_GUARD_CYCLES), TransRec.IntToModel);
                        when LVAL_GUARD_CYCLES =>
                            Params.Set(VideoBusOptionsType'pos(LVAL_GUARD_CYCLES), TransRec.IntToModel);
                        when DVAL_GUARD_CYCLES =>
                            Params.Set(VideoBusOptionsType'pos(DVAL_GUARD_CYCLES), TransRec.IntToModel);
                        when others =>
                            Alert(ModelID, "SetOptions, Unimplemented Option: " & to_string(VideoBusOptionsType'val(TransRec.Options)), FAILURE);
                    end case;

                when MULTIPLE_DRIVER_DETECT =>
                    Alert(ModelID, "Multiple Drivers on Transaction Record." & 
                                    "  Transaction # " & to_string(TransRec.Rdy), FAILURE);
                when others =>
                    Alert(ModelID, "Unimplemented Transaction: " & to_string(Operation), FAILURE);

            end case;
        end loop;
    end process TransactionHandler;

    ------------------------------------------------------------
    -- VideoBus Transmit Logic
    ------------------------------------------------------------
    VideoBusTransmitHandler : process
        variable TxData : std_logic_vector(TransRec.DataFromModel'range);
        variable pixelCount : integer := 0;
        variable lineCount : integer := 0;

        variable LvalGuardCycles : integer; 
        variable DvalGuardCycles : integer;
        variable FvalGuardCycles : integer;
    begin 
        -- Initialize
        vid_fval_out <= '0';
        vid_lval_out <= '0';
        vid_dval_out <= '0';
        for dataStream in 0 to NUM_DATA_STREAMS-1 loop
            vid_data_out(dataStream) <= (others => 'X');
        end loop;

        wait for 0 ns; -- Allow ModelID to become valid

        TransmitLoop : loop
                -- Find Transaction
            if Empty(TransmitFifo) then
                WaitForToggle(TransmitRequestCount);
            else 
                wait for 0 ns; -- allow TransmitRequestCount to settle if both happen at same time.
            end if;

            TxData := Pop(TransmitFifo);
            GetVideoBusParameter(Params, FVAL_GUARD_CYCLES, FvalGuardCycles);
            GetVideoBusParameter(Params, LVAL_GUARD_CYCLES, LvalGuardCycles);
            GetVideoBusParameter(Params, DVAL_GUARD_CYCLES, DvalGuardCycles);

            Log(ModelID, 
                "SEND Starting: " & to_string(TxData) & 
                "  Operation # " & to_string(TransmitRequestCount),
                DEBUG
            );

            -- SOF
            if (lineCount = 0 and pixelCount = 0) then
                vid_fval_out <= '1' after DEFAULT_DELAY;

                WaitForClock(Clk, LvalGuardCycles);
            end if;

            -- SOL
            if (pixelCount = 0) then
                vid_lval_out <= '1' after DEFAULT_DELAY;

                WaitForClock(Clk, DvalGuardCycles);
            end if;

            vid_dval_out <= '1' after DEFAULT_DELAY;
            
            for dataStream in 0 to NUM_DATA_STREAMS-1 loop
                vid_data_out(dataStream) <= TxData after DEFAULT_DELAY;
            end loop;

            wait until rising_edge(Clk);

            vid_dval_out <= '0' after DEFAULT_DELAY;
            
            for dataStream in 0 to NUM_DATA_STREAMS-1 loop
                vid_data_out(dataStream) <= (others => 'X') after DEFAULT_DELAY;
                pixelCount := pixelCount + 1;
                Increment(TransmitDoneCount);
            end loop;

            -- EOL
            if (pixelCount = VIDEO_WIDTH) then
                WaitForClock(Clk, DvalGuardCycles);

                vid_lval_out <= '0' after DEFAULT_DELAY;
                lineCount := lineCount + 1;
                pixelCount := 0;

                WaitForClock(Clk, LvalGuardCycles);
            end if;

            -- EOF
            if (lineCount = VIDEO_HEIGHT) then
                vid_fval_out <= '0' after DEFAULT_DELAY;
                lineCount := 0;

                WaitForClock(Clk, FvalGuardCycles);
            end if;

        end loop;
    end process VideoBusTransmitHandler;

end architecture SimpleBlockingReceive;