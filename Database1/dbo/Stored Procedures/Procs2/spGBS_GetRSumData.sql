Create Procedure dbo.spGBS_GetRSumData
@SheetName nvarchar(50),
@MasterUnit int, 
@RSum_Id int     
AS
Declare @SheetId int
Declare @STime datetime
create table #Vars (
  VarId int
)
create table #Sets (
  Id int
)
Select @SheetId = Sheet_Id
  From Sheets
  Where Sheet_Desc = @SheetName
Insert Into #Vars
  Select Var_id
    From Sheet_Variables
    Where Sheet_Id = @SheetId and
          Var_Id Is Not Null
Select @STime = Start_Time
  From GB_Rsum
  Where RSum_Id = @Rsum_Id
Insert Into #Sets
  Select rsum_id 
    From GB_Rsum r
    Join Prod_Units pu on r.PU_Id = pu.PU_Id and (pu.Pu_id = @MasterUnit or pu.Master_Unit = @MasterUnit)
    Where Start_Time = @STime   
select Distinct g.* from gb_rsum g WITH (index(GB_RSum_PK_RSumId))
--  Join #Sets s on g.Rsum_id = s.id   
--  Where g.PU_Id = @MasterUnit
  Where g.rsum_id = @RSum_Id
select Distinct Coalesce(d.Minimum, 0) as 'Minimum', Coalesce(d.Maximum, 0) as 'Maximum', Coalesce(d.Cpk, 0) as 'Cpk', d.StDev, d.In_Warning, d.In_Limit, d.Conf_Index, d.RSum_Id, d.Var_Id, Coalesce(d.Num_Values, 0) as 'Num_Values', d.Value
 	 from gb_rsum_data d WITH (index(GB_RSum_PK_RSumIdVarId))
  Join #Vars v on v.VarId = d.Var_Id
  Join #Sets s on d.Rsum_id = s.id
Drop Table #Vars
Drop Table #Sets
