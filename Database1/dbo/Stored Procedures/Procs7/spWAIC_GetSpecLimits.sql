Create Procedure [dbo].[spWAIC_GetSpecLimits]
@VariableId Int,
@StartTime datetime = Null,
@EndTime datetime = Null,
@ProductId Int = null,
@InTimeZone nvarchar(200)=NULL
AS
 	 Select @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
 	 Select @EndTime =[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
Declare @SpecPoints Table (Id int Identity(1,1), [Timestamp] DateTime, ProdId Int NULL, VSId int NULL, L_Reject nvarchar(100), L_Warning nvarchar(100), U_Warning nvarchar(100), U_Reject nvarchar(100), L_Control nvarchar(100), 	 T_Control nvarchar(100), U_Control nvarchar(100),EndTime DateTime)
Insert Into @SpecPoints ([Timestamp],
 	 L_Reject,
 	 L_Warning,
 	 U_Warning,
 	 U_Reject,
 	 L_Control,
 	 T_Control,
 	 U_Control,
 	 ProdId,
 	 EndTime
)
select Distinct StartTime,LReject,LWarning,UWarning,UReject,LCL,TCL,UCL,ProdId,EndTime
  	 from [dbo].[fnCMN_GetSpecLimits](@VariableId, @StartTime, @EndTime)
  	 Order by  StartTime
UPDATE @SpecPoints set Timestamp = @StartTime Where Timestamp <@StartTime
UPDATE @SpecPoints set Timestamp = @EndTime Where Timestamp > @EndTime
UPDATE @SpecPoints set EndTime = @StartTime Where EndTime < @StartTime
UPDATE @SpecPoints set EndTime = @EndTime Where EndTime > @EndTime
IF @ProductId is Not Null
BEGIN
 	 DELETE FROM @SpecPoints WHERE ProdId <> @ProductId
END
-- Add Row for end point if needed
Declare @End int, @MaxTimeStamp DateTime
Select @End = Max(Id), @MaxTimeStamp = Max(Timestamp) FROM @SpecPoints --this assumes the last record is the one with the max timestamp
If (@MaxTimeStamp < @EndTime)
Begin
 	  	  	 Insert Into @SpecPoints ([Timestamp],L_Reject,L_Warning,U_Warning,U_Reject,L_Control,T_Control,U_Control,ProdId)
 	  	  	 SELECT 	  	 EndTime,L_Reject,L_Warning,U_Warning,U_Reject,L_Control,T_Control,U_Control,ProdId
 	  	  	 FROM @SpecPoints WHERE ID = @End
End
--Delete from @SpecPoints
--  Where L_Reject Is Null and L_Warning Is Null and U_Warning Is Null and U_Reject Is Null and L_Control Is Null and 
-- 	  	 T_Control Is Null and U_Control Is Null and [Timestamp] > @StartTime and [Timestamp] < @EndTime
--If all the rows are null, there is no reason
--to return any of them.
If (Select Count(*)
 	  	 From @SpecPoints
 	  	 Where L_Reject Is Not Null
 	  	 Or L_Warning Is Not Null
 	  	 Or U_Warning Is Not Null
 	  	 Or U_Reject Is Not Null
 	  	 Or L_Control Is Not Null
 	  	 Or T_Control Is Not Null
 	  	 Or U_Control Is Not Null) = 0
 	 Delete From @SpecPoints
select Distinct 'Timestamp'=  [dbo].[fnServer_CmnConvertFromDbTime] ([Timestamp],@InTimeZone)  ,
 	 ProdId ,
 	 L_Reject ,
 	 L_Warning ,
 	 U_Warning ,
 	 U_Reject ,
 	 L_Control, 	 
 	 T_Control,
 	 U_Control
from @SpecPoints
Order By [Timestamp]
