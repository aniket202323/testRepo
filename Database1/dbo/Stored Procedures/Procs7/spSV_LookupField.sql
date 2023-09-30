/* spSV_LookupField 34,0,0,1,2,0   */
Create Procedure dbo.spSV_LookupField
@Path_Id int,
@prodId int,
@formId int,
@User_Id int,
@ResultNum int = 1,
@PP_Id int = NULL
AS
Declare @PEI_Id int
--products
if @ResultNum = 1
 	 Begin
 	  	 Select distinct p.Prod_Id AS 'Id', p.Prod_Desc + ' - [' + p.Prod_Code + ']' AS 'Product'
 	  	 From Products p
 	  	 Join PrdExec_Path_Products pepp on pepp.Prod_Id = p.Prod_Id
 	  	 left join Bill_Of_Material_Product bomp on (bomp.Prod_Id=p.Prod_Id and bomp.BOM_Formulation_Id=@formId) 
 	  	 Where 
 	  	  	 pepp.Path_Id = @Path_Id
 	  	  	 and (
 	  	  	  	 bomp.Prod_Id is not null or @formId=0
 	  	  	 )
 	  	 Order By [Product]
 	 End
--advanceunits
else if @ResultNum = 2
 	 Begin
 	  	 Declare @PU_Id int
 	  	 Declare @Start_Time datetime
 	  	 Declare @PU_Desc nvarchar(50)
 	  	 
 	  	 Select @Start_Time = max(Start_Time)
 	  	 From Production_Plan_Starts pps
 	  	 Join Production_Plan pp on pp.pp_id = pps.pp_id
 	  	 Where pp.Path_Id = @Path_Id
 	  	 --And pps.End_Time is NULL
 	  	 
 	  	 Select @PU_Id = pps.PU_Id
 	  	 From Production_Plan_Starts pps
 	  	 Join Production_Plan pp on pp.pp_id = pps.pp_id
 	  	 Where pp.Path_Id = @Path_Id
 	  	 And pps.Start_Time = @Start_Time
 	  	 Select @PU_Desc = PU_Desc
 	  	 From Prod_Units
 	  	 Where PU_Id = @PU_Id
/*
 	  	 Select 
 	  	   pei.pu_id AS 'Id', pupei.pu_desc AS 'Unit', @PU_Desc as 'Caption'
 	  	   From prdexec_path_input_sources ppis
 	  	  	 Join prdexec_inputs pei on pei.pei_id = ppis.pei_id
 	  	   Join prod_units pupei on pupei.pu_id = pei.pu_id
 	  	   Where ppis.path_id = @Path_Id and ppis.pu_id = @PU_Id
 	  	 Union
 	  	 Select 
 	  	   pei.pu_id AS 'Id', pupei.pu_desc AS 'Unit', @PU_Desc as 'Caption'
 	  	   From prdexec_input_sources pr
 	  	   Left Outer Join prdexec_path_input_sources ppis on ppis.pei_id = pr.pei_id and ppis.path_id = @Path_Id and ppis.pu_id = pr.pu_id
 	  	  	 Join prdexec_inputs pei on pei.pei_id = pr.pei_id
 	  	   Join prod_units pupei on pupei.pu_id = pei.pu_id
 	  	   Where pr.pu_id = @PU_Id and ppis.pepis_id is NULL
 	  	  	 Order By [Unit]
*/
 	  	 Select 
 	  	   [Id] = pei.pu_id ,[Unit] = pupei.pu_desc , [Caption] = @PU_Desc ,[Path] = isnull(pep.Path_Code,''),[Process Order] = isnull(pp.Process_Order,'')
 	  	   From prdexec_path_input_sources ppis
 	  	  	 Join prdexec_inputs pei on pei.pei_id = ppis.pei_id
 	  	   Join prod_units pupei on pupei.pu_id = pei.pu_id
 	  	   Left Join Production_Plan_Starts pps ON End_Time is null and pps.PU_Id = pei.pu_id and is_Production = 1
 	  	   Left Join Production_Plan pp ON pp.PP_Id = pps.PP_Id
 	  	   LEFT JOIN prdexec_paths pep ON pep.Path_Id = pp.Path_Id
 	  	   Where ppis.path_id = @Path_Id and ppis.pu_id = @PU_Id
 	  	 Union
 	  	 Select 
 	  	   [Id] = pei.pu_id, [Unit] = pupei.pu_desc , [Caption] = @PU_Desc ,[Path] = isnull(pep.Path_Code,''),[Process Order] = isnull(pp.Process_Order,'')
 	  	   From prdexec_input_sources pr
 	  	   Left Outer Join prdexec_path_input_sources ppis on ppis.pei_id = pr.pei_id and ppis.path_id = @Path_Id and ppis.pu_id = pr.pu_id
 	  	   Join prdexec_inputs pei on pei.pei_id = pr.pei_id
 	  	   Join prod_units pupei on pupei.pu_id = pei.pu_id
 	  	   Left Join Production_Plan_Starts pps ON End_Time is null and pps.PU_Id = pei.pu_id and is_Production = 1
 	  	   Left Join Production_Plan pp ON pp.PP_Id = pps.PP_Id
 	  	   LEFT JOIN prdexec_paths pep ON pep.Path_Id = pp.Path_Id
 	  	   Where pr.pu_id = @PU_Id and ppis.pepis_id is NULL
 	  	  	 Order By [Unit]
 	 End
