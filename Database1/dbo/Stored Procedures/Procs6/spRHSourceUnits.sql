CREATE PROCEDURE dbo.spRHSourceUnits
@PU_Id int
AS
--TODO: Fix this based on changes to PrdExec_Path
/*
Select p.PU_Id, p.PU_Desc
 From PrdExec_Path pex
 Join Prod_Units p on p.PU_Id = pex.Source_PU_Id
 Where pex.PU_Id = @PU_Id
 Order By p.PU_Desc
*/
select p.PU_Id, p.PU_Desc
  From PrdExec_Input_Sources pxis
  Join PrdExec_Inputs pxi on pxis.PEI_Id = pxi.PEI_Id and pxi.PU_Id = @PU_Id
  Join Prod_Units p on p.PU_Id = pxis.PU_Id
  Order By PU_Desc
