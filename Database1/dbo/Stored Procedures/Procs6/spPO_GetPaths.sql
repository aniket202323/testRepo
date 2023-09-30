
CREATE PROCEDURE dbo.spPO_GetPaths
@LineIds	nvarchar(max) = null				-- filter paths for a certain line
,@Path_Id	Int = Null				-- filter to only this path
AS



    ----------------------------------------------------------------------------------------------------------------------------------
-- Declares
----------------------------------------------------------------------------------------------------------------------------------
Declare @Paths table (Path_Id int, Path_Code nvarchar(50), Path_Desc nvarchar(50), LineId int,
                      Comment_Id int null, IsLineProduction bit, IsScheduleControlled bit,
                      ScheduleControlType tinyint null)

Select @LineIds = ltrim(rtrim(@LineIds))
If(@LineIds = '') Select @LineIds = null

Create Table #Lines (Id Int)
INSERT INTO #Lines (Id)  SELECT Id FROM dbo.fnCMN_IdListToTable('LineIds',@LineIds,',')


    ----------------------------------------------------------------------------------------------------------------------------------
-- Grab the initial set of paths
----------------------------------------------------------------------------------------------------------------------------------
insert into @Paths (Path_Id, Path_Code, Path_Desc, LineId, Comment_Id, IsLineProduction, IsScheduleControlled, ScheduleControlType)
Select Path_Id, Path_Code, Path_Desc, PL_Id, Comment_Id, Is_Line_Production, Is_Schedule_Controlled, Schedule_Control_Type
from   Prdexec_Paths
where  ((@Path_Id is null) or (@Path_Id = Path_Id))
  and  (@LineIds is null or Prdexec_Paths.PL_Id in (Select ID from #Lines))

    if (@Path_Id is not null) and (NOT EXISTS(SELECT 1 FROM @Paths WHERE @Path_Id = Path_Id))
        BEGIN
            SELECT Error = 'ERROR: Path not found', Code = 'ResourceNotFound', ErrorType = 'PathNotFound', PropertyName1 = 'Path_Id', PropertyName2 = 'Control Type', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = @Path_Id, PropertyValue2 = 'AllUnitsRunSameScheduleSimultaneously', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END



----------------------------------------------------------------------------------------------------------------------------------
-- Return final results
----------------------------------------------------------------------------------------------------------------------------------
Select     Path_Id, Path_Code, Path_Desc, LineId, Comment_Id, IsLineProduction, IsScheduleControlled, ScheduleControlType
from     @Paths
order by Path_Id

Select     Path_Id,
           PEPU_Id as ExecutionPathUnitId,
           Is_Production_Point,
           Is_Schedule_Point,
           PU_Id,
           Unit_Order
from     Prdexec_Path_Units
where    Path_Id in (Select Path_Id from @Paths)
order by Path_Id, Unit_Order

select PrdExec_Path_Products.Path_Id as Path_Id,PB.Prod_Id, PB.Prod_Code, PB.Prod_Desc
from PrdExec_Path_Products
         JOIN Products_Base PB ON PB.Prod_Id = PrdExec_Path_Products.Prod_Id
where PrdExec_Path_Products.Path_Id in (Select Path_Id from @Paths)


