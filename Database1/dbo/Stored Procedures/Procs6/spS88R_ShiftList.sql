CREATE procedure [dbo].[spS88R_ShiftList]
AS
select Distinct Shift_desc from crew_schedule Order By Shift_desc
