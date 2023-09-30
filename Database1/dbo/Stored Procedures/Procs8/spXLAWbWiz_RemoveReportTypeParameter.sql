-- spXLAWbWiz_RemoveReportTypeParameter() removes all but system parameters that are tied to Report_Type_Id 
-- System parameters are those Report_Parameters.RP_Id whose Report_Parameters.Is_Default = 1. The caller of this
-- function supplies the list of system parameters.
-- [ Proficy Publish-To_Web Wizard uses this function to clear exising parameters then update with the newly selected
-- parameters ] mt/11-25-2002
--
CREATE PROCEDURE dbo.spXLAWbWiz_RemoveReportTypeParameter
 	   @Report_Type_Id       Int
 	 , @SystemParameterList  Varchar(8000)
 	 , @ReturnStatus         Int OUTPUT
AS
 	 --Needed for cursor
DECLARE @ReportDefinitionStatus Int
DECLARE @@Report_Id             Int
 	 --Needed for temp system parameter table
DECLARE @i                      Integer
DECLARE @TempChar               Char
DECLARE @TempString             VarChar(10)
Declare @ID_Count               Integer
DECLARE @TempID                 Integer
SELECT @ReturnStatus = 0 	 --Initialize
If @SystemParameterList Is NULL GOTO EXIT_PROCEDURE
CREATE TABLE #Report_IDs (Report_Id Int)
CREATE TABLE #System_IDs (RP_Id Int)
--Build Temp Table for Report_Id then cursor through to delete "Report Definition"
  --Can't delete Report_Type_Parameters directly -- violation of constraint Report_Type_Id is referred to by 
  --Report_Definitions, etc. Call spXLAWbWiz_DeleteReportDefinition @Report_Id to clean definition before 
  --deleting Report_Type_Parameters
INSERT INTO #Report_IDs SELECT Report_Id From Report_Definitions WHERE Report_Type_Id = @Report_Type_Id
DECLARE TCursor INSENSITIVE CURSOR FOR (SELECT rid.Report_Id FROM #Report_IDs rid) FOR READ ONLY
OPEN TCursor
FETCH NEXT FROM TCursor INTO @@Report_Id
WHILE (@@FETCH_STATUS = 0)
  BEGIN
    FETCH NEXT FROM TCursor INTO @@Report_Id
    SELECT @ReportDefinitionStatus = 0
    EXECUTE spXLAWbWiz_DeleteReportDefinition @@Report_Id, @ReportDefinitionStatus OUTPUT
    If @ReportDefinitionStatus <> 0 BREAK
  END
--End WHILE
CLOSE TCursor
DEALLOCATE TCursor
If @ReportDefinitionStatus <> 0 
  BEGIN --{ ECRs 26745, 26214 mt/10-15-2003; missing markers!
    SELECT @ReturnStatus = @ReportDefinitionStatus
    GOTO DROP_TEMP_TABLES
  END   -- }
--EndIf
--Build "IDs" table for system parameter, so we don't delete them
SELECT @TempString = '' 	 --Initialize; avoid string + null = NULL problem
SELECT @i = 1
SELECT @ID_Count = 0
SELECT @TempChar = SUBSTRING (@SystemParameterList, @i, 1)
WHILE (@TempChar <> '$') AND (@i < 7999)
  BEGIN
    If @TempChar <> ','  --Not an ID separator
      SELECT @TempString = @TempString + @TempChar     --continue collecting chararacter into string
    Else --found the ID separator, we have collected all chars for the ID
      BEGIN
        SELECT @TempString = LTRIM(RTRIM(@TempString))
        If @TempString <> '' 
          BEGIN
            SELECT @TempID = CONVERT(Integer, @TempString)
            SELECT @ID_Count = @ID_Count + 1
            INSERT #System_IDs VALUES(@TempID)
          END
        --EndIf:@TempString                
        SELECT @TempString = '' 	 --initialize for next loop
      END
    --EndIf:
    SELECT @i = @i + 1
    SELECT @TempChar = SUBSTRING(@SystemParameterList, @i, 1)
  END
--End WHILE 	  	 
--Handle the last string
SELECT @TempString = LTRIM(RTRIM(@TempString))
If @TempString <> '' 
  BEGIN
    SELECT @TempID = CONVERT(Integer, @TempString)
    SELECT @ID_Count = @ID_Count + 1
    INSERT #System_IDs VALUES(@TempID)
  END
--EndIf:@TempString <> '' 
DELETE FROM Report_Type_Parameters WHERE Report_Type_Id = @Report_Type_Id AND RP_Id NOT IN (SELECT s.RP_Id FROM #System_IDs s)
SELECT @ReturnStatus = @@ERROR
DROP_TEMP_TABLES:
  DROP TABLE #Report_IDs
  DROP TABLE #System_IDs
EXIT_PROCEDURE:
