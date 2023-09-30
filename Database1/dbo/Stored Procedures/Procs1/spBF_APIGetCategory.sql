CREATE PROCEDURE [dbo].[spBF_APIGetCategory]
              @TimeSelection Int 
              ,@StartTime DateTime = Null
              ,@EndTime     DateTime = Null
              ,@PUIds       nvarchar(max) = null
              ,@LineIds     nvarchar(max) = Null
              ,@UserId      Int
 	  	  	   ,@OEEParameter nvarchar(50) = NULL
 	  	  	   ,@FilterNonProductiveTime Int = 0
AS
/* ##### spBF_APIGetCategory #####
Description 	 : Returns data for waterfall chart for Availability donut in case of classic OEE and for Availability, Performance & Quality donuts in case of Time based OEE
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Modified procedure to handle time based downtime calculation.
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Exclude Units for which Production event is Inactive
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Handled scenario where NPT falls inside DT
2018-06-07 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Changed logic of excluding Units [Production rate specification is not defined and Oee mode not set]
*/
IF NOT EXISTS(SELECT 1 FROM Users WHERE User_id = @UserId )
BEGIN
       SELECT  Error = 'ERROR: Valid User Required'
       RETURN
END
 	 --<Start: Logic to exclude Units>
 	 DECLARE @xml1 XML
 	 DECLARE @ActiveUnits TABLE(Pu_ID int)
 	 SET @xml1 = cast(('<X>'+replace(@PUIds,',','</X><X>')+'</X>') as xml)
 	 INSERT INTO @ActiveUnits(Pu_ID)
 	 SELECT N.value('.', 'int') FROM @xml1.nodes('X') AS T(N)
 	 SET @PUIds = NULL
 	 ;WITH NotConfiguredUnits As
 	 (
 	  	 Select 
 	  	  	 Pu.Pu_Id from Prod_Units Pu
 	  	 Where
 	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	 AND Production_Rate_Specification IS NULL
 	 )
 	 SELECT 
 	  	 @PUIds = COALESCE(@PUIds + ',', '') + Cast(Au.Pu_ID as nvarchar)
 	 FROM 
 	  	 @ActiveUnits Au
 	  	 LEFT OUTER JOIN NotConfiguredUnits Nu ON Nu.PU_Id = Au.Pu_ID
 	 WHERE 
 	  	 Nu.PU_Id IS NULL
 	 --<End: Logic to exclude Units>
If @OEEParameter IS NOT NULL
Begin
 	 If (@OEEParameter = 'Quality')
 	 Begin
 	  	 Set @OEEParameter = 'Quality losses'
 	 End
 	 Else
 	 Begin
 	  	 Set @OEEParameter = @OEEParameter + ' loss'
 	 End
End
DECLARE @Unspecified nVarChar(100)
DECLARE @InTimeZone  nVarChar(200) 
DECLARE @AllUnits Table (PU_Id Int,HasTree Int,LineId Int,DeptTZ nVarChar(500))
DECLARE @AllLines Table (PL_Id Int)
DECLARE @OneLineId Int
DECLARE @SecurityUnits Table (PU_Id Int)
DECLARE @End Int, @Start Int,@PUId Int,@ActualSecurity Int
DECLARE @outputtable table (Category nVarChar(max),Duration float,EventCount int)
DECLARE @DowntimeTable TABLE (DetailId Int,
Duration FLOAT,
UnitId Int,
CategoryId Int,
Category nvarchar(1000))
SET @Unspecified = '<None>'
SET @InTimeZone = 'UTC'
If @LineIds Is Not NUll
BEGIN
       INSERT INTO @AllLines(PL_Id) 
              SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Lines',@LineIds,',')
       IF (SELECT COUNT(*) FROM @AllLines) = 1
       BEGIN
              SELECT @OneLineId = PL_Id From @AllLines
       END
END
If EXISTS(SELECT 1 FROM @AllLines) 
BEGIN
       INSERT INTO @AllUnits(PU_Id)
       SELECT a.PU_Id
       FROM Prod_Units_Base a
       JOIN @AllLines c on c.PL_Id = a.PL_Id 
       Join Event_Configuration  b on b.ET_Id = 2 and b.PU_Id = a.PU_Id
END
ELSE If @PUIds Is Not NUll
BEGIN
       INSERT INTO @AllUnits(PU_Id) 
              SELECT DiSTINCT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,',')
       IF NOT EXISTS(SELECT 1 FROM @AllUnits)
       BEGIN
              SELECT  Error = 'ERROR: No Units Found'
              RETURN
       END
END
IF NOT EXISTS(SELECT 1 FROM @AllUnits)
BEGIN
       SELECT  Error = 'ERROR: No Valid Units Found'
       RETURN
