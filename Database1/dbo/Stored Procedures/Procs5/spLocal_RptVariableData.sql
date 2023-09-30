  --------------------------------------------------------------------------------------------------------------------------------------------------------  
--  
-- Version 1 2003-03-06  
--  
-- This SP receives a StartTime, EndTime, and a DisplayId and returns Tests values for the variables  
-- that are associated with the display.  The data returned is:  
-- Line  
-- Display    
-- Variable  
-- Result_On  
-- Result  
-- Comment  
--  
-- 2003-03-06   Vince King  
--  - Original procedure.  
--  
-- 2003-03-10   Vince King  
--  - Added code to result set to return Product and Variable Specs.  
--  - Added report parameters @IncludeSpecs and @IncludeComment to  
--    allow the user to determine if Specs and Comment are returned.  
--------------------------------------------------------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [dbo].[spLocal_RptVariableData]   
 @StartTime    datetime,  
 @EndTime      datetime,   
 @DisplayId    Integer,  
 @VarList  nVarChar(500),  
 @IncludeSpecs  Integer,  
 @IncludeComment Integer  
  
AS  
  
SET ANSI_WARNINGS OFF  
  
DECLARE @strSQL  nVarChar(4000)  
  
---------------------------------------------------------------------------------  
-- Create the temporary table to hold Variable Ids.  
---------------------------------------------------------------------------------  
CREATE TABLE #Variables (  
 VarId  Integer )  
  
CREATE INDEX v_VarId  
 ON #Variables(VarId)  
  
---------------------------------------------------------------------------------  
-- Insert the Variable Ids in the #Variables temporary table.  
---------------------------------------------------------------------------------  
  
INSERT #Variables (VarId)  
SELECT Var_Id  
FROM Variables  
WHERE CHARINDEX('|' + CONVERT(VARCHAR, Var_Id) + '|', '|' + @VarList + '|') > 0  
  
---------------------------------------------------------------------------------  
-- Get the Display Description.  
---------------------------------------------------------------------------------  
DECLARE @DisplayDesc    nVarChar(100)   
  
SELECT @DisplayDesc = (SELECT Sheet_Desc FROM Sheets WHERE Sheet_Id = @DisplayId)   
  
---------------------------------------------------------------------------------  
-- Return the result set for the variables selected.  If a list of Var_Ids was  
-- was provided, bring back only those variables, otherwise bring back ALL  
-- variables on the display.  
---------------------------------------------------------------------------------  
  
SELECT @strSQL = 'SELECT  pl.PL_Desc [Line],' + CHAR(39) +   
   @DisplayDesc + CHAR(39) + ' [Display],  
   v.Var_Desc [Variable],  
   Result_On [Result On],  
   p.Prod_Desc + ' + CHAR(39) + '(' + CHAR(39) + ' + p.Prod_Code + ' +   
    CHAR(39) + ')' + CHAR(39) + ' [Product],  
   Result [Result] '  
IF @IncludeSpecs = 1  
  SELECT @strSQL = @strSQL + ',(SELECT TOP 1 L_Entry FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)  
    ORDER BY vs.Effective_Date DESC) [Lower Entry],  
   (SELECT TOP 1 L_Reject FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)  
    ORDER BY vs.Effective_Date DESC) [Lower Reject],  
   (SELECT TOP 1 L_Warning FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)  
    ORDER BY vs.Effective_Date DESC) [Lower Warning],  
   (SELECT TOP 1 L_User FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)   
    ORDER BY vs.Effective_Date DESC) [Lower User],  
   (SELECT TOP 1 Target FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)  
    ORDER BY vs.Effective_Date DESC)  [Target],  
   (SELECT TOP 1 U_User FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)   
    ORDER BY vs.Effective_Date DESC) [Upper User],  
   (SELECT TOP 1 U_Warning FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)   
    ORDER BY vs.Effective_Date DESC) [Upper Warning],  
   (SELECT TOP 1 U_Reject FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)   
    ORDER BY vs.Effective_Date DESC) [Upper Reject],  
   (SELECT TOP 1 U_Entry FROM Var_Specs vs WHERE (vs.Var_Id = t.Var_Id)  
    AND (t.Result_On >= vs.Effective_Date)  
    AND  (t.Result_On < vs.Expiration_Date  
     OR vs.Expiration_Date IS NULL)  
    AND (p.Prod_Id = vs.Prod_Id)   
    ORDER BY vs.Effective_Date DESC) [Upper Entry]'  
 IF @IncludeComment = 1  
  SELECT @strSQL = @strSQL +  ',RTRIM(LTRIM(CONVERT(nVarChar(1000), c.Comment_Text))) [Comment]'  
  
 SELECT @strSQL = @strSQL + '  FROM    Tests t JOIN    Variables v ON t.Var_Id = v.Var_Id   
   LEFT JOIN    Prod_Units pu ON v.PU_Id = pu.PU_Id   
   LEFT JOIN    Prod_Lines pl ON pu.PL_Id = pl.PL_Id   
   LEFT    JOIN    Comments c ON t.Comment_Id = c.Comment_Id   
   LEFT JOIN Production_Starts ps ON v.PU_Id = ps.PU_Id  
     AND t.Result_On >= ps.Start_Time  
     AND (t.Result_On < ps.End_Time  
      OR ps.End_Time IS NULL)  
   LEFT JOIN Products p ON ps.Prod_Id = p.Prod_Id'  
  
 IF (SELECT COUNT(VarId) FROM #Variables) > 0   
   SELECT @strSQL = @strSQL +   
    ' WHERE   t.Var_Id    IN (SELECT tv.VarId FROM #Variables tv)'  
 ELSE  
   SELECT  @strSQL = @strSQL +   
    ' WHERE   t.Var_Id      
    IN (SELECT sv.Var_Id FROM Sheet_Variables sv WHERE Sheet_Id = ' + CONVERT(nVARCHAR(10),@DisplayId) + ')'  
  
 SELECT  @strSQL = @strSQL + ' AND Result_On > ' + CHAR(39) + CONVERT(nVARCHAR(50), @StartTime) + CHAR(39) +  
    ' AND Result_On <= ' + CHAR(39) + CONVERT(nVARCHAR(50), @EndTime) + CHAR(39) +   
   ' ORDER BY t.Result_On, v.Var_Desc ASC '  
  
 EXEC (@strSQL)  
  
DropTables:  
  
DROP TABLE #Variables  
  
RETURN  
