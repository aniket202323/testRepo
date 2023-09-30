/*
Get OEE data for a set of production units.
Execute spBF_OEEGetData_MasterUnits '1075','02/18/2017','02/20/2017',0,'UTC',1,10000,1
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@Summarize               - Adds a summary row which includes all units
@FilterNonProductiveTime - controls if NPT is included or not (1 = not)
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
*/
CREATE PROCEDURE [dbo].[spBF_OEEGetData_MasterUnits_Bak_177]
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@FilterNonProductiveTime int = 0,
@InTimeZone 	              nVarChar(200) = null,
@ReturnLineData 	  	  	 Int = 0,
@pageSize 	  	  	  	  	 Int = Null,
@pageNum 	  	  	  	  	 Int = Null,
@SortOrder 	  	  	  	  Int = 0 	  	  	  	  	 --  PercentOEE(!= 1,2,3),1 - PerformanceRate,2 - QualityRate,3 - AvailableRate
,@TotalRowCount Int =0 OUTPUT
AS
/* ##### spBF_OEEGetData_MasterUnits #####
Description 	 : fetches data for supervisory screen donut charts
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 modified to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL, OEEmode
2018-06-01 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Removed check for record existence in oeeaggregation if Agg store flag is ON
*/
set nocount on
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
SELECT @ReturnLineData = Coalesce(@ReturnLineData,0)
DECLARE @UseAggTable 	 Int = 0
DECLARE @Units TABLE
  ( RowID int IDENTITY,
  	  UnitId int NULL ,
  	  Unit nVarChar(100) NULL,
  	  UnitOrder int null,
  	  LineId int NULL, 
  	  Line nVarChar(100) NULL,
  	  OEEType  	  Int Null,
 	  Master_Unit int Null
)
SELECT @UseAggTable = Coalesce(Value,0) FROM Site_parameters where parm_Id = 607
-------------------------------------------------------------------------------------------------
-- Unit translation
-------------------------------------------------------------------------------------------------
If (@UnitList is Not Null)
  	  Set @UnitList = REPLACE(@UnitList, ' ', '')
if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
  	  Set @UnitList = Null
IF (@UnitList is not null)
  	  BEGIN
 	  
 	  	 IF (@UseAggTable = 1)
 	  	  	  BEGIN
 	  	  	  	 INSERT INTO @Units (UnitId) 
 	  	  	  	 --SELECT DISTINCT(Pu_Id) FROM OEEAggregation WHERE Pu_Id in (
 	  	  	  	 select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
 	  	  	  	 --)
 	  	  	  END
 	  	 ELSE  	 
 	  	  	 BEGIN
 	  	  	  	  INSERT INTO @Units (UnitId)
 	  	  	  	  SELECT Id FROM [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
 	  	  	 END 	  
END
UPDATE u
  	  SET u.Unit = u1.PU_Desc,
  	    	  u.LineId = u1.PL_Id, 
  	    	  u.Line = l.PL_Desc,
 	  	  u.Master_Unit = u1.Master_Unit,
  	    	  u.UnitOrder = coalesce(u1.PU_Order, 0)
  	  FROM @Units u
  	  Join dbo.Prod_Units u1 ON u1.PU_Id = u.UnitId
  	  Join dbo.Prod_Lines l ON l.PL_Id = u1.PL_ID
DELETE FROM @Units where Master_Unit is not null
DECLARE @PUIds nvarchar(max)
SELECT @PUIds = ''
 	 SELECT @PUIds =  @PUIds + CONVERT(nvarchar(10),UnitId) + ',' FROM @Units
EXECUTE spBF_OEEGetData @PUIds, @StartTime,@EndTime,@FilterNonProductiveTime,@InTimeZone,@ReturnLineData,@pageSize,@pageNum,@SortOrder,@TotalRowCount OUTPUT