--formulations
else if @ResultNum = 3
 	 Begin
 	  	 Declare  @Forecast_Start_Date datetime, @Process_Order nvarchar(50)
 	  	 
 	  	 Select @Forecast_Start_Date = Forecast_Start_Date, @Process_Order = Process_Order
 	  	  	 From Production_Plan
 	  	  	 Where PP_Id = @PP_Id
 	  	 
--select @Prod_Id as Prod_Id, @Forecast_Start_Date as Forecast_Start_Date
 	  	 DECLARE @tBOMFormulations TABLE (
 	  	  	 BOMFormulationId bigint,
 	  	  	 BOMFormulationDesc nvarchar(50),
 	  	  	 MasterBOMFormulationId bigint
 	  	 )
 	  	 
 	  	 Insert @tBOMFormulations (
 	  	  	 BOMFormulationId,
 	  	  	 BOMFormulationDesc,
 	  	  	 MasterBOMFormulationId)
 	  	 SELECT 0,
 	  	  	 '<None>',
 	  	  	 NULL
 	  	 Insert @tBOMFormulations (
 	  	  	 BOMFormulationId,
 	  	  	 BOMFormulationDesc,
 	  	  	 MasterBOMFormulationId)
 	  	 SELECT distinct bomf.BOM_Formulation_Id,
 	  	  	 bomf.BOM_Formulation_Desc,
 	  	  	 bomf.Master_BOM_Formulation_Id
 	  	  	 FROM Bill_Of_Material_Formulation bomf
 	  	  	 JOIN Bill_Of_Material_Product bomp on bomp.BOM_Formulation_Id = bomf.BOM_Formulation_Id
 	  	  	 join PrdExec_Path_Units ppu on (ppu.PU_Id=bomp.PU_Id and ppu.Path_Id=@Path_Id and ppu.Is_Schedule_Point=1) or bomp.PU_Id is null 
 	  	  	 WHERE bomp.Prod_Id = @prodId
--select * from @tBOMFormulations
 	  	 
 	  	 Insert @tBOMFormulations (
 	  	  	 bomf.BOMFormulationId,
 	  	  	 bomf.BOMFormulationDesc,
 	  	  	 bomf.MasterBOMFormulationId)
 	  	 SELECT distinct BOM_Formulation_Id,
 	  	  	 BOM_Formulation_Desc,
 	  	  	 Master_BOM_Formulation_Id
 	  	  	 FROM Bill_Of_Material_Formulation bomf
 	  	  	 JOIN @tBOMFormulations bomf2 on bomf2.MasterBOMFormulationId = bomf.BOM_Formulation_Id
 	  	  	 WHERE bomf2.MasterBOMFormulationId is NOT NULL
 	  	  	 AND BOM_Formulation_Id NOT IN (SELECT BOMFormulationId FROM @tBOMFormulations)
 	  	 SELECT BOMFormulationId AS 'Id', BOMFormulationDesc AS 'BOM Formulation Desc', @Process_Order as 'Caption'
 	  	  	 FROM @tBOMFormulations
 	 End
