-- spNP_LastNonProductiveByUnits() Gets the lastest non-productive times for a given set of units.
-- This procedure is used when first attempt to retrieve that data in a specified data window return nothing.
--
CREATE PROCEDURE dbo.spNP_LastNonProductiveByUnits
 	   @UnitString1 	 Varchar(8000)
 	 , @UnitString2 	 Varchar(8000)
AS
DECLARE @PU_Id         Int
DECLARE @Return_Status Int
SELECT  @Return_Status = -1  	 --Initialize
-- Make Temp table for selected units
CREATE TABLE #Temp_ID (ID integer)
INSERT  #Temp_ID EXECUTE spNP_IDsFromString @UnitString1, @UnitString2
SELECT DISTINCT Max(d.Start_Time)
  FROM NonProductive_Detail d
  JOIN #Temp_ID t ON t.ID = d.PU_Id
SELECT @Return_Status = @@Error
SELECT [Return_Status] = @Return_Status
DROP TABLE #Temp_ID
