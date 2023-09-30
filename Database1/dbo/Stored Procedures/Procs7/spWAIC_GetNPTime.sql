Create Procedure [dbo].[spWAIC_GetNPTime]
@UnitId Int,
@StartTime datetime,
@EndTime datetime,
@InTimeZone nvarchar(200)=NULL
AS
 	 Select @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone) 
 	 Select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
Select Coalesce(pu.PU_Desc + '->', '') + 'Non-Productive Time' + Coalesce(' (' + Event_Reason_Name + ')', '') [Label],
 	 [StartTime]=   [dbo].[fnServer_CmnConvertFromDbTime] (npd.Start_Time,@InTimeZone)   , 
    [EndTime]= [dbo].[fnServer_CmnConvertFromDbTime] (npd.End_Time,@InTimeZone) ,
    Null [Hyperlink]
From NonProductive_Detail npd
Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
Left Outer Join Event_Reasons er On er.Event_Reason_Id = ertd.Event_Reason_Id
Left Outer Join Prod_Units pu On npd.PU_Id = pu.PU_Id
Where npd.PU_Id = @UnitId
 	 And ((npd.Start_Time > @StartTime And npd.Start_Time < @EndTime) --NPT starts in the range
 	  	  	  	 Or (npd.End_Time > @StartTime And npd.End_Time < @EndTime) --NPT ends in the range
 	  	  	  	 Or (npd.Start_Time <= @StartTime And npd.End_Time >= @EndTime)) --NPT encompasses the range
