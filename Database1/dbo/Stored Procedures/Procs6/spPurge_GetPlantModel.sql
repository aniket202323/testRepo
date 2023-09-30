CREATE PROCEDURE dbo.spPurge_GetPlantModel
AS
/*Select 0 ParentId, Dept_Id Id, Dept_Desc Name, 'Department' Icon
From Departments
Where Dept_Desc Not Like '<%>'*/
Select 0 ParentId, 0 Id, 'Department' Name, 'Department' Icon
Select 0 ParentId, pl.PL_Id Id, pl.PL_Desc Name, 'Line' Icon
From Prod_Lines pl
/*Join Departments d On d.Dept_Id = pl.Dept_Id And d.Dept_Desc Not Like '<%>'*/
Where pl.PL_Desc Not Like '<%>'
Select pu.PL_Id ParentId, pu.PU_Id Id, pu.PU_Desc Name, 'Unit' Icon
From Prod_Units pu
Join Prod_Lines pl On pl.PL_Id = pu.PL_Id and pl.PL_Desc Not Like '<%>'
/*Join Departments d On d.Dept_Id = pl.Dept_Id And d.Dept_Desc Not Like '<%>'*/
Where PU_Desc Not Like '<%>'
Select pug.PU_Id ParentId, pug.PUG_Id Id, pug.PUG_Desc Name, 'VarGroup' Icon
From PU_Groups pug
Join Prod_Units pu On pu.PU_Id = pug.PU_Id and pu.PU_Desc Not Like '<%>'
Join Prod_Lines pl On pl.PL_Id = pu.PL_Id and pl.PL_Desc Not Like '<%>'
/*Join Departments d On d.Dept_Id = pl.Dept_Id And d.Dept_Desc Not Like '<%>'*/
Where pug.PUG_Desc Not Like '<%>'
Select v.PUG_Id ParentId, v.Var_Id Id, v.Var_Desc Name, 'Variable' Icon
From Variables v
Join PU_Groups pug On pug.PUG_Id = v.PUG_Id and pug.PUG_Desc Not Like '<%>'
Join Prod_Units pu On pu.PU_Id = pug.PU_Id and pu.PU_Desc Not Like '<%>'
Join Prod_Lines pl On pl.PL_Id = pu.PL_Id and pl.PL_Desc Not Like '<%>'
/*Join Departments d On d.Dept_Id = pl.Dept_Id And d.Dept_Desc Not Like '<%>'*/
Where v.Var_Desc Not Like '<%>'
