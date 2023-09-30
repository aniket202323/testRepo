CREATE PROCEDURE dbo.spRS_GetLineTree 
AS
Select LineId = pl.PL_Id, LineDesc = pl.PL_Desc, MasterUnitId = pu1.PU_Id, MasterUnitDesc = pu1.PU_Desc,
       ChildUnitId = pu2.PU_id, ChildUnitDesc = pu2.PU_Desc, GroupId = pug.PUG_Id, GroupDesc = pug.PUG_Desc
  From PU_Groups pug 
    Join Prod_Units pu2 on pu2.PU_Id = pug.PU_Id
    Join Prod_Units pu1 on pu1.PU_Id = Case When pu2.Master_Unit Is Null Then pu2.PU_Id Else pu2.Master_Unit End 
    Join Prod_Lines pl on pl.PL_Id = pu1.PL_Id and pl.pl_id > 0 
  Order by LineDesc, MasterUnitDesc, ChildUnitDesc, GroupDesc
