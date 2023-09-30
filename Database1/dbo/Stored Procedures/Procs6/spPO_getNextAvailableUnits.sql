
CREATE PROCEDURE dbo.spPO_getNextAvailableUnits
@PP_Id	 			int




AS
    IF (NOT EXISTS(SELECT 1 FROM Production_Plan WHERE PP_Id = @PP_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

    Declare @PU_Id int, @Start_Time datetime,@PU_Desc nvarchar(50), @Path_Id INT

    Select @Path_Id = Path_Id from Production_Plan where PP_Id = @PP_Id
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
        [Id] = pei.pu_id ,[Name] = pupei.pu_desc , [Caption] = @PU_Desc
    From prdexec_path_input_sources ppis
             Join prdexec_inputs pei on pei.pei_id = ppis.pei_id
             Join prod_units pupei on pupei.pu_id = pei.pu_id
             Left Join Production_Plan_Starts pps ON End_Time is null and pps.PU_Id = pei.pu_id and is_Production = 1
             Left Join Production_Plan pp ON pp.PP_Id = pps.PP_Id
    Where ppis.path_id = @Path_Id and ppis.pu_id = @PU_Id
    Union
    Select
        [Id] = pei.pu_id, [Name] = pupei.pu_desc , [Caption] = @PU_Desc
    From prdexec_input_sources pr
             Left Outer Join prdexec_path_input_sources ppis on ppis.pei_id = pr.pei_id and ppis.path_id = @Path_Id and ppis.pu_id = pr.pu_id
             Join prdexec_inputs pei on pei.pei_id = pr.pei_id
             Join prod_units pupei on pupei.pu_id = pei.pu_id
             Left Join Production_Plan_Starts pps ON End_Time is null and pps.PU_Id = pei.pu_id and is_Production = 1
             Left Join Production_Plan pp ON pp.PP_Id = pps.PP_Id
    Where pr.pu_id = @PU_Id and ppis.pepis_id is NULL
    Order By [Id]



    SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON
