
Library ieee;
use ieee.std_logic_1164.all;
use work.regFilePackage.all;

entity DecodeStage is
	port( IR, Imm_val : IN std_logic_vector(15 downto 0);
	      clk, stallAll, Branch, rst, interrupt, WriteReg, enableFU, enableHU , falseprediction, wb_excute ,IDEX_MemRead, stallfromFetch: IN std_logic;
	      Rwrite, Add_BR_Reg,ID_EX_Rdst,Exec_Rdst: IN std_logic_vector(2 downto 0);
	      
	      writeData, DataATExec: IN std_logic_vector(31 downto 0);
	      R1, R2, R_br_Final: OUT std_logic_vector(31 downto 0);
	      controlSignals2 :  out std_logic_vector(11 downto 0);
	      controlSignals  :  out std_logic_vector(7 downto 0);
	      Rdest:  out std_logic_vector(2 downto 0);
	      LDUseStall: out std_logic;
	      RegfileOut: out ram_type
		);
end entity;

Architecture decStage of DecodeStage is
signal signals2: std_logic_vector(11 downto 0);
signal signals: std_logic_vector(7 downto 0);
signal FU_output:std_logic_vector(1 downto 0);
signal stall_hazard: std_logic;
signal extended1, extended2, extendedIMM, R2Temp, R_br:std_logic_vector(31 downto 0);
constant zeros: std_logic_vector(15 downto 0):="0000000000000000";
constant ones: std_logic_vector(15 downto 0):="1111111111111111";

signal stall_result, isRst, isIntr, finalStall, changeSignals: std_logic;

Begin

Hazard_Unit : ENTITY work.Hazard_Load_case PORT MAP('0', IDEX_MemRead , ID_EX_Rdst ,IR(8 downto 6) , IR(5 downto 3),stall_hazard);

FileRegL : ENTITY work.RegFile PORT MAP(IR(8 downto 6), IR(5 downto 3), Add_BR_Reg, clk, WriteReg, rst, Rwrite, writeData, R1, R2Temp, R_br,RegfileOut);

CULabel:   entity work.controlUnit port map(interrupt, IR(13 downto 9), branch, clk, rst, finalStall, signals2, signals, isRst, isIntr);
stall_result<=finalStall or (Branch and not(IR(13) and not(IR(12)) and not(IR(11)) and IR(10) and not(IR(9)))) or falseprediction or stallfromFetch; --exclude call
finalStall <= (stall_hazard and not(isRst or isIntr or signals2(4))) or stallAll;
LDUseStall <= finalStall;
changeSignals<= stall_result and not(isRst or isIntr or signals2(4)) and not(stallAll);
signals2L: entity work.twoInpMux generic map(12) port map (signals2, "000000000000", changeSignals, controlSignals2);
signalsL:  entity work.twoInpMux generic map(8) port map (signals,"11000000", changeSignals, controlSignals);
extended1 <= zeros & Imm_val;
extended2 <= ones & Imm_val;
extendedL: entity work.twoInpMux port map (extended1, extended2, Imm_val(15), extendedIMM);
sndOpMuxL: entity work.twoInpMux port map (extendedIMM, R2Temp, signals(5), R2);
RdestMuxL: entity work.twoInpMux generic map(3) port map (IR(2 downto 0), IR(8 downto 6), signals2(3), Rdest);


Forwarding_Unit : ENTITY work.DFU PORT MAP( clk, enableFU , Add_BR_Reg, Exec_Rdst,Rwrite,WriteReg,wb_excute,FU_output);
Rdst_Mux : ENTITY work.three_input_mux Port Map( R_br, writeData, DataATExec  ,FU_output ,R_br_Final);
	

end Architecture;