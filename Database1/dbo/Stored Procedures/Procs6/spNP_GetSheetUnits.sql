-- spNP_GetSheetUnits() retrieve sheet information based on passed in sheet name
--
CREATE PROCEDURE dbo.spNP_GetSheetUnits
 	   @Sheet_Desc 	 nVarchar(50)
AS
DECLARE @Count         Int
DECLARE @PL_Id         Int
DECLARE @Return_Status Int
SELECT  @Return_Status = -1  	 --Initialize
SELECT @Count = COUNT(Sheet_Id) FROM Sheets WHERE Sheet_Type = 27 AND Sheet_Desc = @Sheet_Desc
If @Count > 1
  BEGIN
    GOTO DO_SPECIFIC_UNITS
  END
Else If @Count = 1
  BEGIN
    SELECT @PL_Id = PL_Id FROM Sheets WHERE Sheet_Type = 27 AND Sheet_Desc = @Sheet_Desc
    If @PL_Id IS NULL 
      BEGIN
       GOTO DO_SPECIFIC_UNITS
      END
    Else
      BEGIN
        SELECT pu.PU_Id, pu.PU_Desc, pu.PL_Id, pl.PL_Desc, pu.Non_Productive_Reason_Tree 
          FROM Prod_Units pu  
          JOIN Prod_Lines pl on pl.PL_Id = pu.PL_Id
         WHERE pu.PU_Id <> 0 AND pu.Non_Productive_Category = 7 AND pu.PL_Id = @PL_Id
        SELECT @Return_Status = @@Error
        SELECT [Return_Status] = @Return_Status
      END
    --EndIf
  END
--EndIf
GOTO END_PROC
DO_SPECIFIC_UNITS:
  SELECT u.Sheet_Id, u.PU_Id, pu.PU_Desc, pu.PL_Id, pl.PL_Desc, pu.Non_Productive_Reason_Tree 
    FROM Sheet_Unit u 
    JOIN Prod_Units pu ON pu.PU_Id = u.PU_Id AND pu.PU_Id <> 0 AND pu.Non_Productive_Category = 7
    JOIN Prod_Lines pl on pl.PL_Id = pu.PL_Id
    JOIN Sheets s ON s.Sheet_Id = u.Sheet_Id AND s.Sheet_Type = 27 AND s.Sheet_Desc = @Sheet_Desc
  SELECT @Return_Status = @@Error
  SELECT [Return_Status] = @Return_Status
END_PROC:
