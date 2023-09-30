CREATE PROCEDURE dbo.spServer_AMgrGetEmailKey
@AlarmId int,
@TableId int,
@KeyId int output
AS
Declare @DeptId int,
        @PLId int,
        @MasterPUId int,
        @PUId int,
        @PUGId int,
        @VarId int,
        @FamilyId int,
        @ProdGroupId int,
        @ProdId int,
 	  	 @STime datetime,
 	  	 @SupportsAppliedProduct int
Set @DeptId = null
Set @PLId = null
Set @MasterPUId = null
Set @PUId = null
Set @PUGId = null
Set @VarId = null
Set @FamilyId = null
Set @ProdGroupId = null
Set @ProdId = null
set @KeyId = NULL
Select @VarId = Key_Id, @STime = Start_Time from Alarms where Alarm_Id = @AlarmId
Select @DeptId = d.Dept_Id, @PLId = l.PL_Id, @PUId = u.PU_Id, @MasterPUId = coalesce(u.Master_Unit, u.PU_Id), @PUGId = v.PUG_Id
  from Variables_Base v
  join Prod_Units_Base u on u.PU_Id = v.PU_Id
  join Prod_Lines_Base l on l.PL_Id = u.PL_Id
  join Departments_Base d on d.Dept_Id = l.Dept_Id
  where v.Var_Id = @VarId
if @TableId in (21, 22, 23)
 	 begin
 	  	 select @SupportsAppliedProduct = CONVERT(INT,dbo.fnServer_CmnGetParameter(196, 20, HOST_NAME(), '0', NULL))
 	  	 Set @ProdId = null
 	  	 if (@SupportsAppliedProduct = 1)
 	  	  	 begin
 	  	  	  	 Select @ProdId = ProdId
 	  	  	  	   From dbo.fnCMN_GetPSFromEvents(@MasterPUId,@STime,@STime)
 	  	  	 end
 	  	 else
 	  	  	 begin
 	  	  	  	 Select @ProdId = Prod_Id
 	  	  	  	   From Production_Starts
 	  	  	  	   Where PU_Id = @MasterPUId and Start_Time <= @STime and (End_Time > @STime or End_Time is null)
 	  	  	  	   Order by Start_Time 
 	  	  	 end
 	 
 	 
 	  	 Select @FamilyId = f.Product_Family_Id, @ProdGroupId = g.Product_Grp_Id
 	  	   from Products p
 	  	   left join Product_Family f on f.Product_Family_Id = p.Product_Family_Id
 	  	   left join Product_Group_Data d on d.Prod_Id = p.Prod_Id
 	  	   left join Product_Groups g on g.Product_Grp_Id = d.Product_Grp_Id
 	  	   where p.Prod_Id = @ProdId
 	 end
 	 
if (@TableId = 17) 	  	 -- Department
 	 set @KeyId = @DeptId
else if (@TableId = 18) -- Line
 	 set @KeyId = @PLId
else if (@TableId = 43) -- Unit
 	 set @KeyId = @PUId
else if (@TableId = 19) -- Unit Group
 	 set @KeyId = @PUGId
else if (@TableId = 20) -- Variable
 	 set @KeyId = @VarId
else if (@TableId = 21) -- Product Family
 	 set @KeyId = @FamilyId
else if (@TableId = 22) -- Product Group
 	 set @KeyId = @ProdGroupId
else if (@TableId = 23) -- Product
 	 set @KeyId = @ProdId
