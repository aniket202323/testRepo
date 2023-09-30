CREATE PROCEDURE dbo.spServer_CalcMgrGetTestNames
AS
select var_id, Test_Name, MasterUnit = COALESCE(m.Master_Unit, v.PU_Id) 
 	 from variables_base v 
 	 join Prod_Units_Base m on m.PU_Id = v.PU_Id
 	 where Test_Name is not NULL and v.pu_id is not null
