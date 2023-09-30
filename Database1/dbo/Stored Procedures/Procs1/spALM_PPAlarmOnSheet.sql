CREATE Procedure dbo.spALM_PPAlarmOnSheet
@PP_Id int,
@Sheet_Id int, 
@IsOnSheet int OUTPUT
AS
Declare @ThePath as int
Declare @Paths       Table (Path_Id int)
-- get all Paths for Units on Sheet
Insert into @Paths (Path_Id)
  Select distinct pepu.Path_Id
   from PrdExec_Path_Units pepu
   join Sheet_Unit su on su.PU_Id = pepu.PU_Id
     where su.Sheet_Id = @Sheet_Id
select @ThePath = Path_Id from Production_Plan where PP_Id = @PP_Id
select @IsOnSheet = COUNT(PP_Id) from Production_Plan pp
 	 Join @Paths p on p.Path_Id = pp.Path_Id
 	   where pp.PP_Id = @PP_Id
