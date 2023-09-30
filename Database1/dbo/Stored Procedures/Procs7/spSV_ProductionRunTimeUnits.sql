CREATE Procedure dbo.spSV_ProductionRunTimeUnits
@Path_Id int
AS
Select pu.PU_Id, pu.PU_Desc
From Prod_Units pu
Join PrdExec_Path_Units pepu on pepu.PU_Id = pu.PU_Id and pepu.Path_Id = @Path_Id and pepu.Is_Production_Point = 1
-- Manual Order Flow - Allow Edit of All Units With Production_Plan_Starts Records.
-- Select distinct pu.PU_Id, pu.PU_Desc
-- From Prod_Units pu
-- Join Production_Plan_Starts pps on pps.pu_id = pu.pu_id
-- Join Production_Plan pp on pp.pp_id = pps.pp_id
-- Where pp.Path_Id = @Path_Id
-- Order By PU_Desc
