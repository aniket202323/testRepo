-- DESCRIPTION:
-- spXLA_SearchUnits_Secure allows the caller to search for all units or units in a given production lines. For security reasonh, units configured with 
-- specific security group will be revealed only to users belong to that group or administrator group (User_Security.Group_Id = 1).  The security is imposed
-- only on search.  Once the use has PU_Id, s/he can query for attributes or use the ID for other Add-In functions. 
-- mt/5-23-2005
CREATE PROCEDURE dbo.spXLA_SearchUnits_Secure
 	   @User_Id        Integer 
 	 , @PL_Id 	   Integer     = NULL
 	 , @MasterOnly     Bit         = 0
 	 , @PU_Desc_Filter Varchar(50) = NULL
AS 
DECLARE @queryType 	             TinyInt
DECLARE @GetMaster_Line_Filter      TinyInt
DECLARE @GetMaster_Line_NoFilter    TinyInt
DECLARE @GetMaster_NoLine_Filter    TinyInt
DECLARE @GetMaster_NoLine_NoFilter  TinyInt
DECLARE @AllUnits_Line_Filter       TinyInt
DECLARE @AllUnits_Line_NoFilter     TinyInt
DECLARE @AllUnits_NoLine_Filter     TinyInt
DECLARE @AllUnits_NoLine_NoFilter   TinyInt
DECLARE @Admin                      Bit
SELECT @GetMaster_Line_Filter     = 1
SELECT @GetMaster_Line_NoFilter   = 2
SELECT @GetMaster_NoLine_Filter   = 3
SELECT @GetMaster_NoLine_NoFilter = 4
SELECT @AllUnits_Line_Filter      = 5
SELECT @AllUnits_Line_NoFilter    = 6
SELECT @AllUnits_NoLine_Filter    = 7
SELECT @AllUnits_NoLine_NoFilter  = 8
If      @MasterOnly = 0 AND @PL_Id Is NULL     AND @PU_Desc_Filter Is NULL     SELECT @queryType = @AllUnits_NoLine_NoFilter
Else If @MasterOnly = 0 AND @PL_Id Is NOT NULL AND @PU_Desc_Filter Is NOT NULL SELECT @queryType = @AllUnits_Line_Filter
Else If @MasterOnly = 0 AND @PL_Id Is NULL     AND @PU_Desc_Filter Is NOT NULL SELECT @queryType = @AllUnits_NoLine_Filter
Else If @MasterOnly = 0 AND @PL_Id Is NOT NULL AND @PU_Desc_Filter Is NULL     SELECT @queryType = @AllUnits_Line_NoFilter
Else If @MasterOnly = 1 AND @PL_Id Is NOT NULL AND @PU_Desc_Filter IS NOT NULL SELECT @queryType = @GetMaster_Line_Filter
Else If @MasterOnly = 1 AND @PL_Id Is NULL     AND @PU_Desc_Filter IS NOT NULL SELECT @queryType = @GetMaster_NoLine_Filter
Else If @MasterOnly = 1 AND @PL_Id Is NOT NULL AND @PU_Desc_Filter IS NULL     SELECT @queryType = @GetMaster_Line_NoFilter
Else If @MasterOnly = 1 AND @PL_Id Is NULL     AND @PU_Desc_Filter IS NULL     SELECT @queryType = @GetMaster_NoLine_NoFilter
-- Get Security Group Memberships of this user
CREATE TABLE #User_Security( Group_Id Int)
INSERT INTO #User_Security SELECT us.Group_Id FROM User_Security us WHERE us.User_Id = @User_Id
-- Verify administrative group memberhship for this user
SELECT @Admin = 0
If EXISTS ( SELECT Group_Id FROM #User_Security WHERE Group_Id = 1 ) SELECT @Admin = 1
--EndIf
IF @queryType = @AllUnits_NoLine_NoFilter
  BEGIN
      SELECT pu.* 
        FROM Prod_Units pu
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE pu.PU_Id > 0 
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
    ORDER BY Pu_Desc
  END
ELSE IF @queryType = @AllUnits_NoLine_Filter
  BEGIN
      SELECT pu.* 
        FROM Prod_Units pu
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE pu.PU_Id > 0 
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
         AND pu.PU_Desc LIKE '%' + @PU_Desc_Filter + '%'
    ORDER BY pu.PU_Desc
  END
ELSE IF @queryType = @AllUnits_Line_NoFilter
  BEGIN
      SELECT  pu.* 
        FROM  Prod_Units pu
        JOIN  Prod_Lines pl ON pl.Pl_Id = pu.Pl_Id AND pl.Pl_Id = @PL_Id
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE  pu.PU_Id > 0 
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
    ORDER BY  pu.PU_Desc
  END
ELSE IF @queryType = @AllUnits_Line_Filter
  BEGIN
      SELECT  pu.* 
        FROM  Prod_Units pu
        JOIN  Prod_Lines pl ON pl.Pl_Id = pu.Pl_Id AND pl.Pl_Id = @PL_Id
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE  pu.PU_Id > 0 
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
         AND pu.PU_Desc LIKE '%' + @PU_Desc_Filter + '%'
    ORDER BY  pu.PU_Desc
  END
ELSE IF @queryType = @GetMaster_NoLine_NoFilter
  BEGIN  
      SELECT pu.* 
        FROM Prod_Units pu
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE pu.Master_Unit IS NULL 
         AND pu.PU_Id > 0 
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
     ORDER BY pu.PU_Desc
  END
ELSE IF @queryType = @GetMaster_NoLine_Filter
  BEGIN  
      SELECT pu.* 
        FROM Prod_Units pu
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE pu.Master_Unit IS NULL 
         AND pu.PU_Id > 0 
         AND PU_Desc LIKE '%' + @PU_Desc_Filter + '%' 
    ORDER BY pu.PU_Desc
  END
ELSE IF @queryType = @GetMaster_Line_NoFilter
  BEGIN
      SELECT pu.* 
        FROM Prod_Units pu
        JOIN Prod_Lines pl ON pl.Pl_Id = pu.Pl_Id AND pl.Pl_Id = @PL_Id
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE pu.Master_Unit IS NULL 
         AND pu.PU_Id > 0
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
    ORDER BY pu.PU_Desc
  END
ELSE IF @queryType = @GetMaster_Line_Filter
  BEGIN
      SELECT pu.* 
        FROM Prod_Units pu
        JOIN Prod_Lines pl ON pl.Pl_Id = pu.Pl_Id AND pl.Pl_Id = @PL_Id
        LEFT JOIN #User_Security us ON us.Group_Id = pu.Group_Id
       WHERE pu.Master_Unit IS NULL 
         AND pu.PU_Id > 0 
         AND pu.PU_Desc LIKE '%' + @PU_Desc_Filter + '%'
         AND ( pu.Group_Id IS NULL OR pu.Group_Id = us.Group_Id OR @Admin = 1 )
    ORDER BY pu.PU_Desc
  END
--EndIf
DROP TABLE #User_Security