END
UPDATE @AllUnits SET DeptTZ = d.Time_Zone,LineId = b.PL_Id 
       FROM @AllUnits a
       JOIN Prod_Units_Base b on b.PU_Id = a.PU_Id 
       JOIN Prod_Lines_Base c on c.PL_Id = b.PL_Id 
       JOIN Departments_Base d on d.Dept_Id = c.Dept_Id 
IF (SELECT COUNT(Distinct DeptTZ) FROM @AllUnits) <= 1
BEGIN
       SELECT @OneLineId  = MIN(LineId) FROM @AllUnits
END
IF @StartTime Is Not Null AND @EndTime Is Not Null
BEGIN 
       SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
       SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 	    SET @InTimeZone = NULL
END
ELSE
BEGIN
    EXECUTE dbo.spBF_CalculateOEEReportTime @OneLineId,@TimeSelection ,@StartTime  Output,@EndTime  Output, 1
 	 SET @InTimeZone = 'UTC'
END
IF @StartTime Is Null OR @EndTime Is Null
BEGIN 
       SELECT Error ='ERROR: Could not Calculate Date'
       RETURN
END
SELECT @PUIds = ''
       SELECT @PUIds =  @PUIds + CONVERT(nvarchar(10),PU_Id) + ',' 
                     FROM @AllUnits
Insert Into @AllUnits (PU_Id)
       SELECT a.PU_Id 
              FROM Prod_Units a 
              Join @AllUnits b on b.PU_Id = a.Master_Unit 
              WHERE a.PU_Id <> a.Master_Unit
UPDATE @AllUnits SET HasTree = 0
UPDATE @AllUnits SET HasTree = 1
       FROM @AllUnits a
       Join Prod_Events b on b.PU_Id = a.PU_Id and b.Event_Type = 2
Declare @DowntimeData table (
       EventId int,UnitEquipmentId uniqueidentifier,UnitId int,Unit nVarChar(100),StartTime datetime null,
       EndTime datetime null,Duration decimal(10,2) null,Uptime float null,LocationEquipmentId uniqueidentifier null,
       LocationId int null,Location nVarChar(100) null,FaultId int null,Fault nVarChar(100) null,
       StatusId int null,Status nVarChar(100) null,
       Reason1Id int null, Reason1 nVarChar(100) null,
       Reason2Id int null, Reason2 nVarChar(100) null,
       Reason3Id int null, Reason3 nVarChar(100) null,
       Reason4Id int null, Reason4 nVarChar(100) null,
       Action1Id int null, Action1 nVarChar(100) null,
       Action2Id int null, Action2 nVarChar(100) null,
       Action3Id int null, Action3 nVarChar(100) null,
       Action4Id int null, Action4 nVarChar(100) null,
       ReasonComment text null,
       ActionComment text null,
       ReasonsCompleted tinyint null,
       Operator nVarChar(255) null,
       IsOpen Int,
 	    NPT int
)
INSERT INTO @DowntimeData( EventId ,UnitEquipmentId ,UnitId ,Unit ,StartTime ,
       EndTime  ,Duration ,LocationEquipmentId ,
       LocationId ,Location,
       FaultId,Fault,
       StatusId  ,Status ,
       Reason1Id  , Reason1 ,
       Reason2Id  , Reason2 ,
       Reason3Id  , Reason3,
       Reason4Id  , Reason4,
       Action1Id  , Action1,
       Action2Id  , Action2,
       Action3Id  , Action3,
       Action4Id  , Action4,
       ReasonComment,
       ActionComment,
       ReasonsCompleted,
       Operator)
EXECUTE spBF_DowntimeGetData  Null, @PUIds,@StartTime , @Endtime, @InTimeZone,0,Null,Null,NULL,@OEEParameter
  	  	 DECLARE @PU_IDs TABLE (Pu_Id Int)
 	  	 DECLARE @xml XML
 	  	 SET @xml = cast(('<X>'+replace(@PUIds,',','</X><X>')+'</X>') as xml)
 	  	 INSERT INTO @PU_IDs(Pu_Id)
 	  	 SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
 	  	 DECLARE @NPTTimes TABLE(NPDet_Id int, Pu_Id int, StartTime Datetime, EndTime Datetime) 	 
 	  	 Insert Into @NPTTimes(NPDet_Id, Pu_Id, StartTime, EndTime)
 	  	 SELECT 	 Distinct np.NPDet_Id,
 	  	  	  	 np.PU_Id,
 	  	  	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @Endtime THEN @Endtime
 	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	 END
 	  	 FROM [dbo].NonProductive_Detail np WITH (NOLOCK)
 	  	  	 JOIN [dbo].Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	 JOIN @PU_IDs u ON u.pu_Id= np.Pu_Id
 	  	 WHERE np.PU_ID IN (SELECT DISTINCT(PU_Id) FROM @PU_IDs)
 	  	  	  	 AND np.Start_Time < @Endtime
 	  	  	  	 AND np.End_Time > @StartTime
