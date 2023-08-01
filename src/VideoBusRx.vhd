-- Verification Component to receive on a VideoBus interface 

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
    use work.VideoBusRxPkg.all;

entity VideoBusRx is
    generic (
        MODEL_ID_NAME    : string := "";
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
        vid_fval_in    : in  std_logic;
        vid_lval_in    : in  std_logic;
        vid_dval_in    : in  std_logic;
        vid_data_in    : in  VideoDataArray(0 to NUM_DATA_STREAMS-1)(PIXEL_DEPTH-1 downto 0);

        -- Testbench Transaction Interface
        TransRec    : InOut StreamRecType
    );

    -- Derive ModelInstance label from path_name
    constant MODEL_INSTANCE_NAME : string :=
        -- use MODEL_ID_NAME Generic if set, otherwise use instance label (preferred if set as entityname_1)
        IfElse(MODEL_ID_NAME /= "", MODEL_ID_NAME, to_lower(PathTail(VideoBusRx'PATH_NAME)));

end entity VideoBusRx;
architecture SimpleBlockingReceive of VideoBusRx is
    signal ModelID : AlertLogIDType;

    -- RecieveFifo which contains received frames
    signal ReceiveFifo : ScoreboardIdType;

    -- Number of received frames
    signal ReceiveCount : integer := 0;  
begin

    --------------------------------------------------------------------
    -- Initialize alerts
    --------------------------------------------------------------------
    Initialize : process
        variable ID : AlertLogIDType;
    begin
        -- Alerts
        ID := NewID(MODEL_INSTANCE_NAME);
        ModelID <= ID;
        ReceiveFifo <= NewID("ReceiveFifo", ID, ReportMode => DISABLED, Search => PRIVATE_NAME);
        wait;
    end process Initialize;

    --------------------------------------------------------------------
    -- Transaction Handler
    -- Decodes transactions and Handlers DUT interface
    --------------------------------------------------------------------
    TransactionHandler : process
        alias operation : StreamOperationType is TransRec.Operation;

        variable RxData : std_logic_vector(TransRec.DataFromModel'range);
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
                when GET =>
                    TransRec.BoolFromModel <= TRUE;
                    if (Empty(ReceiveFifo)) then
                        -- Wait for data
                        WaitForToggle(ReceiveCount);
                    else 
                        -- Settling for when not Empty at current time, but ReceiveCount not updated yet
                        -- ReceiveCount used in reporting below.
                        wait for 0 ns;
                    end if;
                    -- Put Data into record
                    RxData := Pop(ReceiveFifo);
                    TransRec.DataFromModel <= SafeResize(RxData,  TransRec.DataFromModel'length); 

                    Log(ModelID, 
                        "Received: " & to_hxstring(RxData) & 
                        ".  Operation # " & to_string(ReceiveCount),
                        DEBUG, 
                        Enable => TransRec.BoolToModel); 

                -- Execute Standard Directive Transactions
                when WAIT_FOR_TRANSACTION =>
                    if Empty(ReceiveFifo) then 
                        WaitForToggle(ReceiveCount);
                    end if; 

                when WAIT_FOR_CLOCK =>
                    WaitForClock(Clk, TransRec.IntToModel); --WaitForClock stops the VC for the specified number of clocks
                
                when GET_ALERTLOG_ID =>
                    TransRec.IntFromModel <= integer(ModelID); -- GetAlertLogID looks up the AlertLogID of the VC and returns it
                
                when GET_TRANSACTION_COUNT =>
                    TransRec.IntFromModel <= ReceiveCount;

                when MULTIPLE_DRIVER_DETECT =>
                    Alert(ModelID, "Multiple Drivers on Transaction Record." & 
                                    "  Transaction # " & to_string(TransRec.Rdy), FAILURE);
                when others =>
                    Alert(ModelID, "Unimplemented Transaction: " & to_string(Operation), FAILURE);

            end case;
        end loop;
    end process TransactionHandler;

------------------------------------------------------------
-- Fval / Lval / Dval Checker
------------------------------------------------------------
VideoBusLineChecker : process(vid_dval_in, vid_lval_in, vid_fval_in)
begin 
    AlertIf(ModelID, (vid_dval_in='1' and not (vid_lval_in='1' and vid_fval_in='1')), 
    "vid_dval_in high while vid_lval_in or vid_fval_in low!", FAILURE);
    AlertIf(ModelID, (vid_lval_in='1' and not vid_fval_in='1'), 
    "vid_lval_in high while vid_fval_in low!", FAILURE);
end process VideoBusLineChecker;

------------------------------------------------------------
-- VideoBus Receive Logic + Checks if number of pixel in line / number of lines are correct
------------------------------------------------------------
 VideoBusHandler : process
    variable RxData : std_logic_vector(TransRec.DataFromModel'range);
    variable pixelCount : integer;
    variable lineCount : integer;
begin 
    wait for 0 ns; -- Allow ModelID to become valid
    SetLogEnable(ModelID, PASSED, false); -- don't log passed affirmations
    
    wait until rising_edge(vid_fval_in);
    Log(ModelID, "New frame started in VideoBusRx!", INFO); 
    pixelCount := 0;
    lineCount := 0;
    while (vid_fval_in = '1') loop
        wait until rising_edge(Clk);
        if (vid_lval_in = '1') then
            pixelCount := 0;
            while (vid_lval_in = '1') loop
                wait until rising_edge(Clk);
                if (vid_dval_in = '1') then
                    for dataStream in 0 to NUM_DATA_STREAMS-1 loop
                        RxData := vid_data_in(dataStream);
                        Push(ReceiveFifo, RxData);
                        Increment(ReceiveCount);
                        pixelCount := pixelCount + 1;
                    end loop;
                end if;
            end loop;
            AffirmIf(ModelID, (pixelCount = VIDEO_WIDTH), "pixelCount ?= VIDEO_WIDTH");
            -- Fill missing pixels
            for i in 1 to (VIDEO_WIDTH - pixelCount) loop 
                RxData := (others => 'U');
                Push(ReceiveFifo, RxData);
                Increment(ReceiveCount);
            end loop;
            lineCount := lineCount + 1;
        end if;
    end loop;
    AffirmIf(ModelID, (lineCount = VIDEO_HEIGHT), "lineCount ?= VIDEO_HEIGHT");
    -- Fill missing pixels
    for j in 1 to (VIDEO_HEIGHT - lineCount) loop
        for i in 1 to VIDEO_WIDTH loop
            RxData := (others => 'U');
            Push(ReceiveFifo, RxData);
            Increment(ReceiveCount);
        end loop;   
    end loop;
end process VideoBusHandler;

end architecture SimpleBlockingReceive;