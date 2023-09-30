CREATE PROCEDURE dbo.spServer_CalcMgrGetVarCalcTimes
@varid int,
@puid int,
@resultvarid int,
@resultPUId int,
@id int,
@RefTime datetime,
@IsEvent int
as
declare @@varid int
declare @@entityid int
declare @@attributeid int
declare @IsGenealogy int
declare @StartTime datetime
declare @EndTime datetime
-- Another Temp table.  Put info about the parameters to the calc so we look at them
Create Table #CMGCTResults(entityId int, attributeId int, varid int)
insert into #CMGCTResults(entityId, attributeId, varid)
select i.Calc_Input_Entity_Id, i.Calc_Input_attribute_Id, d.member_var_id from 
calculation_inputs i
join calculation_input_data d on d.calc_input_id = i.calc_input_id
where i.calculation_id = @id and d.result_var_id=@resultvarid --and d.member_var_id <> @varid
-- Insert any dependencies into the table (translate scope into an equivalent attribute id
insert into #CMGCTResults(entityId, attributeId, varid)
select 3, 
 	 ScopeId = 
 	    CASE
 	      WHEN c.Calc_dependency_scope_Id = 1 THEN 8
 	      WHEN c.Calc_dependency_scope_Id = 3 THEN 9
 	      ELSE 7
 	    END,
d.var_id from 
calculation_dependencies c
join calculation_dependency_data d on d.calc_dependency_id = c.calc_dependency_id 
where d.result_var_id=@resultvarid and d.var_id = @varid
-- Insert any instance dependencies into the table (translate scope into an equivalent attribute id
insert into #CMGCTResults(entityId, attributeId, varid)
select 3, 
 	 ScopeId = 
 	    CASE
 	      WHEN Calc_dependency_scope_Id = 1 THEN 8
 	      WHEN Calc_dependency_scope_Id = 3 THEN 9
 	      ELSE 7
 	    END,
var_id from 
calculation_instance_dependencies
where result_var_id=@resultvarid and var_id = @varid
--Debugging
--select * from #CMGCTResults
select @IsGenealogy = 0
-- Now, loop through the calc parameters and insert any run times it causes
execute('Declare xxx_Cursor CURSOR Global Static' +
        'For (select varid,entityid,attributeid from #CMGCTResults)' +
        'For Read Only')
Open xxx_Cursor  
FetchLoop:
Fetch Next From xxx_Cursor Into @@varid,@@entityid,@@attributeid
If (@@Fetch_Status = 0)
begin
   if @@entityid = 7
   begin
     select @IsGenealogy = 1
     execute dbo.spServer_CalcMgrGetVarCalcTimes2 @varid, @@attributeid, @resultvarid, @id, @reftime, @IsEvent, @IsGenealogy
     Goto FetchLoop
   end 
   if @@varid = @varid
   begin
     if @@entityid = 6
       select @IsGenealogy = 1
     execute dbo.spServer_CalcMgrGetVarCalcTimes2 @varid, @@attributeid, @resultvarid, @id, @reftime, @IsEvent, @IsGenealogy
   end
   Goto FetchLoop
end
Close xxx_Cursor
Deallocate xxx_Cursor
drop Table #CMGCTResults
-- Debugging
--select * from #CMGCTRunTimes
-- For genealogy related calc we need to get the time range from the table.  Use that to
-- get the run times.
if @IsGenealogy = 1
begin
   select @StartTime=min(StartTime), @EndTime=max(RunTime) from #CMGCTRunTimes
   delete from #CMGCTRunTimes  
   execute dbo.spServer_CalcMgrGetGenealogyCalcTimes @puid, @resultPUId, @StartTime, @EndTime
-- Debugging
--   select @varId, @puid, @resultvarid, @resultPUId, @StartTime, @EndTime
--   select * from #CMGCTRunTimes
end