IF @FilterNonProductiveTime = 1
BEGIN
 	  	 
 	  	 UPDATE D
 	  	 SET 
 	  	  	 D.Duration = datediff(second,D.StartTime,Npt.StartTime) /  60.0 + datediff(second,Npt.EndTime, D.EndTime) /  60.0
 	  	 FROM 
 	  	  	 @DowntimeData D
 	  	  	 JOIn @NPTTImes Npt ON Npt.Pu_Id = D.UnitId AND D.EndTime > Npt.EndTime and D.StartTime < Npt.StartTime
 	  	  	 AND NOT (D.StartTime = Npt.StartTime And  D.EndTime = Npt.EndTime)
 	  	 
 	  	 UPDATE D
 	  	 SET
 	  	  	 D.EndTime = Npt.StartTime,
 	  	  	 D.Duration = datediff(second,D.StartTime,Npt.StartTime) /  60.0
 	  	 FROM 
 	  	  	 @DowntimeData D
 	  	  	 JOIn @NPTTImes Npt ON Npt.Pu_Id = D.UnitId AND D.EndTime between Npt.StartTime and Npt.EndTime and D.StartTime < Npt.StartTime
 	  	  	 AND NOT (D.StartTime = Npt.StartTime And  D.EndTime = Npt.EndTime)
 	  	 UPDATE D
 	  	 SET
 	  	  	 D.StartTime = Npt.EndTime,
 	  	  	 D.Duration = datediff(second,Npt.endtime,D.endtime) /  60.0
 	  	 FROM 
 	  	  	 @DowntimeData D
 	  	  	 JOIn @NPTTImes Npt ON Npt.Pu_Id = D.UnitId AND D.StartTime between Npt.StartTime and Npt.EndTime and D.EndTime > Npt.EndTime
 	  	  	 AND NOT (D.StartTime = Npt.StartTime And  D.EndTime = Npt.EndTime)
 	  	  
 	  	 DELETE D 
 	  	 FROM 
 	  	  	 @DowntimeData D
 	  	  	 JOIn @NPTTImes Npt ON Npt.Pu_Id = D.UnitId AND D.StartTime between Npt.StartTime and Npt.EndTime AND D.EndTime between Npt.StartTime and Npt.EndTime
 	  	  	 AND NOT (D.StartTime = Npt.StartTime And  D.EndTime = Npt.EndTime)
 	  	  
 	  	 DELETE D
 	  	 FROM 
 	  	  	 @DowntimeData D
 	  	  	 JOIn @NPTTImes Npt ON Npt.Pu_Id = D.UnitId AND D.StartTime = Npt.StartTime And  D.EndTime = Npt.EndTime
 	  	 
 	  	 DELETE D
 	  	 FROM 
 	  	  	 @DowntimeData D
 	  	  	 JOIn @NPTTImes Npt ON Npt.Pu_Id = D.UnitId AND D.StartTime > Npt.StartTime And  D.EndTime < Npt.EndTime
 	  	  	 ---Need to test this scenario
END
;WITH S AS (
SELECT  D.EventId          
        , D.Duration         
        , UnitId, erc.ERC_Id, 
 	  	 CASE wHEN ec.ERC_Desc IN('Availability','Performance') THEN ec.ERC_Desc+' Loss'
 	  	 wHEN ec.ERC_Desc IN('Quality') THEN ec.ERC_Desc+' Losses'
 	  	 ELSE 
 	  	 ec.ERC_Desc END ERC_Desc
 	  	 , 	  	 Row_Number() over (Partition by D.EventId Order by erc.ERC_Id) Rownum
       FROM  @DowntimeData D
       LEFT JOIN Timed_Event_Details ted on ted.TEDet_Id = d.EventId 
       LEFT JOIN Timed_Event_Fault tef on tef.TEFault_Id = d.FaultId
       LEFT JOIN Event_Reason_Category_Data erc on erc.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id 
       Left Join Event_Reason_Catagories ec on ec.ERC_Id = erc.ERC_Id
)
Insert Into @DowntimeTable Select EventId, Duration,UnitId, ERC_Id, ERC_Desc from S Where Rownum = 1
 	    
INSERT INTO @outputtable (Category,Duration,EventCount)
SELECT COALESCE(Category,'Unspecified') as 'Category', SUM(Duration) as 'Duration',
 	    COUNT(1) as 'EventCount'
 	     FROM @DowntimeTable GROUP BY Category
SELECT Category,Duration,EventCount FROM @outputtable
 	  	 
