-------------------------------------------------------------------------------
-- Edit history
-------------------------------------------------------------------------------
-- LPV STI 04-oct-2004 Development
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Parameters
-------------------------------------------------------------------------------
/*  	 
 	 @ErrorCode 	  	  	 INTEGER OUTPUT,
 	 @ErrorMessage 	  	 VARCHAR (1000) OUTPUT, 	 
 	 @Mode. 	  	  	  	 Values: 1,2
 	  	  	  	  	  	  	  	 1 - Return all Crew for PU_ID in PUIDList filtered by TEAM_DESC with @Mask
 	  	     	  	  	  	  	 2 - Return Crew of RptCrewDescList
 	 @RptCrewDescList. 	 Default = Null. Pipe-separated list of CrewDesc
 	 @RptPuIdList 	  	 Default = Null. Pipe-separated list of pu id
 	 @Mask. 	  	  	  	 Default = Null. Criterea to search for crew
*/
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Sample input:
/*
EXEC spRS_FilterTeams 
0,  --@ErrorCode
'', --@ErrorMessage
2,  --@Mode
'B|A',  --@RptCrewDescList
'', -- @RptPuIdList
'%b%' -- @Mask
*/
-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spRS_FilterShifts]
@Mode   	  	  	  	 INTEGER,
@RptCrewDescList  VARCHAR (4000) = Null,
@RptPuIdList 	  	 VARCHAR (100) = Null,
@Mask   	  	  	  	 VARCHAR (100) = Null
AS 
 	 SET NOCOUNT ON
 	 
 	 DECLARE @SQLStatement  	 VARCHAR (4000)
   	 DECLARE @crewDesc 	  	  	 VARCHAR (50)
 	 DECLARE @puId 	  	  	  	 INTEGER
 	 DECLARE @Seploc  	  	  	 INTEGER
 	 DECLARE @CountLines  	  	 INTEGER
 	 DECLARE @ANDFLAG  	  	  	 INTEGER
 	 IF @Mode Not in (1,2)
 	 BEGIN
 	  	 RETURN 0
 	 END
 	 
 	 CREATE TABLE #TempCrew
 	  	 (
 	  	  	 TEAM_ID 	  	  	 INT IDENTITY(1,1),
 	  	  	 TEAM_DESC  	  	 VARCHAR (50)
 	  	 )
 	 CREATE TABLE #TempProdUnits
 	  	  	 (
 	  	  	  	 pu_Id  	  	 INT
 	  	  	 )
 	 
 	 SELECT @ANDFLAG = 0
 	 
 	 IF LEN(ISNULL(@Mask,'')) <=0
 	  	 SELECT @Mask = '%%'
 	 IF (LEN(IsNull(@RptPuIdList,'')) > 0) AND UPPER(ISNULL(@RptPuIdList,'')) != '!NULL'   
 	 BEGIN
 	  	 WHILE Len(IsNull(@RptPuIdList,'')) > 0
 	  	 BEGIN
 	  	  	 IF CHARINDEX(',', @RptPuIdList) > 0
 	  	  	 BEGIN
 	  	  	  	 SELECT @Seploc = CHARINDEX(',', @RptPuIdList)
 	  	  	  	 IF ISNUMERIC(left(@RptPuIdList, @Seploc-1)) = 1
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @puId = Cast(left(@RptPuIdList, @Seploc-1) AS INTEGER)
 	  	  	  	  	 INSERT  	 #TempProdUnits (pu_id) VALUES(@puId)
 	  	  	  	 END
 	  	  	  	 SELECT @RptPuIdList = right(@RptPuIdList, len(@RptPuIdList) - @Seploc)
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 IF ISNUMERIC(@RptPuIdList) = 1
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @puId = Cast(@RptPuIdList  as INT)
 	  	  	  	  	 INSERT  	 #TempProdUnits (pu_id) VALUES(@puId)
 	  	  	  	 END
 	  	  	  	 SELECT @RptPuIdList = ''
 	  	  	 END
 	  	 END 	  	 
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT  	 #TempProdUnits (pu_id)
 	  	  	 SELECT 	 pu_id
 	  	  	 FROM  	  	 prod_units
 	  	  	 WHERE 	  	 pu_id > 0
 	 END
 	 
 	 IF @Mode = 1
 	 BEGIN
 	  	 SELECT @SQLStatement =  	 ' SELECT DISTINCT Shift_DESC AS TEAM_DESC ' +
 	  	  	  	  	  	  	  	  	  	 ' FROM   DBO.CREW_SCHEDULE C JOIN #TempProdUnits P ON C.PU_ID = P.PU_ID ' +
 	  	  	  	  	  	  	  	  	  	 ' WHERE  Shift_DESC LIKE "' + @Mask +'" ' +
 	  	  	  	  	  	  	  	  	  	 ' ORDER  BY Shift_DESC' 	  	 
 	 END
 	 
 	 IF @Mode = 2
 	 BEGIN
 	  	 
 	  	 IF (LEN(IsNull(@RptCrewDescList,'')) > 0)
 	  	 BEGIN
 	  	  	 WHILE Len(IsNull(@RptCrewDescList,'')) > 0
 	  	  	 BEGIN
 	  	  	  	 IF CHARINDEX(',', @RptCrewDescList) > 0
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @Seploc = CHARINDEX(',', @RptCrewDescList)
 	  	  	  	  	 
 	  	  	  	  	 SELECT @crewDesc = left(@RptCrewDescList, @Seploc-1)
 	  	  	  	  	 INSERT  	 #TempCrew (TEAM_DESC) VALUES(@crewDesc)
 	  	  	  	  	 
 	  	  	  	  	 SELECT @RptCrewDescList = right(@RptCrewDescList, len(@RptCrewDescList) - @Seploc)
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @crewDesc = @RptCrewDescList
 	  	  	  	  	 INSERT  	 #TempCrew (TEAM_DESC) VALUES(@crewDesc)
 	  	  	  	  	 
 	  	  	  	  	 SELECT @RptCrewDescList = ''
 	  	  	  	 END
 	  	  	 END 	  	 
 	  	 END
 	  	 SELECT @SQLStatement =  	 ' SELECT DISTINCT TEAM_ID, TEAM_DESC ' +
 	  	  	  	  	  	  	  	  	  	 ' FROM   #TempCrew ' + 
 	  	  	  	  	  	  	  	  	  	 ' ORDER BY TEAM_ID '
 	 END 	 
 	 
 	 PRINT @SQLStatement
 	 
 	 EXECUTE (@SQLStatement)
 	 
 	 
 	  	 GOTO CLEAN_AND_EXIT
 	  	 
CLEAN_AND_EXIT:
 	 
 	 DROP TABLE #TempProdUnits
 	 DROP TABLE #TempCrew
 	 
 	 
