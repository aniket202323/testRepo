CREATE PROCEDURE dbo.spRS_SearchUnitByTree 
@LineId int,
@MasterUnitId int,
@ChildUnitId int,
@GroupId int,
@VarSearchDesc varchar(50)
AS
Declare @QueryType int
If @LineId Is Null 
  Begin
    If @VarSearchDesc Is Not Null
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.pl_id > 0 
        Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
    Else
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.pl_id > 0 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
  End
Else If @MasterUnitId Is Null
  Begin
    If @VarSearchDesc Is Not Null
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0
        Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
    Else
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
  End
Else If @ChildUnitId Is Null
  Begin
    If @VarSearchDesc Is Not Null
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id and pu2.PU_Id = @MasterUnitId
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
    Else
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id and pu2.PU_Id = @MasterUnitId
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
  End
Else If @GroupId Is Null
  Begin
    If @VarSearchDesc Is Not Null
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id and pu2.PU_Id = @ChildUnitId
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
    Else
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id and pu2.PU_Id = @ChildUnitId
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
  End
Else 
  Begin
    If @VarSearchDesc Is Not Null
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id and pug.PUG_Id = @GroupId
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id and pu2.PU_Id = @ChildUnitId
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
    Else
        Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
               ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc,
               VarId = v.Var_Id, VarDesc = v.Var_Desc
        From Variables v
          Join PU_Groups pug on pug.pug_id = v.pug_id and pug.PUG_Id = @GroupId
          Join Prod_Units pu2 on pu2.PU_Id = v.PU_Id and pu2.PU_Id = @ChildUnitId
          Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
          Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.PL_Id = @LineId and pl.pl_id > 0 
        Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc, VarDesc
  End
