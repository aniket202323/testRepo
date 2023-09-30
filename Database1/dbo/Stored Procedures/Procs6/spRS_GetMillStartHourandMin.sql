CREATE   PROCEDURE [dbo].[spRS_GetMillStartHourandMin] 
AS
Declare @MillStartHour int
Declare @MillStartMin int
Select @MillStartHour = Value From Site_Parameters Where Parm_Id=14
Select @MillStartMin = Value From Site_Parameters Where Parm_Id=15
Select @MillStartHour as MillStartHour,@MillStartMin as MillStartMin
