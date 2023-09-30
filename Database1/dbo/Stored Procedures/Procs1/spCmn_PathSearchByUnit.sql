-------------------------------------------------------------------------------
-- This Stored Procedure will retrieve a PathId and PathCode for a given 
-- Production Unit Id or Description. It will locate the path based on the 
-- following criteria:
--
-- 1. Returns the Path pointed by the DefaultPathCode UDP for the PU.
-- 2. Counts how many Paths are associated with the PU:
--  	 If only 1:
-- 	  	 Returns the found path.
--  	 If more than 1: 
-- 	  	 Returns the last Active Path. If there is not active path, then
-- 	  	 returns the associated path that matches the PU Desc.
-- 3. If all above fails, then returns the passed defaultPathCode
--
-- Original  	  11-Nov-2004  	  AlexJ
-- Revision
--
-- Return codes:
-- 1  	 - Success
-- -100 	 - Production Unit Not found
--
--
-- Example
--  declare 	 @PathId Int, @PathCode varchar(25), @rc int
--  EXEC @rc = spcmn_PathSearchByUnit @PathId OUTPUT, @PathCode OUTPUT, 'TestPU2', '<Undefined>'
--  EXEC @rc = spcmn_PathSearchByUnit @PathId OUTPUT, @PathCode OUTPUT, 'TestPU2', 'Path3'
-------------------------------------------------------------------------------
CREATE 	 PROCEDURE dbo.spCmn_PathSearchByUnit
 	 @PathId 	  	  	 Int 	  	 OUTPUT,
 	 @PathCode 	  	 VarChar(255) 	 OUTPUT,
 	 @PUInput 	  	 VarChar(255),
 	 @DefaultPathCode 	 VarChar(255) 	 = Null 	 
AS 
-------------------------------------------------------------------------------
-- Declare variables
-------------------------------------------------------------------------------
DECLARE 	 @PUId 	  	  	 Int,
 	 @PUDesc 	  	  	 VarChar(255),
 	 @ReturnCode 	  	 Int,
 	 @CountPath 	  	 Int,
 	 @DefaultPUPathCode 	 VarChar(255),
 	 @MaxStartTime 	  	 DateTime
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT 	 @PUId 	  	 = Null,
 	 @PUDesc 	  	 = Null,
 	 @PathId 	  	 = Null,
 	 @PathCode 	 = Null,
 	 @ReturnCode 	 = 1
-------------------------------------------------------------------------------
-- Check the inputs.  The PUId must exist
-------------------------------------------------------------------------------
IF 	 IsNumeric(@PUInput) = 1
BEGIN
 	 SELECT 	 @PUId 	 = Convert(Int, Convert(Float, @PUInput))
 	 SELECT 	 @PUDesc 	 = PU_Desc
 	  	 FROM 	 Prod_Units
 	  	 WHERE 	 PU_Id 	 = @PUId
END
ELSE
BEGIN
 	 SELECT 	 @PUDesc 	 = @PUInput
 	 SELECT 	 @PUId 	 = PU_Id
 	  	 FROM 	 Prod_Units
 	  	 WHERE 	 PU_Desc 	 = @PUDesc
END
IF 	 @PUId 	 Is Null
BEGIN
 	 SELECT 	 @ReturnCode 	 = -100
 	 GOTO 	 FInished
END
-------------------------------------------------------------------------------
-- Search for the DefaultPathCode for this PU
------------------------------------------------------------------------------
IF 	 @PathId 	 Is Null
BEGIN
 	 SELECT 	 @PathId 	 = Default_Path_Id
 	  	 FROM 	 Prod_Units
 	  	 WHERE 	 PU_Id = @PUId
END
-------------------------------------------------------------------------------
-- If not default on unit check UDP
-------------------------------------------------------------------------------
IF 	 @PathId 	 Is Null
BEGIN
 	 EXEC 	 spcmn_PUParameterLookup 	 
 	  	 @DefaultPUPathCode    	  	 OUTPUT, 
 	  	 @PUId,  
 	  	 'DefaultPathCode', 
 	  	 Null
 	 IF 	 @DefaultPUPathCode 	 Is Not Null
 	 BEGIN
 	  	 SELECT 	 @PathId 	 = Path_Id
 	  	  	 FROM 	 PrdExec_Paths
 	  	  	 WHERE 	 Path_Code 	 = @DefaultPUPathCode
 	 END
END
-------------------------------------------------------------------------------
-- If could not find a UDP, then find out how many Paths the passed PU belongs.
-------------------------------------------------------------------------------
IF 	 @PathId Is Null
BEGIN
 	 SELECT 	 @CountPath 	 = Count(PPU.PEPU_Id)
 	  	  	 FROM 	 PrdExec_Path_Units PPU
 	  	  	 JOIN 	 PrdExec_Paths PP 
 	  	  	 ON 	 PPU.Path_Id 	 = PP.Path_Id
 	  	  	 WHERE 	 PPU.PU_Id 	 = @PUId
 	  	  	 AND 	 PP.Is_Schedule_Controlled  = 1
 	 -- 	  	 AND 	 PPU.Is_Schedule_Point = 1
 	 -- 	  	 AND 	 PPU.Is_Production_Point = 1
 	 -------------------------------------------------------------------------------
 	 -- If PU belongs to multiple paths, then search for the last active Path
 	 -------------------------------------------------------------------------------
 	 IF 	 @CountPath > 1
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- If PU belongs to multiple paths, then search for the last active Path. If
 	  	 -- there are no active paths, then search for a path that is associated with
 	  	 -- the PU and matches the pu desc.
 	  	 --
 	  	 -- A PU can be active in different Paths, therefore it might exist multiple
 	  	 -- records for this PU where end_time is null. The SP gets the path from the
 	  	 -- most recent time, the PU has been active.
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @MaxStartTime 	 = Null
 	  	 SELECT 	 @MaxStartTime 	 = Max(Start_Time)
 	  	  	 FROM 	 prdexec_path_unit_starts
 	  	  	 WHERE 	 PU_Id 	  	 = @PUId
 	  	  	 AND 	 End_Time 	 Is Null
 	  	 IF 	 @MaxStartTime 	 Is Not Null
 	  	 BEGIN
 	  	  	 SELECT 	 @PathId 	  	 = Path_Id
 	  	  	  	 FROM 	 PrdExec_Path_Unit_Starts
 	  	  	 WHERE 	 PU_Id 	  	 = @PUId
 	  	  	 AND 	 Start_Time 	 = @MaxStartTime
 	  	  	 AND 	 End_Time 	 Is Null
 	  	 END
 	  	 -------------------------------------------------------------------------------
 	  	 --  Search for a Path that is associated with the unit and which PathCode matches
 	  	 --  the PU Desc
 	  	 ------------------------------------------------------------------------------
 	  	 IF 	 @PathId 	 Is Null
 	  	 BEGIN
 	  	  	 SELECT 	 @PathId = PPU.Path_Id
 	  	  	  	 FROM 	 PrdExec_Path_Units PPU
 	  	  	  	 JOIN 	 PrdExec_Paths PP 
 	  	  	  	 ON 	 PPU.Path_Id 	 = PP.Path_Id
 	  	  	  	 WHERE 	 PPU.PU_Id 	 = @PUId
 	  	  	  	 AND 	 PP.Path_Code 	 = @PUDesc
 	  	  	  	 AND 	 PP.Is_Schedule_Controlled  = 1
 	  	 -- 	  	 AND 	 PPU.Is_Schedule_Point = 1
 	  	 -- 	  	 AND 	 PPU.Is_Production_Point = 1
 	  	 END
 	 END
 	 -------------------------------------------------------------------------------
 	 -- If PU belongs to a single path, this is the path we are looking for
 	 -------------------------------------------------------------------------------
 	 IF 	 @CountPath = 1
 	 BEGIN
 	  	 SELECT 	 @PathId = PPU.Path_Id
 	  	  	 FROM 	 PrdExec_Path_Units PPU
 	  	  	 JOIN 	 PrdExec_Paths PP 
 	  	  	 ON 	 PPU.Path_Id 	 = PP.Path_Id
 	  	  	 WHERE 	 PPU.PU_Id 	 = @PUId
 	  	  	 AND 	 PP.Is_Schedule_Controlled  = 1
 	 -- 	  	 AND 	 PPU.Is_Schedule_Point = 1
 	 -- 	  	 AND 	 PPU.Is_Production_Point = 1
 	 END
END
-------------------------------------------------------------------------------
-- Returns the default value if not found. PathId will be null if the default
-- path code does not exist
------------------------------------------------------------------------------
Finished:
IF 	 @PathId 	 Is Null
BEGIN
 	 SELECT 	 @PathCode 	  	 = @DefaultPathCode
 	 SELECT 	 @PathId 	  	  	 = Path_Id
 	  	 FROM 	 PrdExec_Paths
 	  	 WHERE 	 Path_Code 	 = @DefaultPathCode
END
ELSE
BEGIN
 	 SELECT 	 @PathCode 	  	  	 = Path_Code
 	  	 FROM 	 PrdExec_Paths
 	  	 WHERE 	 Path_Id 	  	 = @PathId
END
RETURN @ReturnCode
