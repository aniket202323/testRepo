Create Procedure dbo.spPO_GetPOData
  AS
  SELECT PL_Id, PL_Desc
    FROM Prod_Lines
    where pl_id > 0
 SELECT Distinct pu.PU_Id, PU_Desc,PL_Id,Unit_Type_Id = Coalesce(Unit_Type_Id,1)
    FROM Prod_Units pu
     Join prdexec_status ps on Pu.PU_id = ps.PU_Id
    WHERE pu.PU_Id > 0  
    ORDER BY PL_Id
Create Table #Paths (pl_Id Int,pu_desc nvarchar(50),Source_PU_Desc nvarchar(50),PU_Id Int,Source_PU_Id Int,Step  Int,PU_Order Int)
Insert Into  #Paths (pl_Id ,pu_desc ,Source_PU_Desc ,p.PU_Id ,Source_PU_Id ,Step,PU_Order)
select p1.pl_Id,p1.pu_desc,Source_PU_Desc = p2.PU_Desc,p.PU_Id,Source_PU_Id = pis.pu_Id, 1,p1.PU_Order
 from prdexec_Inputs p
 Join prdexec_Input_Sources pis on pis.PEI_Id = p.PEI_Id
 Join Prod_Units p1 on p.PU_Id = p1.PU_Id
 Join Prod_Units p2 on pis.PU_Id = p2.PU_Id
Insert Into  #Paths (pl_Id ,pu_desc ,Source_PU_Desc ,p.PU_Id ,Source_PU_Id ,Step,PU_Order)
select p1.pl_Id,p1.pu_desc,Source_PU_Desc = p2.PU_Desc,p.PU_Id,Source_PU_Id = pis.pu_Id, 1,p1.PU_Order
 from prdexec_Inputs p
 Join prdexec_Path_Input_Sources pis on pis.PEI_Id = p.PEI_Id
 Join Prod_Units p1 on p.PU_Id = p1.PU_Id
 Join Prod_Units p2 on pis.PU_Id = p2.PU_Id
Select Distinct * from #Paths
order by pl_Id,PU_Order
Drop Table #Paths
