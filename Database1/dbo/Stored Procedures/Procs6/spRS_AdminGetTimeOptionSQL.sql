CREATE PROCEDURE dbo.spRS_AdminGetTimeOptionSQL
@RRD_Id int
AS
Select RRD_Id, Default_Prompt_Desc, Start_Date_SQL, End_Date_SQL
From Report_Relative_Dates
Where RRD_Id = @RRD_Id
