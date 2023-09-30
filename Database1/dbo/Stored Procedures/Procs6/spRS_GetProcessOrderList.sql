Create Procedure [dbo].[spRS_GetProcessOrderList]
(@StartTime 	 datetime,
 @EndTime 	 datetime,
 @PUId 	  	 int,
 @ExcludeStr varchar(8000),
 @Mask   	  	  	  	 VARCHAR (100),
 @MaskFlag 	  	  	 tinyint,
 @InTimeZone varchar(255)=NULL
)
AS
/*DECLARE 	 @StartTime 	 datetime,
 	  	 @EndTime 	 datetime,
 	  	 @PUId 	  	 datetime
SELECT 	 @StartTime 	 = '2001-01-01',
 	  	 @EndTime 	 = '2009-02-01',
 	  	 @PUId 	  	 = 5*/
Declare @INstr VarChar(7999)
Declare @Id int
DECLARE @FullMask 	  	 VARCHAR(50) 	 
Create Table #T (VarId int)
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 If @ExcludeStr Is Not Null
  Begin
 	 Select @INstr = @ExcludeStr + ','
 	 While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
 	   Begin
 	     Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	     insert into #T (VarId) Values (@Id)
 	     Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	     Select @INstr = Right(@INstr,Datalength(@INstr)-1)
 	   End
  End  
 	 
 	 If @Mask Is Not Null
 	 Begin
 	  	 If @MaskFlag = 1 Select @FullMask = @Mask + '%'
 	  	 Else If @MaskFlag = 2 Select @FullMask = '%' + @Mask
 	  	 Else Select @FullMask = '%' + @Mask + '%'
 	 
 	 End
 	 If @Mask IS NULL
 	 BEGIN
 	  	 SELECT @FullMask='%'
 	 END 
-- double bounded
IF(ISNULL(@StartTime,'')!=NULL AND ISNULL(@EndTime,'')!=NULL)
BEGIN
 	 SELECT 	 pp.PP_Id,
 	  	  	 pp.Process_Order
 	 FROM dbo.Production_Plan_Starts pps WITH (NOLOCK)
 	  	 JOIN dbo.Production_Plan pp WITH (NOLOCK)
 	  	  	  	  	  	  	  	  	 ON pps.PP_Id = pp.PP_Id
 	 WHERE pps.PU_Id = @PUId
 	  	 AND pps.Start_Time < @EndTime
 	  	 AND ( 	 pps.End_Time > @StartTime
 	  	  	 OR pps.End_Time IS NULL)
 	  	 AND pp.PP_Id NOT IN (Select varId from #t)
 	  	 AND pp.Process_Order Like @FullMask
 	 UNION SELECT 	 pp.PP_Id,
 	  	  	  	  	 pp.Process_Order
 	 FROM dbo.Events e WITH (NOLOCK)
 	  	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON e.Event_Id = ed.Event_Id
 	  	  	 LEFT JOIN dbo.Production_Plan pp 	 WITH (NOLOCK)
 	  	  	  	  	  	  	  	  	  	  	  	 ON ed.PP_Id = pp.PP_Id
 	 WHERE 	 e.PU_Id = @PUId
 	  	  	 AND ed.PP_Id IS NOT NULL
 	  	  	 AND e.TimeStamp > @StartTime
 	  	  	 AND e.TimeStamp <= @EndTime
 	  	  	 AND pp.Process_Order Like @FullMask
 	  	  	 AND pp.PP_Id NOT IN (Select varId from #t) 
 	 GROUP BY 	 pp.PP_Id,
 	  	  	  	 pp.Process_Order
END
-- EndTime bounded (i.e. @startTime is null)
IF(ISNULL(@EndTime,'')!=NULL)
BEGIN
 	 SELECT 	 pp.PP_Id,
 	  	  	 pp.Process_Order
 	 FROM dbo.Production_Plan_Starts pps WITH (NOLOCK)
 	  	 JOIN dbo.Production_Plan pp WITH (NOLOCK)
 	  	  	  	  	  	  	  	  	 ON pps.PP_Id = pp.PP_Id
 	 WHERE 	 pps.PU_Id = @PUId
 	  	  	 AND pps.Start_Time < @EndTime
 	  	  	 AND pp.PP_Id NOT IN (Select varId from #t)
 	  	  	 AND pp.Process_Order Like @FullMask
 	 UNION SELECT 	 pp.PP_Id,
 	  	  	  	  	 pp.Process_Order
 	 FROM dbo.Events e WITH (NOLOCK)
 	  	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON e.Event_Id = ed.Event_Id
 	  	  	 LEFT JOIN dbo.Production_Plan pp 	 WITH (NOLOCK)
 	  	  	  	  	  	  	  	  	  	  	  	 ON ed.PP_Id = pp.PP_Id
 	 WHERE 	 e.PU_Id = @PUId
 	  	  	 AND ed.PP_Id IS NOT NULL
 	  	  	 AND e.TimeStamp <= @EndTime
 	  	  	 AND e.PU_Id NOT IN (Select varId from #t)
 	  	  	 AND pp.PP_Id NOT IN (Select varId from #t)
 	  	  	 AND pp.Process_Order Like @FullMask
 	 GROUP BY 	 pp.PP_Id,
 	  	  	  	 pp.Process_Order
END
ELSE
BEGIN
-- No Start or EndTime
SELECT 	 pp.PP_Id,
 	  	 pp.Process_Order
FROM dbo.Production_Plan_Starts pps WITH (NOLOCK)
 	 JOIN dbo.Production_Plan pp WITH (NOLOCK)
 	  	  	  	  	  	  	  	 ON pps.PP_Id = pp.PP_Id
WHERE pps.PU_Id = @PUId
 	  	  	 AND pp.PP_Id NOT IN (Select varId from #t) 
 	  	  	 AND pp.Process_Order Like @FullMask
UNION SELECT 	 pp.PP_Id,
 	  	  	  	 pp.Process_Order
FROM dbo.Events e WITH (NOLOCK)
 	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON e.Event_Id = ed.Event_Id
 	  	 LEFT JOIN dbo.Production_Plan pp 	 WITH (NOLOCK)
 	  	  	  	  	  	  	  	  	  	  	 ON ed.PP_Id = pp.PP_Id
WHERE 	 e.PU_Id = @PUId
 	  	 AND ed.PP_Id IS NOT NULL
 	  	 AND pp.PP_Id NOT IN (Select varId from #t)
 	  	 AND pp.Process_Order Like @FullMask
GROUP BY 	 pp.PP_Id,
 	  	  	 pp.Process_Order
END
